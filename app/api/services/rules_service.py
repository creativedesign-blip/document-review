from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from uuid import uuid4

from common.logger import get_logger
from common.models import (
    ReviewRule,
    RuleExample,
    RiskLevel,
    RuleStatusEnum,
    DocumentRuleAssociation,
)
from database.rules_repository import RulesRepository

logging = get_logger(__name__)


class RulesService:
    """Service for managing review rules."""

    def __init__(self, repository: RulesRepository):
        self.repository = repository

    async def get_all_rules(self) -> List[ReviewRule]:
        """Get all review rules."""
        return await self.repository.get_all_rules()

    async def get_rules_by_ids(self, rule_ids: List[str]) -> List[ReviewRule]:
        """Get rules by their IDs."""
        rules = []
        for rule_id in rule_ids:
            try:
                rule = await self.repository.get_rule(rule_id)
                rules.append(rule)
            except ValueError:
                logging.warning(f"Rule {rule_id} not found, skipping")
        return rules

    async def get_rule(self, rule_id: str) -> ReviewRule:
        """Get a specific rule by ID."""
        return await self.repository.get_rule(rule_id)

    async def create_rule(
        self,
        name: str,
        description: str,
        risk_level: RiskLevel,
        examples: Optional[List[RuleExample]] = None,
    ) -> ReviewRule:
        """Create a new review rule."""
        now = datetime.now(timezone.utc).isoformat()
        rule = ReviewRule(
            id=str(uuid4()),
            name=name,
            description=description,
            risk_level=risk_level,
            examples=examples or [],
            status=RuleStatusEnum.active,
            created_at=now,
            updated_at=now,
        )
        return await self.repository.create_rule(rule)

    async def update_rule(self, rule_id: str, fields: Dict[str, Any]) -> ReviewRule:
        """Update a rule with new field values."""
        fields["updated_at"] = datetime.now(timezone.utc).isoformat()
        return await self.repository.update_rule(rule_id, fields)

    async def delete_rule(self, rule_id: str) -> None:
        """Delete a rule."""
        await self.repository.delete_rule(rule_id)

    async def get_document_rules(self, doc_id: str) -> List[DocumentRuleAssociation]:
        """Get all rule associations for a document."""
        return await self.repository.get_document_rules(doc_id)

    async def set_document_rule(
        self, doc_id: str, rule_id: str, enabled: bool
    ) -> None:
        """Enable or disable a rule for a specific document."""
        # Verify rule exists
        await self.repository.get_rule(rule_id)
        await self.repository.set_document_rule(doc_id, rule_id, enabled)

    async def get_enabled_rules_for_document(self, doc_id: str) -> List[ReviewRule]:
        """Get all enabled rules for a specific document."""
        return await self.repository.get_enabled_rules_for_document(doc_id)
