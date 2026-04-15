"""Chat Pydantic schemas — request and response models."""

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


# --- Query ---


class QueryRequest(BaseModel):
    """Chat query request. Supports guest and authenticated modes."""

    query: str = Field(min_length=1, max_length=2000)
    conversation_id: Optional[str] = Field(
        default=None,
        description="UUID of existing conversation (auth users)",
    )
    guest_session_id: Optional[str] = Field(
        default=None,
        description="UUID for guest rate-limit tracking",
    )

    @property
    def is_guest(self) -> bool:
        """Whether this is a guest query."""
        return self.guest_session_id is not None


class CitationResponse(BaseModel):
    """Citation referencing a source document passage."""

    document_id: Optional[str] = None
    title: Optional[str] = None
    page: Optional[int] = None
    paragraph_id: Optional[str] = None
    relevance_score: Optional[float] = None
    passage_text: Optional[str] = None


class QueryMetadata(BaseModel):
    """Performance/diagnostic metadata from the RAG pipeline."""

    retrieval_time_ms: Optional[float] = None
    llm_time_ms: Optional[float] = None
    total_chunks_retrieved: Optional[int] = None


class QueryResponse(BaseModel):
    """Chat query response with answer, citations, and metadata."""

    answer: str
    conversation_id: Optional[str] = None
    citations: list[CitationResponse] = Field(default_factory=list)
    metadata: Optional[QueryMetadata] = None
    guest_queries_remaining: Optional[int] = None


# --- Conversations ---


class ConversationSummary(BaseModel):
    """Lightweight conversation metadata for listing."""

    id: str
    title: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    message_count: int = 0
    last_message_preview: Optional[str] = None


class MessageResponse(BaseModel):
    """A single message in a conversation."""

    id: str
    sender: str
    content: str
    citations: list[CitationResponse] = Field(default_factory=list)
    timestamp: datetime


class ExportResponse(BaseModel):
    """Exported conversation data."""

    export_data: str
