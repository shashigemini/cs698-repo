"""Session and message repository — data access for conversations."""

import uuid
from typing import Optional

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.chat_message import ChatMessage
from app.models.chat_session import ChatSession


class SessionRepository:
    """Encapsulates chat session database queries."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def create(
        self,
        *,
        user_id: uuid.UUID,
        title: Optional[str] = None,
        wrapped_conversation_key: Optional[str] = None,
    ) -> ChatSession:
        """Create a new chat session."""
        chat_session = ChatSession(
            user_id=user_id,
            title=title,
            wrapped_conversation_key=wrapped_conversation_key,
        )
        self._session.add(chat_session)
        await self._session.flush()
        return chat_session

    async def get_by_id(
        self, session_id: uuid.UUID
    ) -> Optional[ChatSession]:
        """Look up a session by ID."""
        result = await self._session.execute(
            select(ChatSession).where(ChatSession.id == session_id)
        )
        return result.scalar_one_or_none()

    async def list_for_user(
        self, user_id: uuid.UUID, limit: int = 20, offset: int = 0
    ) -> list[ChatSession]:
        """List all sessions for a user, newest first."""
        result = await self._session.execute(
            select(ChatSession)
            .where(ChatSession.user_id == user_id)
            .order_by(ChatSession.updated_at.desc())
            .limit(limit)
            .offset(offset)
        )
        return list(result.scalars().all())

    async def list_for_user_with_stats(
        self, user_id: uuid.UUID, limit: int = 20, offset: int = 0
    ) -> list[dict]:
        """List all sessions with aggregate statistics."""
        sessions = await self.list_for_user(user_id, limit, offset)
        
        results = []
        for session in sessions:
            count_res = await self._session.execute(
                select(func.count(ChatMessage.id))
                .where(ChatMessage.session_id == session.id)
            )
            count = count_res.scalar_one()
            
            last_msg_res = await self._session.execute(
                select(ChatMessage)
                .where(ChatMessage.session_id == session.id)
                .order_by(ChatMessage.created_at.desc())
                .limit(1)
            )
            last_msg = last_msg_res.scalar_one_or_none()
            preview = last_msg.content[:100] if last_msg else None
            
            results.append({
                "session": session,
                "message_count": count,
                "last_message_preview": preview,
            })
            
        return results

    async def update_title(
        self, session_id: uuid.UUID, title: str
    ) -> None:
        """Update a session's title."""
        session = await self.get_by_id(session_id)
        if session:
            session.title = title
            await self._session.flush()

    async def delete(self, session_id: uuid.UUID) -> bool:
        """Delete a session and cascade to messages."""
        session = await self.get_by_id(session_id)
        if not session:
            return False
        await self._session.delete(session)
        await self._session.flush()
        return True


class MessageRepository:
    """Encapsulates chat message database queries."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def create(
        self,
        *,
        session_id: uuid.UUID,
        sender: str,
        content: str,
        rag_metadata: Optional[dict] = None,
    ) -> ChatMessage:
        """Create a new message in a session."""
        message = ChatMessage(
            session_id=session_id,
            sender=sender,
            content=content,
            rag_metadata=rag_metadata,
        )
        self._session.add(message)
        await self._session.flush()
        return message

    async def list_for_session(
        self, session_id: uuid.UUID
    ) -> list[ChatMessage]:
        """List all messages in a session, chronologically."""
        result = await self._session.execute(
            select(ChatMessage)
            .where(ChatMessage.session_id == session_id)
            .order_by(ChatMessage.created_at.asc())
        )
        return list(result.scalars().all())

    async def get_recent_pairs(
        self, session_id: uuid.UUID, limit: int = 5
    ) -> list[ChatMessage]:
        """Get the most recent message pairs for context injection.

        Returns the last N*2 messages (user+assistant pairs).
        """
        result = await self._session.execute(
            select(ChatMessage)
            .where(ChatMessage.session_id == session_id)
            .order_by(ChatMessage.created_at.desc())
            .limit(limit * 2)
        )
        messages = list(result.scalars().all())
        messages.reverse()  # Chronological order
        return messages
