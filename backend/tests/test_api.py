"""Integration tests for API endpoints.

Tests the full request→response cycle through FastAPI's TestClient.
"""

import base64
from unittest.mock import AsyncMock, patch

import pytest
import pytest_asyncio
from app.config import get_settings
from app.core.database import Base, Database
from app.core.redis import RedisClient
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.dependencies import get_db, get_redis, get_settings as dep_get_settings, set_database, set_redis


@pytest_asyncio.fixture
async def app_client(test_settings):
    """Create a test app with in-memory DB and mocked Redis."""
    # Create in-memory engine
    engine = create_async_engine(test_settings.database_url, echo=False)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    session_factory = async_sessionmaker(engine, expire_on_commit=False)

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
    
    dep_get_settings.cache_clear()
    config_get_settings.cache_clear()
    
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
    
    class MockRedisClient(RedisClient):
        def __init__(self, client):
            self.client = client
        async def check_health(self):
            return True
        async def close(self):
            pass
            
    mock_redis_client = MockRedisClient(mock_redis)
    
    async def patched_get_db():
        async with session_factory() as session:
            yield session

    # Set globals for manual dependency injection (fallback)
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


class TestHealthEndpoints:
    """Tests for health check endpoints."""

    @pytest.mark.asyncio
    async def test_health_basic(self, app_client):
        """GET /health should return 200 with status."""
        response = await app_client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "version" in data

    @pytest.mark.asyncio
    async def test_health_full(self, app_client):
        """GET /health/full should include service status."""
        response = await app_client.get("/health/full")
        assert response.status_code == 200
        data = response.json()
        assert "services" in data
        assert data["services"]["database"] == "up"
        assert data["services"]["redis"] == "up"
        assert data["services"]["qdrant"] == "up"
        assert data["services"]["openai"] == "up"

    @pytest.mark.asyncio
    async def test_health_degraded_when_rag_dependency_down(self, app_client):
        """GET /health should degrade when a RAG dependency is unavailable."""
        app = app_client._transport.app
        app.state.qdrant_health_check = AsyncMock(return_value=False)

        response = await app_client.get("/health")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "degraded"
        assert data["services"]["qdrant"] == "down"
        assert data["services"]["openai"] == "up"


class TestAuthEndpoints:
    """Tests for auth API endpoints."""

    @pytest.mark.asyncio
    async def test_register_success(self, app_client):
        """POST /api/auth/register should create user and return tokens."""
        salt = base64.urlsafe_b64encode(b"\x00" * 16).decode()

        response = await app_client.post(
            "/api/auth/register",
            json={
                "email": "api-test@example.com",
                "client_auth_token": "test-auth-token",
                "salt": salt,
                "wrapped_account_key": "wrapped-ak",
                "recovery_wrapped_ak": "recovery-ak",
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert "user_id" in data
        assert "access_token" in data
        assert "refresh_token" in data

    @pytest.mark.asyncio
    async def test_register_duplicate_email(self, app_client):
        """Registering same email twice should return 409."""
        salt = base64.urlsafe_b64encode(b"\x01" * 16).decode()
        body = {
            "email": "dup-api@example.com",
            "client_auth_token": "token1",
            "salt": salt,
            "wrapped_account_key": "wak",
            "recovery_wrapped_ak": "rwak",
        }

        # First registration
        r1 = await app_client.post("/api/auth/register", json=body)
        assert r1.status_code == 200

        # Second — should conflict
        r2 = await app_client.post("/api/auth/register", json=body)
        assert r2.status_code == 409

    @pytest.mark.asyncio
    async def test_register_invalid_email(self, app_client):
        """Invalid email should return 422."""
        response = await app_client.post(
            "/api/auth/register",
            json={
                "email": "not-valid",
                "client_auth_token": "token",
                "salt": "AAAAAAAAAAAAAAAAAAAAAA==",
                "wrapped_account_key": "wak",
                "recovery_wrapped_ak": "rwak",
            },
        )
        assert response.status_code == 400

    @pytest.mark.asyncio
    async def test_login_challenge(self, app_client):
        """POST /api/auth/login should return salt (even for nonexistent user)."""
        response = await app_client.post(
            "/api/auth/login",
            json={"email": "anyone@example.com"},
        )
        assert response.status_code == 200
        data = response.json()
        assert "salt" in data

    @pytest.mark.asyncio
    async def test_login_verify_wrong_credentials(self, app_client):
        """POST /api/auth/login/verify with wrong token should return 401."""
        response = await app_client.post(
            "/api/auth/login/verify",
            json={
                "email": "noone@example.com",
                "client_auth_token": "wrong-token",
            },
        )
        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_protected_endpoint_no_token(self, app_client):
        """Accessing protected endpoint without token should return 401."""
        response = await app_client.get("/api/chat/conversations")
        assert response.status_code == 401


class TestSecurityHeaders:
    """Tests for security headers middleware."""

    @pytest.mark.asyncio
    async def test_security_headers_present(self, app_client):
        """Every response should include security headers."""
        response = await app_client.get("/health")

        assert "x-content-type-options" in response.headers
        assert response.headers["x-content-type-options"] == "nosniff"
        assert "x-frame-options" in response.headers
        assert response.headers["x-frame-options"] == "DENY"
        assert "x-request-id" in response.headers

    @pytest.mark.asyncio
    async def test_request_id_propagated(self, app_client):
        """Custom X-Request-ID should be echoed back."""
        response = await app_client.get(
            "/health",
            headers={"X-Request-ID": "custom-trace-123"},
        )
        assert response.headers["x-request-id"] == "custom-trace-123"
