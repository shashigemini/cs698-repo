"""Conversation service — CRUD and export for chat sessions."""

import json
import uuid
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import ForbiddenError, NotFoundError
from app.core.logging import get_logger
from app.models.chat_session import ChatSession
from app.repositories.session_repo import MessageRepository, SessionRepository
from app.schemas.chat_schemas import (
    ConversationSummary,
    ExportResponse,
    MessageResponse,
)

logger = get_logger(__name__)


class ConversationService:
    """Manages conversation lifecycle and ownership verification."""

    def __init__(self, session: AsyncSession) -> None:
        self._session_repo = SessionRepository(session)
        self._message_repo = MessageRepository(session)

    async def list_conversations(
        self, user_id: str, limit: int = 20, offset: int = 0
    ) -> list[ConversationSummary]:
        """List all conversations for a user."""
        session_stats = await self._session_repo.list_for_user_with_stats(
            uuid.UUID(user_id), limit=limit, offset=offset
        )
        return [
            ConversationSummary(
                id=str(stat["session"].id),
                title=stat["session"].title,
                created_at=stat["session"].created_at,
                updated_at=stat["session"].updated_at,
                message_count=stat["message_count"],
                last_message_preview=stat["last_message_preview"],
            )
            for stat in session_stats
        ]

    async def load_history(
        self, user_id: str, conversation_id: str
    ) -> list[MessageResponse]:
        """Load all messages in a conversation.

        Raises:
            NotFoundError: If conversation doesn't exist.
            ForbiddenError: If user doesn't own the conversation.
        """
        session = await self._verify_ownership(
            user_id, conversation_id
        )

        messages = await self._message_repo.list_for_session(
            uuid.UUID(conversation_id)
        )

        return [
            MessageResponse(
                id=str(m.id),
                sender=m.sender,
                content=m.content,
                citations=(
                    m.rag_metadata.get("citations", [])
                    if m.rag_metadata
                    else []
                ),
                timestamp=m.created_at,
            )
            for m in messages
        ]

    async def delete_conversation(
        self, user_id: str, conversation_id: str
    ) -> None:
        """Delete a conversation after verifying ownership."""
        await self._verify_ownership(user_id, conversation_id)

        deleted = await self._session_repo.delete(
            uuid.UUID(conversation_id)
        )
        if not deleted:
            raise NotFoundError(
                error_code="CONVERSATION_NOT_FOUND"
            )

        await self._session_repo._session.commit()
        logger.info("Conversation deleted")

    async def export_conversation(
        self, user_id: str, conversation_id: str
    ) -> ExportResponse:
        """Export a conversation as Markdown."""
        session = await self._verify_ownership(
            user_id, conversation_id
        )

        messages = await self._message_repo.list_for_session(
            uuid.UUID(conversation_id)
        )

        lines = [f"# {session.title or 'Conversation'}\n"]
        for m in messages:
            label = "You" if m.sender == "user" else "Assistant"
            lines.append(f"**{label}** ({m.created_at.isoformat()}):\n")
            lines.append(f"{m.content}\n")

            if m.rag_metadata and m.rag_metadata.get("citations"):
                lines.append("\n_Citations:_\n")
                for c in m.rag_metadata["citations"]:
                    lines.append(
                        f"- {c.get('title', 'Unknown')}, "
                        f"p.{c.get('page', '?')}\n"
                    )
            lines.append("---\n")

        return ExportResponse(export_data="\n".join(lines))

    async def _verify_ownership(
        self, user_id: str, conversation_id: str
    ) -> ChatSession:
        """Verify that a conversation belongs to the given user.

        Returns the ChatSession if valid.
        Raises NotFoundError or ForbiddenError.
        """
        session = await self._session_repo.get_by_id(
            uuid.UUID(conversation_id)
        )
        if not session:
            raise NotFoundError(
                error_code="CONVERSATION_NOT_FOUND"
            )
        if str(session.user_id) != user_id:
            raise ForbiddenError()
        return session
