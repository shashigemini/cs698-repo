"""Document repository — data access for ingested documents."""

import uuid
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.document import Document


class DocumentRepository:
    """Encapsulates document database queries."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def create(
        self,
        *,
        logical_book_id: str,
        title: str,
        file_path: str,
        author: Optional[str] = None,
        edition: Optional[str] = None,
        embedding_model: str = "text-embedding-ada-002",
    ) -> Document:
        """Create a new document record."""
        doc = Document(
            logical_book_id=logical_book_id,
            title=title,
            file_path=file_path,
            author=author,
            edition=edition,
            embedding_model=embedding_model,
        )
        self._session.add(doc)
        await self._session.flush()
        return doc

    async def get_by_id(
        self, doc_id: uuid.UUID
    ) -> Optional[Document]:
        """Look up a document by ID."""
        result = await self._session.execute(
            select(Document).where(Document.id == doc_id)
        )
        return result.scalar_one_or_none()

    async def list_all(self) -> list[Document]:
        """List all documents, newest first."""
        result = await self._session.execute(
            select(Document).order_by(Document.created_at.desc())
        )
        return list(result.scalars().all())

    async def update_status(
        self,
        doc_id: uuid.UUID,
        *,
        status: str,
        chunks_created: Optional[int] = None,
        total_pages: Optional[int] = None,
    ) -> None:
        """Update ingestion status and optionally chunk/page counts."""
        doc = await self.get_by_id(doc_id)
        if doc:
            doc.ingestion_status = status
            if chunks_created is not None:
                doc.chunks_created = chunks_created
            if total_pages is not None:
                doc.total_pages = total_pages
            await self._session.flush()

    async def delete(self, doc_id: uuid.UUID) -> bool:
        """Delete a document record."""
        doc = await self.get_by_id(doc_id)
        if not doc:
            return False
        await self._session.delete(doc)
        await self._session.flush()
        return True
