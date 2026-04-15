"""Qdrant store module for writing and deleting document chunks."""

from typing import Optional
import uuid

from qdrant_client import AsyncQdrantClient
from qdrant_client.models import PointStruct, Filter, FieldCondition, MatchValue

from app.config import Settings
from app.core.exceptions import RetrievalError
from app.core.logging import get_logger
from app.rag.chunker import Chunk

logger = get_logger(__name__)

class QdrantStore:
    """Manages writing and deleting points in the Qdrant vector database."""

    def __init__(self, settings: Settings) -> None:
        self._client = AsyncQdrantClient(
            host=settings.qdrant_host,
            port=settings.qdrant_port,
        )
        self._collection = settings.qdrant_collection

    async def upsert_document_chunks(
        self,
        document_id: str,
        chunks: list[Chunk],
        embeddings: list[list[float]],
        title: str,
        author: Optional[str] = None,
    ) -> None:
        """Upsert document chunks and their embeddings into Qdrant.
        
        Args:
            document_id: The UUID string of the document.
            chunks: List of Chunk objects.
            embeddings: List of embedding vectors corresponding to chunks.
            title: Document title.
            author: Optional document author.
            
        Raises:
            RetrievalError: If Qdrant communication fails.
        """
        if len(chunks) != len(embeddings):
            raise ValueError("Number of chunks must match number of embeddings")
            
        points = []
        for i, (chunk, embedding) in enumerate(zip(chunks, embeddings)):
            # Generate a deterministic point ID for this document chunk
            point_id = str(uuid.uuid5(uuid.UUID(document_id), f"chunk_{i}"))
            
            payload = chunk.to_payload(
                document_id=document_id,
                title=title,
                author=author,
            )
            
            points.append(
                PointStruct(
                    id=point_id,
                    vector=embedding,
                    payload=payload,
                )
            )
            
        try:
            # Upsert points in batches to avoid payload limits
            batch_size = 100
            for i in range(0, len(points), batch_size):
                batch = points[i : i + batch_size]
                await self._client.upsert(
                    collection_name=self._collection,
                    points=batch,
                )
            logger.info("Upserted %d points for document %s", len(points), document_id)
        except Exception as e:
            logger.error("Failed to upsert points for document %s: %s", document_id, e)
            raise RetrievalError("Failed to store document embeddings") from e

    async def delete_document_chunks(self, document_id: str) -> None:
        """Delete all chunks associated with a document_id.
        
        Args:
            document_id: The UUID string of the document.
            
        Raises:
            RetrievalError: If Qdrant communication fails.
        """
        try:
            await self._client.delete(
                collection_name=self._collection,
                points_selector=Filter(
                    must=[
                        FieldCondition(
                            key="document_id",
                            match=MatchValue(value=document_id),
                        )
                    ]
                ),
            )
            logger.info("Deleted chunks for document %s from Qdrant", document_id)
        except Exception as e:
            logger.error("Failed to delete chunks for document %s: %s", document_id, e)
            raise RetrievalError("Failed to delete document embeddings") from e
