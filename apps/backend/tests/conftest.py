"""Shared test fixtures and configuration.

Provides in-memory database sessions, mock Redis, and
pre-configured Settings for all tests.
"""

import asyncio
import os
import uuid
from datetime import datetime, timezone
from typing import AsyncGenerator
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
import pytest_asyncio

from app.config import Settings

# --- Mutation Testing Guard ---
MUTANT_RUN = os.environ.get("MUTANT_UNDER_TEST") is not None

# --- Basic Fixtures & Helpers (Allowed in Sandbox) ---

@pytest.fixture
def test_settings() -> Settings:
    """Provide test-safe settings (no real external services)."""
    # Generate temporary RSA keys for testing
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric import rsa

    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
    )
    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    ).decode()

    public_pem = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    ).decode()

    return Settings(
        environment="testing",
        debug=True,
        database_url=os.environ.get("DATABASE_URL", "sqlite+aiosqlite:///"),
        redis_url=os.environ.get("REDIS_URL", "redis://localhost:6379/15"),
        jwt_private_key=private_pem,
        jwt_public_key=public_pem,
        jwt_access_token_ttl_minutes=5,
        jwt_refresh_token_ttl_days=1,
        cors_origins=["http://localhost:3000"],
        openai_api_key="test-key",
        openai_model="gpt-4.1-mini",
        openai_embedding_model="text-embedding-ada-002",
        qdrant_host="localhost",
        qdrant_port=6333,
        qdrant_collection="test_docs",
        csrf_secret="test-csrf-secret-for-testing-only",
        rate_limit_login_max=5,
        rate_limit_login_window_minutes=15,
        rate_limit_register_max=3,
        rate_limit_register_window_minutes=60,
        rate_limit_guest_query_max=10,
        rate_limit_guest_query_window_hours=24,
        rate_limit_global_max=100,
        rate_limit_global_window_seconds=60,
    )

def make_user_id() -> str:
    """Generate a random user ID string."""
    return str(uuid.uuid4())

def utc_now() -> datetime:
    """Get the current UTC datetime."""
    return datetime.now(timezone.utc)

# --- Heavy Fixtures (Guarded) ---

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

import app.models  # noqa: F401 - ensure models are registered
from app.core.database import Base


@pytest_asyncio.fixture
async def db_session(test_settings: Settings) -> AsyncGenerator[AsyncSession, None]:
    """Provide a database session for isolated tests."""
    engine = create_async_engine(
        test_settings.database_url,
        echo=False,
    )

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    session_factory = async_sessionmaker(
        engine, expire_on_commit=False
    )

    async with session_factory() as session:
        yield session

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

    await engine.dispose()


@pytest.fixture
def mock_redis():
    """Provide a mock Redis client with in-memory counters."""
    store = {}

    async def mock_incr(key):
        store[key] = store.get(key, 0) + 1
        return store[key]

    async def mock_expire(key, ttl):
        pass

    async def mock_ttl(key):
        return 60

    async def mock_get(key):
        val = store.get(key)
        return str(val).encode() if val else None

    redis = AsyncMock()
    redis.incr = AsyncMock(side_effect=mock_incr)
    redis.expire = AsyncMock(side_effect=mock_expire)
    redis.ttl = AsyncMock(side_effect=mock_ttl)
    redis.get = AsyncMock(side_effect=mock_get)
    redis._store = store

    return redis
