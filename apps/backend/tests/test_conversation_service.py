"""Tests for ConversationService — list, load, delete, export."""

import uuid

import pytest
import pytest_asyncio

from app.core.exceptions import ForbiddenError, NotFoundError
from app.models.user import User
from app.repositories.session_repo import (
    MessageRepository,
    SessionRepository,
)
from app.services.conversation_service import ConversationService


@pytest_asyncio.fixture
async def user_a(db_session):
    """Create user A."""
    u = User(
        email="user-a@example.com",
        password_hash="argon2$fake",
        role="user",
    )
    db_session.add(u)
    await db_session.flush()
    return u


@pytest_asyncio.fixture
async def user_b(db_session):
    """Create user B (different from A)."""
    u = User(
        email="user-b@example.com",
        password_hash="argon2$fake",
        role="user",
    )
    db_session.add(u)
    await db_session.flush()
    return u


@pytest.fixture
def service(db_session):
    """Provide a ConversationService instance."""
    return ConversationService(db_session)


@pytest_asyncio.fixture
async def conversation_with_messages(
    db_session, user_a, service
):
    """Create a conversation with some messages."""
    session_repo = SessionRepository(db_session)
    message_repo = MessageRepository(db_session)

    session = await session_repo.create(
        user_id=user_a.id, title="Test Chat"
    )
    await message_repo.create(
        session_id=session.id,
        sender="user",
        content="What is dharma?",
    )
    await message_repo.create(
        session_id=session.id,
        sender="assistant",
        content="Dharma refers to cosmic law.",
        rag_metadata={"citations": [{"source": "doc1"}]},
    )
    return session


class TestListConversations:
    """Tests for listing user conversations."""

    @pytest.mark.asyncio
    async def test_returns_user_sessions(
        self, service, user_a, db_session
    ):
        s_repo = SessionRepository(db_session)
        await s_repo.create(user_id=user_a.id, title="Chat 1")
        await s_repo.create(user_id=user_a.id, title="Chat 2")

        convos = await service.list_conversations(
            user_id=str(user_a.id)
        )
        assert len(convos) == 2

    @pytest.mark.asyncio
    async def test_empty_for_new_user(self, service, user_b):
        convos = await service.list_conversations(
            user_id=str(user_b.id)
        )
        assert convos == []


class TestLoadHistory:
    """Tests for loading conversation messages."""

    @pytest.mark.asyncio
    async def test_loads_messages(
        self, service, user_a, conversation_with_messages
    ):
        result = await service.load_history(
            conversation_id=str(conversation_with_messages.id),
            user_id=str(user_a.id),
        )
        assert len(result) == 2
        assert result[0].sender == "user"

    @pytest.mark.asyncio
    async def test_not_found(self, service, user_a):
        fake_id = str(uuid.uuid4())
        with pytest.raises(NotFoundError):
            await service.load_history(
                conversation_id=fake_id,
                user_id=str(user_a.id),
            )

    @pytest.mark.asyncio
    async def test_wrong_user_forbidden(
        self,
        service,
        user_b,
        conversation_with_messages,
    ):
        with pytest.raises(ForbiddenError):
            await service.load_history(
                conversation_id=str(
                    conversation_with_messages.id
                ),
                user_id=str(user_b.id),
            )


class TestDeleteConversation:
    """Tests for deleting conversations."""

    @pytest.mark.asyncio
    async def test_deletes_owned(
        self, service, user_a, conversation_with_messages
    ):
        await service.delete_conversation(
            conversation_id=str(
                conversation_with_messages.id
            ),
            user_id=str(user_a.id),
        )
        with pytest.raises(NotFoundError):
            await service.load_history(
                conversation_id=str(
                    conversation_with_messages.id
                ),
                user_id=str(user_a.id),
            )

    @pytest.mark.asyncio
    async def test_wrong_user_forbidden(
        self, service, user_b, conversation_with_messages
    ):
        with pytest.raises(ForbiddenError):
            await service.delete_conversation(
                conversation_id=str(
                    conversation_with_messages.id
                ),
                user_id=str(user_b.id),
            )


class TestExportConversation:
    """Tests for exporting conversations."""

    @pytest.mark.asyncio
    async def test_exports_markdown(
        self, service, user_a, conversation_with_messages
    ):
        result = await service.export_conversation(
            conversation_id=str(
                conversation_with_messages.id
            ),
            user_id=str(user_a.id),
        )
        assert "dharma" in result.export_data.lower()
