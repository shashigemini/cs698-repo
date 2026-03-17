"""Integration tests for admin API endpoints."""

from unittest.mock import AsyncMock, patch

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.config import get_settings
from app.core.database import Base, Database
from app.core.redis import RedisClient


@pytest_asyncio.fixture
async def admin_client(test_settings):
    """App client pre-configured for admin tests."""
    engine = create_async_engine(
        test_settings.database_url, echo=False
    )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    session_factory = async_sessionmaker(
        engine, expire_on_commit=False
    )

    # Mock database
    mock_db = AsyncMock(spec=Database)
    mock_db.check_health = AsyncMock(return_value=True)

    async def mock_get_session():
        async with session_factory() as session:
            yield session

    mock_db.get_session = mock_get_session

    # Clear settings caches
    from app.dependencies import get_settings as dep_get_settings
    from app.config import get_settings as config_get_settings
    from app.dependencies import get_db, get_redis, set_database, set_redis

    dep_get_settings.cache_clear()
    config_get_settings.cache_clear()

    async def patched_get_db():
        async with session_factory() as session:
            yield session

    class MockRedis:
        def __init__(self):
            self.store = {}
        async def incr(self, key):
            val = self.store.get(key, 0) + 1
            self.store[key] = val
            return val
        async def expire(self, key, seconds):
            return True
        async def ttl(self, key):
            return 60
        async def get(self, key):
            return self.store.get(key)
        async def delete(self, key):
            self.store.pop(key, None)
        async def set(self, key, val, ex=None):
            self.store[key] = val
            return True

    mock_redis = MockRedis()
    
    class MockRedisClient:
        def __init__(self, client):
            self.client = client
        async def check_health(self):
            return True
            
    mock_redis_client = MockRedisClient(mock_redis)

    set_database(mock_db)
    set_redis(mock_redis_client)

    from app.main import create_app

    # We patch both functions to ensure direct calls also get the test settings
    with patch("app.dependencies.get_settings", return_value=test_settings), \
         patch("app.config.get_settings", return_value=test_settings):
        
        app = create_app()

        # Use dependency overrides for reliability in FastAPI
        app.dependency_overrides[dep_get_settings] = lambda: test_settings
        app.dependency_overrides[get_db] = patched_get_db
        app.dependency_overrides[get_redis] = lambda: mock_redis_client.client

        app.state.database = mock_db
        app.state.redis = mock_redis_client

        transport = ASGITransport(app=app)
        async with AsyncClient(
            transport=transport, base_url="http://test"
        ) as client:
            yield client

    # Cleanup
    app.dependency_overrides.clear()
    dep_get_settings.cache_clear()
    config_get_settings.cache_clear()

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


def _register_and_login_admin(test_settings):
    """Generate admin JWT tokens for testing."""
    from app.services.token_service import TokenService
    from app.repositories.revoked_token_repo import (
        RevokedTokenRepository,
    )
    import uuid

    # Create a token manually (admin role)
    from jose import jwt
    from datetime import datetime, timedelta, timezone

    claims = {
        "sub": str(uuid.uuid4()),
        "email": "admin@test.com",
        "role": "admin",
        "type": "access",
        "exp": datetime.now(timezone.utc) + timedelta(hours=1),
        "iat": datetime.now(timezone.utc),
        "jti": str(uuid.uuid4()),
    }
    token = jwt.encode(
        claims,
        test_settings.jwt_private_key,
        algorithm=test_settings.jwt_algorithm,
    )
    return token


def _make_user_token(test_settings):
    """Generate a non-admin user token."""
    from jose import jwt
    import uuid
    from datetime import datetime, timedelta, timezone

    claims = {
        "sub": str(uuid.uuid4()),
        "email": "user@test.com",
        "role": "user",
        "type": "access",
        "exp": datetime.now(timezone.utc) + timedelta(hours=1),
        "iat": datetime.now(timezone.utc),
        "jti": str(uuid.uuid4()),
    }
    return jwt.encode(
        claims,
        test_settings.jwt_private_key,
        algorithm=test_settings.jwt_algorithm,
    )


class TestAdminDocuments:
    """Tests for admin document endpoints."""

    @pytest.mark.asyncio
    async def test_list_documents_requires_admin(
        self, admin_client, test_settings
    ):
        """GET /api/admin/documents with user token → 403."""
        user_token = _make_user_token(test_settings)
        resp = await admin_client.get(
            "/api/admin/documents",
            headers={
                "Authorization": f"Bearer {user_token}"
            },
        )
        assert resp.status_code == 403

    @pytest.mark.asyncio
    async def test_list_documents_no_auth(
        self, admin_client
    ):
        """GET /api/admin/documents without auth → 401."""
        resp = await admin_client.get(
            "/api/admin/documents"
        )
        assert resp.status_code == 401

    @pytest.mark.asyncio
    async def test_list_documents_with_admin(
        self, admin_client, test_settings
    ):
        """GET /api/admin/documents with admin token → 200."""
        admin_token = _register_and_login_admin(
            test_settings
        )
        resp = await admin_client.get(
            "/api/admin/documents",
            headers={
                "Authorization": f"Bearer {admin_token}"
            },
        )
        assert resp.status_code == 200
        assert isinstance(resp.json(), list)
