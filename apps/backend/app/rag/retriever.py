"""Qdrant-based retriever for semantic document search."""

from typing import Optional

from qdrant_client import AsyncQdrantClient

from app.config import Settings
from app.core.exceptions import RetrievalError
from app.core.logging import get_logger

logger = get_logger(__name__)


class Retriever:
    """Queries the Qdrant vector store for relevant passages."""

    def __init__(self, settings: Settings) -> None:
        self._client = AsyncQdrantClient(
            host=settings.qdrant_host,
            port=settings.qdrant_port,
        )
        self._collection = settings.qdrant_collection
        self._top_k = settings.rag_top_k
        self._threshold = settings.rag_similarity_threshold

    async def search(
        self,
        query_vector: list[float],
        *,
        top_k: Optional[int] = None,
        threshold: Optional[float] = None,
    ) -> list[dict]:
        """Search for relevant passages.

        Args:
            query_vector: 1536-dim embedding of the user query.
            top_k: Number of results to return (default from config).
            threshold: Minimum similarity score (default from config).

        Returns:
            List of passage dicts with text, metadata, and score.
        """
        try:
            results = await self._client.search(
                collection_name=self._collection,
                query_vector=query_vector,
                limit=top_k or self._top_k,
                score_threshold=threshold or self._threshold,
            )
        except Exception as e:
            logger.error("Qdrant search failed: %s", e)
            raise RetrievalError("Document search service unavailable") from e

        passages = []
        for hit in results:
            payload = hit.payload or {}
            passages.append(
                {
                    "document_id": payload.get("document_id", ""),
                    "title": payload.get("title", "Unknown"),
                    "page": payload.get("page", 0),
                    "paragraph_id": payload.get("paragraph_id", ""),
                    "text": payload.get("text", ""),
                    "relevance_score": round(hit.score, 4),
                }
            )

        logger.info(
            "Retrieved %d passages (threshold=%.2f)",
            len(passages),
            threshold or self._threshold,
        )
        return passages

    async def check_health(self) -> bool:
        """Verify Qdrant connectivity."""
        try:
            await self._client.get_collections()
            return True
        except Exception:
            return False
