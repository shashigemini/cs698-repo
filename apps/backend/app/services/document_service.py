"""Document ingestion service — PDF upload and processing."""

import os
import uuid
from typing import Optional

from fastapi import BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import Settings
from app.core.exceptions import ValidationError
from app.core.logging import get_logger
from app.repositories.document_repo import DocumentRepository

logger = get_logger(__name__)


class DocumentService:
    """Manages document upload, validation, and ingestion."""

    def __init__(
        self,
        settings: Settings,
        session: AsyncSession,
    ) -> None:
        self._settings = settings
        self._doc_repo = DocumentRepository(session)

    async def ingest(
        self,
        *,
        file_content: bytes,
        filename: str,
        title: str,
        logical_book_id: str,
        background_tasks: BackgroundTasks,
        author: Optional[str] = None,
        edition: Optional[str] = None,
    ) -> dict:
        """Validate, store, and begin ingestion of a PDF.

        Args:
            file_content: Raw PDF bytes.
            filename: Original filename (discarded after validation).
            title: Document title for metadata.
            logical_book_id: Identifier grouping editions of same book.
            author: Optional author name.
            edition: Optional edition identifier.

        Returns:
            Dict with document_id and status.
        """
        # --- Validate file ---
        self._validate_file(file_content, filename)

        # --- Store with UUID filename (anti-path-traversal) ---
        safe_name = f"{uuid.uuid4()}.pdf"
        storage_dir = self._settings.pdf_storage_path
        os.makedirs(storage_dir, exist_ok=True)
        file_path = os.path.join(storage_dir, safe_name)

        with open(file_path, "wb") as f:
            f.write(file_content)

        # --- Create DB record ---
        doc = await self._doc_repo.create(
            logical_book_id=logical_book_id,
            title=title,
            file_path=file_path,
            author=author,
            edition=edition,
        )

        # --- Trigger async ingestion pipeline ---
        await self._doc_repo.update_status(
            doc.id, status="pending"
        )
        await self._doc_repo._session.commit()
        
        background_tasks.add_task(
            self._process_document_pipeline,
            doc_id=doc.id,
            file_path=file_path,
            title=title,
            author=author,
        )

        logger.info(
            "Document queued for ingestion: %s (%s)",
            title, str(doc.id),
        )

        return {
            "document_id": str(doc.id),
            "title": title,
            "status": "pending",
        }

    async def list_documents(self) -> list[dict]:
        """List all ingested documents."""
        docs = await self._doc_repo.list_all()
        return [
            {
                "id": str(d.id),
                "title": d.title,
                "author": d.author,
                "logical_book_id": d.logical_book_id,
                "status": d.ingestion_status,
                "chunks_created": d.chunks_created,
                "created_at": d.created_at.isoformat(),
            }
            for d in docs
        ]

    async def delete_document(self, doc_id: str) -> bool:
        """Delete a document record, its stored file, and Qdrant points."""
        from app.rag.qdrant_store import QdrantStore

        doc = await self._doc_repo.get_by_id(uuid.UUID(doc_id))
        if not doc:
            return False

        # Delete from Qdrant
        try:
            qdrant = QdrantStore(self._settings)
            await qdrant.delete_document_chunks(doc_id)
        except Exception as e:
            logger.error("Failed to delete chunks for %s from Qdrant: %s", doc_id, e)

        # Delete file
        if os.path.exists(doc.file_path):
            os.remove(doc.file_path)

        deleted = await self._doc_repo.delete(uuid.UUID(doc_id))
        if deleted:
            await self._doc_repo._session.commit()
        return deleted

    async def _process_document_pipeline(
        self,
        doc_id: uuid.UUID,
        file_path: str,
        title: str,
        author: Optional[str] = None,
    ) -> None:
        """Background task to extract, chunk, embed, and store document."""
        from app.dependencies import _database
        from app.rag.chunker import chunk_text
        from app.rag.embedder import Embedder
        from app.rag.pdf_parser import parse_pdf
        from app.rag.qdrant_store import QdrantStore

        if _database is None:
            logger.error("Database not initialized for background task")
            return

        try:
            async for session in _database.get_session():
                repo = DocumentRepository(session)
                
                # Update status to processing
                await repo.update_status(doc_id, status="processing")
                await session.commit()
                
                logger.info("Starting ingestion pipeline for document %s", doc_id)
                
                # 1. Parse PDF
                with open(file_path, "rb") as f:
                    pages = parse_pdf(f.read())
                total_pages = len(pages)
                
                # 2. Chunk text
                chunks = chunk_text(pages)
                
                if not chunks:
                    logger.warning("No extractable chunks found for document %s", doc_id)
                    await repo.update_status(doc_id, status="failed", total_pages=total_pages)
                    await session.commit()
                    return
                
                # 3. Embed chunks
                embedder = Embedder(self._settings)
                chunk_texts = [c.text for c in chunks]
                embeddings = await embedder.embed_batch(chunk_texts)
                
                # 4. Upsert to Qdrant
                qdrant = QdrantStore(self._settings)
                await qdrant.upsert_document_chunks(
                    document_id=str(doc_id),
                    chunks=chunks,
                    embeddings=embeddings,
                    title=title,
                    author=author,
                )
                
                # 5. Mark as complete
                await repo.update_status(
                    doc_id, 
                    status="ingested", 
                    chunks_created=len(chunks), 
                    total_pages=total_pages
                )
                await session.commit()
                logger.info("Successfully ingested document %s", doc_id)
                break
                
        except Exception as e:
            logger.exception("Ingestion pipeline failed for document %s: %s", doc_id, e)
            if os.path.exists(file_path):
                try:
                    os.remove(file_path)
                    logger.info("Cleaned up orphaned file %s after ingestion failure", file_path)
                except OSError as cleanup_error:
                    logger.error("Failed to clean up orphaned file %s: %s", file_path, cleanup_error)
            if _database:
                async for session in _database.get_session():
                    repo = DocumentRepository(session)
                    await repo.update_status(doc_id, status="failed")
                    await session.commit()
                    break

    def _validate_file(self, content: bytes, filename: str) -> None:
        """Validate file size and type (magic bytes check)."""
        if len(content) > self._settings.max_upload_bytes:
            raise ValidationError(
                f"File exceeds {self._settings.max_upload_bytes // (1024*1024)}MB limit"
            )

        # PDF magic bytes: %PDF
        if not content[:4] == b"%PDF":
            raise ValidationError(
                "File is not a valid PDF (magic bytes check failed)"
            )

        if not filename.lower().endswith(".pdf"):
            raise ValidationError(
                "Only PDF files are accepted"
            )
