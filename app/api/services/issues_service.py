from datetime import datetime, timezone
from typing import Any, AsyncGenerator, Dict, List, Optional
from uuid import uuid4

from common.logger import get_logger
from common.models import (
    Issue,
    IssueStatusEnum,
    ModifiedFieldsModel,
    DismissalFeedbackModel,
    ReviewRule,
)
from database.issues_repository import IssuesRepository

logging = get_logger(__name__)


class HITLHandler:
    """Human-in-the-loop handler for issue updates with approval workflow."""

    def __init__(self, repository: IssuesRepository):
        self.repository = repository
        self._pending_updates: Dict[str, Dict[str, Any]] = {}

    async def start_update(
        self, thread_id: str, issue_id: str, update_fields: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """Start a HITL-gated update. Returns interrupt info for user approval."""
        self._pending_updates[thread_id] = {
            "issue_id": issue_id,
            "update_fields": update_fields,
        }
        return {
            "id": str(uuid4()),
            "type": "tool_approval",
            "tool_name": "update_issue",
            "args": {"issue_id": issue_id, "update_fields": update_fields},
        }

    async def resume_update(
        self,
        thread_id: str,
        interrupt_id: Optional[str],
        decision: Dict[str, Any],
    ) -> None:
        """Resume a HITL-gated update with user decision."""
        pending = self._pending_updates.get(thread_id)
        if not pending:
            raise ValueError(f"No pending update for thread {thread_id}")

        decision_type = decision.get("type", "approve")

        if decision_type == "reject":
            del self._pending_updates[thread_id]
            return

        update_fields = pending["update_fields"]
        if decision_type == "edit":
            edited_action = decision.get("edited_action", {})
            edited_args = edited_action.get("args", {})
            if "update_fields" in edited_args:
                update_fields = edited_args["update_fields"]

        await self.repository.update_issue(pending["issue_id"], update_fields)
        del self._pending_updates[thread_id]

    async def get_issue(self, issue_id: str) -> Issue:
        """Get issue by ID."""
        return await self.repository.get_issue(issue_id)


class IssuesService:
    """Service for managing document review issues."""

    def __init__(self, repository: IssuesRepository, pipeline: "LangChainPipeline"):
        self.issues_repository = repository
        self.pipeline = pipeline
        self.hitl = HITLHandler(repository)

    async def get_issues_data(self, doc_id: str) -> List[Issue]:
        """Get all issues for a document."""
        return await self.issues_repository.get_issues(doc_id)

    async def initiate_review(
        self,
        pdf_path: str,
        user: Any,
        date_time: datetime,
        custom_rules: Optional[List[ReviewRule]] = None,
    ) -> AsyncGenerator[List[Issue], None]:
        """Initiate document review and stream issues."""
        doc_id = pdf_path.split("/")[-1].split("\\")[-1]  # Get filename
        user_id = getattr(user, "oid", "anonymous")
        timestamp = date_time.isoformat()

        async for base_issues in self.pipeline.process_document(pdf_path, custom_rules):
            issues = []
            for base_issue in base_issues:
                issue = Issue(
                    id=str(uuid4()),
                    doc_id=doc_id,
                    text=base_issue.text,
                    type=base_issue.type.value if hasattr(base_issue.type, "value") else str(base_issue.type),
                    status=IssueStatusEnum.not_reviewed,
                    suggested_fix=base_issue.suggested_fix,
                    explanation=base_issue.explanation,
                    location=base_issue.location,
                    review_initiated_by=user_id,
                    review_initiated_at_UTC=timestamp,
                )
                issues.append(issue)

            if issues:
                await self.issues_repository.store_issues(issues)
                yield issues

    async def accept_issue(
        self,
        issue_id: str,
        user: Any,
        modified_fields: Optional[ModifiedFieldsModel] = None,
    ) -> Issue:
        """Accept an issue with optional modifications."""
        user_id = getattr(user, "oid", "anonymous")
        update_fields: Dict[str, Any] = {
            "status": IssueStatusEnum.accepted.value,
            "resolved_by": user_id,
            "resolved_at_UTC": datetime.now(timezone.utc).isoformat(),
        }
        if modified_fields:
            update_fields["modified_fields"] = modified_fields.model_dump(exclude_none=True)

        return await self.issues_repository.update_issue(issue_id, update_fields)

    async def dismiss_issue(
        self,
        issue_id: str,
        user: Any,
        dismissal_feedback: Optional[DismissalFeedbackModel] = None,
    ) -> Issue:
        """Dismiss an issue with optional feedback."""
        user_id = getattr(user, "oid", "anonymous")
        update_fields: Dict[str, Any] = {
            "status": IssueStatusEnum.dismissed.value,
            "resolved_by": user_id,
            "resolved_at_UTC": datetime.now(timezone.utc).isoformat(),
        }
        if dismissal_feedback:
            update_fields["dismissal_feedback"] = dismissal_feedback.model_dump(exclude_none=True)

        return await self.issues_repository.update_issue(issue_id, update_fields)

    async def add_feedback(
        self, issue_id: str, feedback: DismissalFeedbackModel
    ) -> Issue:
        """Add feedback to an existing issue."""
        update_fields = {"dismissal_feedback": feedback.model_dump(exclude_none=True)}
        return await self.issues_repository.update_issue(issue_id, update_fields)


# Import at bottom to avoid circular imports
from services.lc_pipeline import LangChainPipeline
