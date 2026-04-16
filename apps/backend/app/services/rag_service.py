"""RAG service — orchestrates the full query pipeline.

Retrieves relevant passages from Qdrant, generates an answer
via OpenAI, persists messages, and returns citations.
"""

import time
import uuid
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession

from app.config import Settings
from app.core.exceptions import ValidationError
from app.core.logging import get_logger
from app.rag.embedder import Embedder
from app.rag.llm_client import LLMClient
from app.rag.retriever import Retriever
from app.repositories.session_repo import MessageRepository, SessionRepository
from app.schemas.chat_schemas import (
    CitationResponse,
    QueryMetadata,
    QueryResponse,
)

logger = get_logger(__name__)


class RAGService:
    """Full RAG pipeline: validate → embed → retrieve → generate → persist."""

    def __init__(
        self,
        settings: Settings,
        session: AsyncSession,
    ) -> None:
        self._settings = settings
        self._session = session
        self._embedder = Embedder(settings)
        self._retriever = Retriever(settings)
        self._llm = LLMClient(settings)
        self._session_repo = SessionRepository(session)
        self._message_repo = MessageRepository(session)

    async def query(
        self,
        *,
        query_text: str,
        user_id: Optional[str] = None,
        conversation_id: Optional[str] = None,
    ) -> QueryResponse:
        """Process a user query through the full RAG pipeline.

        Args:
            query_text: The user's question (already validated for length).
            user_id: Authenticated user's ID, or None for guest.
            conversation_id: Existing conversation to continue, or None.

        Returns:
            QueryResponse with answer, citations, and metadata.
        """
        # --- Validate ---
        query_text = query_text.strip()
        if len(query_text) < 3:
            raise ValidationError(
                "Query too short",
                error_code="QUERY_TOO_SHORT",
            )
        if len(query_text) > self._settings.max_query_length:
            raise ValidationError(
                "Query too long",
                error_code="QUERY_TOO_LONG",
            )

        # --- Load conversation history (for authenticated users) ---
        history: list[dict] = []
        session_obj = None

        if user_id and conversation_id:
            try:
                recent = await self._message_repo.get_recent_pairs(
                    uuid.UUID(conversation_id),
                    limit=self._settings.rag_max_history_pairs,
                )
                history = [
                    {"sender": m.sender, "content": m.content}
                    for m in recent
                ]
            except Exception:
                logger.warning(
                    "Failed to load history for conversation"
                )

        # --- Embed query ---
        t_start = time.monotonic()
        query_vector = await self._embedder.embed_text(query_text)
        t_embed = time.monotonic()

        # --- Retrieve ---
        passages = await self._retriever.search(query_vector)
        t_retrieve = time.monotonic()

        # --- Generate answer ---
        answer = await self._llm.generate_answer(
            query=query_text,
            passages=passages,
            history=history,
        )
        t_generate = time.monotonic()

        # --- Citations ---
        citations = [
            CitationResponse(
                document_id=p["document_id"],
                title=p["title"],
                page=p["page"],
                paragraph_id=p["paragraph_id"],
                relevance_score=p.get("relevance_score"),
                passage_text=p.get("text"),
            )
            for p in passages
        ]

        # --- Persist for authenticated users ---
        result_conversation_id = conversation_id

        if user_id:
            if not conversation_id:
                # Create new conversation
                title = query_text[:100] + (
                    "..." if len(query_text) > 100 else ""
                )
                session_obj = await self._session_repo.create(
                    user_id=uuid.UUID(user_id),
                    title=title,
                )
                result_conversation_id = str(session_obj.id)

            session_uuid = uuid.UUID(result_conversation_id)

            # Save user message
            await self._message_repo.create(
                session_id=session_uuid,
                sender="user",
                content=query_text,
            )

            # Save assistant message with citation metadata
            await self._message_repo.create(
                session_id=session_uuid,
                sender="assistant",
                content=answer,
                rag_metadata={
                    "citations": [c.model_dump() for c in citations],
                },
            )
            await self._session.commit()

        # --- Metadata ---
        retrieval_ms = (t_retrieve - t_embed) * 1000
        llm_ms = (t_generate - t_retrieve) * 1000

        metadata = QueryMetadata(
            retrieval_time_ms=round(retrieval_ms, 1),
            llm_time_ms=round(llm_ms, 1),
            total_chunks_retrieved=len(passages),
        )

        logger.info(
            "RAG query completed (retrieval=%.0fms, llm=%.0fms, chunks=%d)",
            retrieval_ms, llm_ms, len(passages),
        )

        return QueryResponse(
            answer=answer,
            conversation_id=result_conversation_id,
            citations=citations,
            metadata=metadata,
        )
