"""Document ORM model for ingested PDFs."""

import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Document(Base):
    """Represents an ingested source document (PDF)."""

    __tablename__ = "documents"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    logical_book_id: Mapped[str] = mapped_column(
        String(255), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(
        String(500), nullable=False
    )
    author: Mapped[str | None] = mapped_column(
        String(255), nullable=True
    )
    edition: Mapped[str | None] = mapped_column(
        String(255), nullable=True
    )
    file_path: Mapped[str] = mapped_column(
        String(1000), nullable=False
    )
    total_pages: Mapped[int | None] = mapped_column(
        Integer, nullable=True
    )
    chunks_created: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0
    )
    embedding_model: Mapped[str] = mapped_column(
        String(100), nullable=False, default="text-embedding-ada-002"
    )
    ingestion_status: Mapped[str] = mapped_column(
        String(50), nullable=False, default="pending", index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )
