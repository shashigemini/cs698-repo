#!/usr/bin/env python
"""Seed Qdrant with test records for E2E testing.

This script drops the `e2e_test_docs` collection (if it exists) to ensure
a clean state, recreates it, chunks a dummy text, and upserts it using
a fixed embedding vector so that the StubEmbedder will match it.

It also inserts a corresponding dummy Document into the database.
"""

import asyncio
import os
import sys

# Ensure backend root is in PYTHONPATH
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker

from app.config import get_settings
from app.rag.chunker import chunk_text
from app.rag.qdrant_store import QdrantStore
from app.models.document import Document

# Dummy text with spiritual/philosophical content
TEST_TEXT = """
Introduction to Inner Peace
Seeking inner peace requires a mindful approach to daily life. Often, the mind is cluttered with anxieties about the past and future. True tranquility is found in the present moment, observing thoughts without judgment.

The Role of Meditation
Meditation is a core practice for cultivating presence. By focusing on the breath or a simple mantra, one can slowly quiet the internal dialogue. This practice is not about stopping thoughts, but rather changing one's relationship to them.

Compassion and Connection
Inner peace naturally radiates outward as compassion. Recognizing the shared humanity in others helps dissolve the ego's boundaries. Acts of kindness are both a result of and a pathway to spiritual fulfillment.
"""

async def seed():
    settings = get_settings()
    if settings.environment != "e2e_testing":
        print(f"Error: Refusing to seed outside e2e_testing (current: {settings.environment})")
        sys.exit(1)

    print("--- Starting E2E Data Seed ---")

    # 1. Clean Qdrant
    from qdrant_client import AsyncQdrantClient
    from qdrant_client.models import Distance, VectorParams
    
    print(f"Connecting to Qdrant at {settings.qdrant_host}:{settings.qdrant_port}")
    qclient = AsyncQdrantClient(host=settings.qdrant_host, port=settings.qdrant_port)
    
    collection_name = settings.qdrant_collection
    if await qclient.collection_exists(collection_name):
        print(f"Dropping existing Qdrant collection: {collection_name}")
        await qclient.delete_collection(collection_name)
    
    print(f"Creating Qdrant collection: {collection_name}")
    await qclient.create_collection(
        collection_name=collection_name,
        vectors_config=VectorParams(size=1536, distance=Distance.COSINE)
    )

    # 2. Chunk text and upsert
    print("Chunking test document...")
    pages = [{"page": 1, "text": TEST_TEXT}]
    # Using low target tokens to force multiple chunks for testing
    chunks = chunk_text(pages, target_tokens=20, overlap_tokens=5)
    print(f"Generated {len(chunks)} chunks.")

    doc_id = "00000000-0000-0000-0000-000000000001"
    embeddings = [[0.1] * 1536 for _ in chunks]  # Matches StubEmbedder

    store = QdrantStore(settings)
    print(f"Upserting chunks into Qdrant ({len(embeddings)} vectors)...")
    await store.upsert_document_chunks(
        document_id=doc_id,
        chunks=chunks,
        embeddings=embeddings,
        title="Inner Peace E2E test",
        author="E2E Test Engine"
    )

    # 3. Insert PostgreSQL Document record
    print(f"Connecting to database: {settings.database_url}")
    engine = create_async_engine(settings.database_url)
    SessionLocal = async_sessionmaker(bind=engine, expire_on_commit=False)
    
    async with SessionLocal() as session:
        # Check if exists first
        from sqlalchemy import select
        result = await session.scalars(select(Document).where(Document.id == doc_id))
        doc = result.first()
        
        if not doc:
            print("Inserting DB Document record...")
            test_doc = Document(
                id=doc_id,
                logical_book_id="e2e_inner_peace",
                title="Inner Peace E2E test",
                author="E2E Test Engine",
                file_path="e2e-test-docs/inner-peace.pdf",
                total_pages=1,
                chunks_created=len(chunks),
                ingestion_status="processed"
            )
            session.add(test_doc)
            await session.commit()
        else:
            print("DB Document record already exists.")
            
    await engine.dispose()
    print("--- E2E Data Seed Complete ---")

if __name__ == "__main__":
    asyncio.run(seed())
