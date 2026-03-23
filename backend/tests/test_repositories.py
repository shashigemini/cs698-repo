"""Tests for repository layer — Session, Message, Document, RevokedToken."""

import uuid
from datetime import datetime, timedelta, timezone

import pytest
import pytest_asyncio

from app.models.chat_message import ChatMessage
from app.models.chat_session import ChatSession
from app.models.document import Document
from app.models.revoked_token import RevokedToken
from app.models.user import User
from app.repositories.document_repo import DocumentRepository
from app.repositories.revoked_token_repo import RevokedTokenRepository
from app.repositories.session_repo import (
    MessageRepository,
    SessionRepository,
)


@pytest_asyncio.fixture
async def user(db_session):
    """Create a test user and return it."""
    u = User(
        email="repo-test@example.com",
        password_hash="argon2$fake",
        role="user",
    )
    db_session.add(u)
    await db_session.flush()
    return u


# --- SessionRepository ---


class TestSessionRepository:
    """Tests for ChatSession CRUD operations."""

    @pytest.mark.asyncio
    async def test_create_session(self, db_session, user):
        repo = SessionRepository(db_session)
        session = await repo.create(user_id=user.id, title="Test")
        assert session.id is not None
        assert session.user_id == user.id
        assert session.title == "Test"

    @pytest.mark.asyncio
    async def test_get_by_id(self, db_session, user):
        repo = SessionRepository(db_session)
        created = await repo.create(user_id=user.id, title="Find")
        found = await repo.get_by_id(created.id)
        assert found is not None
        assert found.id == created.id

    @pytest.mark.asyncio
    async def test_get_by_id_missing(self, db_session):
        repo = SessionRepository(db_session)
        found = await repo.get_by_id(uuid.uuid4())
        assert found is None

    @pytest.mark.asyncio
    async def test_list_for_user(self, db_session, user):
        repo = SessionRepository(db_session)
        await repo.create(user_id=user.id, title="A")
        await repo.create(user_id=user.id, title="B")
        sessions = await repo.list_for_user(user.id)
        assert len(sessions) == 2

    @pytest.mark.asyncio
    async def test_update_title(self, db_session, user):
        repo = SessionRepository(db_session)
        s = await repo.create(user_id=user.id, title="Old")
        await repo.update_title(s.id, "New Title")
        updated = await repo.get_by_id(s.id)
        assert updated is not None
        assert updated.title == "New Title"

    @pytest.mark.asyncio
    async def test_delete(self, db_session, user):
        repo = SessionRepository(db_session)
        s = await repo.create(user_id=user.id, title="Del")
        result = await repo.delete(s.id)
        assert result is True
        assert await repo.get_by_id(s.id) is None


# --- MessageRepository ---


class TestMessageRepository:
    """Tests for ChatMessage CRUD operations."""

    @pytest.mark.asyncio
    async def test_create_message(self, db_session, user):
        s_repo = SessionRepository(db_session)
        session = await s_repo.create(
            user_id=user.id, title="Chat"
        )
        m_repo = MessageRepository(db_session)
        msg = await m_repo.create(
            session_id=session.id,
            sender="user",
            content="Hello!",
        )
        assert msg.id is not None
        assert msg.sender == "user"
        assert msg.content == "Hello!"

    @pytest.mark.asyncio
    async def test_list_for_session(self, db_session, user):
        s_repo = SessionRepository(db_session)
        session = await s_repo.create(
            user_id=user.id, title="Chat"
        )
        m_repo = MessageRepository(db_session)
        await m_repo.create(
            session_id=session.id,
            sender="user",
            content="Hi",
        )
        await m_repo.create(
            session_id=session.id,
            sender="assistant",
            content="Hello",
        )
        messages = await m_repo.list_for_session(session.id)
        assert len(messages) == 2

    @pytest.mark.asyncio
    async def test_get_recent_pairs(self, db_session, user):
        s_repo = SessionRepository(db_session)
        session = await s_repo.create(
            user_id=user.id, title="Chat"
        )
        m_repo = MessageRepository(db_session)
        for i in range(6):
            await m_repo.create(
                session_id=session.id,
                sender="user" if i % 2 == 0 else "assistant",
                content=f"Message {i}",
            )
        pairs = await m_repo.get_recent_pairs(
            session.id, limit=2
        )
        assert len(pairs) <= 4


# --- DocumentRepository ---


class TestDocumentRepository:
    """Tests for Document CRUD operations."""

    @pytest.mark.asyncio
    async def test_create_document(self, db_session):
        repo = DocumentRepository(db_session)
        doc = await repo.create(
            logical_book_id="book-1",
            title="Test Book",
            file_path="/data/test.pdf",
        )
        assert doc.id is not None
        assert doc.title == "Test Book"
        assert doc.ingestion_status == "pending"

    @pytest.mark.asyncio
    async def test_get_by_id(self, db_session):
        repo = DocumentRepository(db_session)
        doc = await repo.create(
            logical_book_id="book-2",
            title="Find Book",
            file_path="/data/find.pdf",
        )
        found = await repo.get_by_id(doc.id)
        assert found is not None
        assert found.title == "Find Book"

    @pytest.mark.asyncio
    async def test_list_all(self, db_session):
        repo = DocumentRepository(db_session)
        await repo.create(
            logical_book_id="b1",
            title="A",
            file_path="/a.pdf",
        )
        await repo.create(
            logical_book_id="b2",
            title="B",
            file_path="/b.pdf",
        )
        docs = await repo.list_all()
        assert len(docs) == 2

    @pytest.mark.asyncio
    async def test_update_status(self, db_session):
        repo = DocumentRepository(db_session)
        doc = await repo.create(
            logical_book_id="b3",
            title="Status",
            file_path="/s.pdf",
        )
        await repo.update_status(
            doc.id,
            status="completed",
            chunks_created=42,
            total_pages=10,
        )
        updated = await repo.get_by_id(doc.id)
        assert updated is not None
        assert updated.ingestion_status == "completed"
        assert updated.chunks_created == 42
        assert updated.total_pages == 10

    @pytest.mark.asyncio
    async def test_delete(self, db_session):
        repo = DocumentRepository(db_session)
        doc = await repo.create(
            logical_book_id="b4",
            title="Delete",
            file_path="/d.pdf",
        )
        assert await repo.delete(doc.id) is True
        assert await repo.get_by_id(doc.id) is None

    @pytest.mark.asyncio
    async def test_delete_nonexistent(self, db_session):
        repo = DocumentRepository(db_session)
        assert await repo.delete(uuid.uuid4()) is False


# --- RevokedTokenRepository ---


class TestRevokedTokenRepository:
    """Tests for token revocation tracking."""

    @pytest.mark.asyncio
    async def test_revoke_token(self, db_session, user):
        repo = RevokedTokenRepository(db_session)
        jti = str(uuid.uuid4())
        expires = datetime.now(timezone.utc) + timedelta(days=7)
        await repo.revoke(
            token_jti=jti,
            user_id=user.id,
            expires_at=expires,
        )
        assert await repo.is_revoked(jti) is True

    @pytest.mark.asyncio
    async def test_is_revoked_false(self, db_session):
        repo = RevokedTokenRepository(db_session)
        assert await repo.is_revoked("nonexistent-jti") is False

    @pytest.mark.asyncio
    async def test_cleanup_expired(self, db_session, user):
        repo = RevokedTokenRepository(db_session)
        jti = str(uuid.uuid4())
        expired_time = datetime.now(timezone.utc) - timedelta(
            days=1
        )
        await repo.revoke(
            token_jti=jti,
            user_id=user.id,
            expires_at=expired_time,
        )
        count = await repo.cleanup_expired()
        assert count >= 1
        assert await repo.is_revoked(jti) is False
