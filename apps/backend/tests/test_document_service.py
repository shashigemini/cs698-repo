"""Tests for DocumentService — ingest, validate, list, delete."""

import io
import os
import tempfile
import uuid
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
import pytest_asyncio

from fastapi import BackgroundTasks
from app.models.user import User
from app.repositories.document_repo import DocumentRepository
from app.services.document_service import DocumentService


@pytest_asyncio.fixture
async def user(db_session):
    """Create a test user."""
    u = User(
        email="doc-test@example.com",
        password_hash="argon2$fake",
        role="admin",
    )
    db_session.add(u)
    await db_session.flush()
    return u


@pytest.fixture
def tmp_storage(tmp_path):
    """Provide a temporary PDF storage directory."""
    return str(tmp_path / "pdfs")


@pytest.fixture
def doc_service(db_session, test_settings, tmp_storage):
    """Provide a DocumentService with test settings."""
    test_settings.pdf_storage_path = tmp_storage
    return DocumentService(
        settings=test_settings,
        session=db_session,
    )


def _make_pdf_file(
    content: bytes = b"%PDF-1.4 fake pdf content",
    filename: str = "test.pdf",
    size: int | None = None,
):
    """Create a mock UploadFile-like object."""
    if size:
        content = b"%PDF-1.4" + b"x" * (size - 8)
    file_mock = MagicMock()
    file_mock.filename = filename
    file_mock.content_type = "application/pdf"
    file_mock.size = len(content)
    file_mock.file = io.BytesIO(content)

    async def read_mock():
        return content

    file_mock.read = AsyncMock(side_effect=read_mock)
    return file_mock


class TestIngest:
    """Tests for document ingestion."""

    @pytest.mark.asyncio
    async def test_valid_pdf_ingested(
        self, doc_service, db_session
    ):
        """Valid PDF creates DB record in pending status."""
        upload = _make_pdf_file()
        result = await doc_service.ingest(
            file_content=await upload.read(),
            filename=upload.filename,
            title="Test Book",
            logical_book_id="book-1",
            background_tasks=BackgroundTasks(),
        )
        assert result["title"] == "Test Book"
        assert result["status"] == "pending"

    @pytest.mark.asyncio
    async def test_rejects_non_pdf_extension(
        self, doc_service
    ):
        """Non-.pdf extension is rejected."""
        upload = _make_pdf_file(filename="test.docx")
        with pytest.raises(Exception):
            await doc_service.ingest(
                file_content=await upload.read(),
                filename=upload.filename,
                title="Bad",
                logical_book_id="book-bad",
                background_tasks=BackgroundTasks(),
            )

    @pytest.mark.asyncio
    async def test_rejects_non_pdf_magic_bytes(
        self, doc_service
    ):
        """File without PDF magic bytes is rejected."""
        upload = _make_pdf_file(
            content=b"NOT A PDF FILE",
            filename="fake.pdf",
        )
        with pytest.raises(Exception):
            await doc_service.ingest(
                file_content=await upload.read(),
                filename=upload.filename,
                title="Fake",
                logical_book_id="book-fake",
                background_tasks=BackgroundTasks(),
            )

    @pytest.mark.asyncio
    async def test_rejects_oversized(self, doc_service):
        """File exceeding max_upload_bytes is rejected."""
        oversized = _make_pdf_file(
            size=doc_service._settings.max_upload_bytes + 1024
        )
        with pytest.raises(Exception):
            await doc_service.ingest(
                file_content=await oversized.read(),
                filename=oversized.filename,
                title="Big",
                logical_book_id="book-big",
                background_tasks=BackgroundTasks(),
            )


class TestListDocuments:
    """Tests for listing documents."""

    @pytest.mark.asyncio
    async def test_list_returns_all(
        self, doc_service, db_session
    ):
        doc_repo = DocumentRepository(db_session)
        await doc_repo.create(
            logical_book_id="b1",
            title="A",
            file_path="/a.pdf",
        )
        await doc_repo.create(
            logical_book_id="b2",
            title="B",
            file_path="/b.pdf",
        )
        docs = await doc_service.list_documents()
        assert len(docs) == 2


class TestDeleteDocument:
    """Tests for deleting documents."""

    @pytest.mark.asyncio
    async def test_delete_removes_record(
        self, doc_service, db_session
    ):
        doc_repo = DocumentRepository(db_session)
        doc = await doc_repo.create(
            logical_book_id="b3",
            title="Del",
            file_path="/del.pdf",
        )
        result = await doc_service.delete_document(
            doc_id=str(doc.id)
        )
        assert result is True

    @pytest.mark.asyncio
    async def test_delete_nonexistent(self, doc_service):
        fake_id = str(uuid.uuid4())
        result = await doc_service.delete_document(doc_id=fake_id)
        assert result is False
