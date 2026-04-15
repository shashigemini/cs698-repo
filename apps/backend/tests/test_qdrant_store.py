"""Tests for Qdrant storage module."""

import pytest
import uuid
from unittest.mock import AsyncMock, patch, MagicMock
from qdrant_client.models import PointStruct

from app.rag.qdrant_store import QdrantStore
from app.rag.chunker import Chunk
from app.core.exceptions import RetrievalError

@pytest.mark.asyncio
async def test_upsert_document_chunks(test_settings):
    store = QdrantStore(test_settings)
    store._client = AsyncMock()
    store._client.upsert = AsyncMock()

    doc_id = str(uuid.uuid4())
    chunks = [
        Chunk(text="First chunk", page=1, paragraph_id="p1", chunk_index=0),
        Chunk(text="Second chunk", page=1, paragraph_id="p2", chunk_index=1),
    ]
    embeddings = [
        [0.1] * 1536,
        [0.2] * 1536,
    ]
    
    await store.upsert_document_chunks(
        document_id=doc_id,
        chunks=chunks,
        embeddings=embeddings,
        title="Test Book",
        author="Author"
    )
    
    assert store._client.upsert.called
    kwargs = store._client.upsert.call_args.kwargs
    assert kwargs["collection_name"] == test_settings.qdrant_collection
    points = kwargs["points"]
    assert len(points) == 2
    assert points[0].payload["text"] == "First chunk"
    assert points[1].vector == [0.2] * 1536

@pytest.mark.asyncio
async def test_upsert_document_chunks_mismatch(test_settings):
    store = QdrantStore(test_settings)
    
    doc_id = str(uuid.uuid4())
    chunks = [Chunk(text="First chunk", page=1, paragraph_id="p1", chunk_index=0)]
    embeddings = [] # mismatch!
    
    with pytest.raises(ValueError):
        await store.upsert_document_chunks(
            document_id=doc_id,
            chunks=chunks,
            embeddings=embeddings,
            title="Test Book"
        )

@pytest.mark.asyncio
async def test_delete_document_chunks(test_settings):
    store = QdrantStore(test_settings)
    store._client = AsyncMock()
    store._client.delete = AsyncMock()

    doc_id = str(uuid.uuid4())
    
    await store.delete_document_chunks(doc_id)
    
    assert store._client.delete.called
    kwargs = store._client.delete.call_args.kwargs
    assert kwargs["collection_name"] == test_settings.qdrant_collection
    # Check that selector contains the document_id
    assert kwargs["points_selector"].must[0].match.value == doc_id
