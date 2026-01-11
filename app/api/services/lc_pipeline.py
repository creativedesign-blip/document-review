import json
from typing import AsyncGenerator, List, Optional

import fitz  # PyMuPDF
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import PydanticOutputParser
from pydantic import BaseModel

from common.logger import get_logger
from common.models import BaseIssue, IssueType, Location, ReviewRule, RiskLevel
from config.config import settings

logging = get_logger(__name__)


class AnalyzedIssue(BaseModel):
    """Issue found during document analysis."""
    text: str
    explanation: str
    suggested_fix: str
    page_num: int
    para_index: int


class AnalysisResult(BaseModel):
    """Result of analyzing a text chunk."""
    issues: List[AnalyzedIssue]


GRAMMAR_PROMPT = """You are a document review expert specializing in grammar and spelling.
Analyze the following text and identify any grammar or spelling issues.

For each issue found, provide:
- text: The exact problematic text
- explanation: Why this is an issue
- suggested_fix: The corrected version
- page_num: The page number (provided in context)
- para_index: The paragraph index (provided in context)

Text to analyze (from page {page_num}, paragraph {para_index}):
{text}

{format_instructions}
"""

DEFINITIVE_LANGUAGE_PROMPT = """You are a document review expert specializing in identifying definitive or absolute language that may be problematic in formal documents.

Look for statements that:
- Make absolute claims without evidence (e.g., "always", "never", "guaranteed")
- Use overly definitive language that could be misleading
- Make promises or guarantees that may not be appropriate

For each issue found, provide:
- text: The exact problematic text
- explanation: Why this language is problematic
- suggested_fix: A more appropriate phrasing
- page_num: The page number (provided in context)
- para_index: The paragraph index (provided in context)

Text to analyze (from page {page_num}, paragraph {para_index}):
{text}

{format_instructions}
"""

CUSTOM_RULE_PROMPT = """You are a document review expert. Apply the following custom rule to analyze the text.

Rule: {rule_name}
Description: {rule_description}
{examples_section}

For each issue found that violates this rule, provide:
- text: The exact problematic text
- explanation: Why this violates the rule
- suggested_fix: The corrected version
- page_num: The page number (provided in context)
- para_index: The paragraph index (provided in context)

Text to analyze (from page {page_num}, paragraph {para_index}):
{text}

{format_instructions}
"""


class LangChainPipeline:
    """LangChain-based pipeline for document analysis."""

    def __init__(self):
        self.llm = ChatOpenAI(
            model=settings.openai_model,
            api_key=settings.openai_api_key,
            base_url=settings.openai_base_url if settings.openai_base_url else None,
            temperature=0.1,
        )
        self.parser = PydanticOutputParser(pydantic_object=AnalysisResult)
        self.pagination = settings.pagination

    def _extract_text_with_positions(self, pdf_path: str) -> List[dict]:
        """Extract text from PDF with page and position information."""
        doc = fitz.open(pdf_path)
        paragraphs = []

        for page_num, page in enumerate(doc, start=1):
            blocks = page.get_text("dict", flags=fitz.TEXT_PRESERVE_WHITESPACE)["blocks"]

            for block_idx, block in enumerate(blocks):
                if block.get("type") == 0:  # Text block
                    lines = block.get("lines", [])
                    text_parts = []
                    bbox = block.get("bbox", [0, 0, 0, 0])

                    for line in lines:
                        for span in line.get("spans", []):
                            text_parts.append(span.get("text", ""))

                    text = " ".join(text_parts).strip()
                    if text:
                        paragraphs.append({
                            "text": text,
                            "page_num": page_num,
                            "para_index": len(paragraphs),
                            "bbox": list(bbox),
                        })

        doc.close()
        return paragraphs

    def _chunk_paragraphs(self, paragraphs: List[dict]) -> List[List[dict]]:
        """Split paragraphs into chunks for processing."""
        chunks = []
        for i in range(0, len(paragraphs), self.pagination):
            chunks.append(paragraphs[i : i + self.pagination])
        return chunks

    async def _analyze_chunk(
        self,
        chunk: List[dict],
        issue_type: IssueType,
        risk_level: Optional[RiskLevel] = None,
    ) -> List[BaseIssue]:
        """Analyze a chunk of text for a specific issue type."""
        if issue_type == IssueType.GrammarSpelling:
            prompt_template = GRAMMAR_PROMPT
        else:
            prompt_template = DEFINITIVE_LANGUAGE_PROMPT

        issues = []
        for para in chunk:
            try:
                prompt = ChatPromptTemplate.from_template(prompt_template)
                chain = prompt | self.llm

                result = await chain.ainvoke({
                    "text": para["text"],
                    "page_num": para["page_num"],
                    "para_index": para["para_index"],
                    "format_instructions": self.parser.get_format_instructions(),
                })

                parsed = self.parser.parse(result.content)
                for analyzed_issue in parsed.issues:
                    issue = BaseIssue(
                        type=issue_type,
                        location=Location(
                            source_sentence=analyzed_issue.text,
                            page_num=para["page_num"],
                            bounding_box=para["bbox"],
                            para_index=para["para_index"],
                        ),
                        text=analyzed_issue.text,
                        explanation=analyzed_issue.explanation,
                        suggested_fix=analyzed_issue.suggested_fix,
                    )
                    issues.append(issue)
            except Exception as e:
                logging.warning(f"Failed to analyze paragraph: {e}")
                continue

        return issues

    async def _analyze_chunk_with_rule(
        self,
        chunk: List[dict],
        rule: ReviewRule,
    ) -> List[BaseIssue]:
        """Analyze a chunk of text with a custom rule."""
        examples_section = ""
        if rule.examples:
            examples_section = "Examples:\n"
            for ex in rule.examples:
                examples_section += f"- {ex.text}: {ex.explanation}\n"

        issues = []
        for para in chunk:
            try:
                prompt = ChatPromptTemplate.from_template(CUSTOM_RULE_PROMPT)
                chain = prompt | self.llm

                result = await chain.ainvoke({
                    "rule_name": rule.name,
                    "rule_description": rule.description,
                    "examples_section": examples_section,
                    "text": para["text"],
                    "page_num": para["page_num"],
                    "para_index": para["para_index"],
                    "format_instructions": self.parser.get_format_instructions(),
                })

                parsed = self.parser.parse(result.content)
                for analyzed_issue in parsed.issues:
                    issue = BaseIssue(
                        type=IssueType.GrammarSpelling,  # Use as placeholder, actual type set by rule name
                        location=Location(
                            source_sentence=analyzed_issue.text,
                            page_num=para["page_num"],
                            bounding_box=para["bbox"],
                            para_index=para["para_index"],
                        ),
                        text=analyzed_issue.text,
                        explanation=analyzed_issue.explanation,
                        suggested_fix=analyzed_issue.suggested_fix,
                    )
                    # Override type with rule name
                    issue.type = rule.name  # type: ignore
                    issues.append(issue)
            except Exception as e:
                logging.warning(f"Failed to analyze paragraph with rule {rule.name}: {e}")
                continue

        return issues

    async def process_document(
        self,
        pdf_path: str,
        custom_rules: Optional[List[ReviewRule]] = None,
    ) -> AsyncGenerator[List[BaseIssue], None]:
        """Process a PDF document and yield issues in chunks."""
        logging.info(f"Processing document: {pdf_path}")

        try:
            paragraphs = self._extract_text_with_positions(pdf_path)
            logging.info(f"Extracted {len(paragraphs)} paragraphs from PDF")
        except Exception as e:
            logging.error(f"Failed to extract text from PDF: {e}")
            return

        chunks = self._chunk_paragraphs(paragraphs)
        logging.info(f"Split into {len(chunks)} chunks for processing")

        for chunk_idx, chunk in enumerate(chunks):
            logging.info(f"Processing chunk {chunk_idx + 1}/{len(chunks)}")
            all_issues: List[BaseIssue] = []

            # If custom rules are provided, use them; otherwise use default types
            if custom_rules:
                for rule in custom_rules:
                    try:
                        issues = await self._analyze_chunk_with_rule(chunk, rule)
                        all_issues.extend(issues)
                    except Exception as e:
                        logging.error(f"Error analyzing with rule {rule.name}: {e}")
            else:
                # Default: run both grammar and definitive language checks
                for issue_type in [IssueType.GrammarSpelling, IssueType.DefinitiveLanguage]:
                    try:
                        issues = await self._analyze_chunk(chunk, issue_type)
                        all_issues.extend(issues)
                    except Exception as e:
                        logging.error(f"Error analyzing for {issue_type}: {e}")

            if all_issues:
                yield all_issues

        logging.info(f"Finished processing document: {pdf_path}")
