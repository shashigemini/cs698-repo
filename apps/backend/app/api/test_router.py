"""Test-only endpoints for E2E integration testing.

These endpoints allow the test runner to reset database state,
seed test data, and check service readiness. They are only active
when ENVIRONMENT=e2e_testing.
"""

import hashlib
import uuid

from fastapi import APIRouter, Depends
from sqlalchemy import text

from app.config import get_settings
from app.core.database import Base
from app.core.redis import RedisClient
from app.dependencies import DbSession, get_redis
from app.services.auth_service import AuthService
from app.dependencies import get_auth_service

router = APIRouter(prefix="/api/test", tags=["test"])


@router.get("/ready")
async def check_ready(session: DbSession, redis=Depends(get_redis)):
    """Wait for all test dependencies to be ready."""
    try:
        # Check DB
        await session.execute(text("SELECT 1"))
        # Check Redis
        await redis.ping()
        return {"status": "ready"}
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=503, detail=str(e))


@router.post("/reset")
async def reset_data(session: DbSession, redis=Depends(get_redis)):
    """Reset all application state (schema and cache)."""
    settings = get_settings()
    if settings.environment != "e2e_testing":
        from fastapi import HTTPException
        raise HTTPException(403, "Only allowed in e2e_testing")

    # 1. Truncate all tables (SQLAlchemy async trick)
    # Using raw SQL to safely wipe data but keep schema
    tables = ["chat_messages", "chat_sessions", "user_e2ee_keys", "users", "documents", "revoked_tokens"]
    for table in tables:
        await session.execute(text(f"TRUNCATE TABLE {table} CASCADE"))
    await session.commit()

    # 2. Flush Redis
    await redis.flushdb()

    # 3. Clean Qdrant
    try:
        from qdrant_client import AsyncQdrantClient
        from qdrant_client.models import Distance, VectorParams
        
        qclient = AsyncQdrantClient(host=settings.qdrant_host, port=settings.qdrant_port)
        if await qclient.collection_exists(settings.qdrant_collection):
            await qclient.delete_collection(settings.qdrant_collection)
            
        await qclient.create_collection(
            collection_name=settings.qdrant_collection,
            vectors_config=VectorParams(size=1536, distance=Distance.COSINE),
        )
    except Exception as e:
        import logging
        logging.getLogger(__name__).warning("Qdrant reset failed: %s", e)

    return {"status": "reset_complete"}


@router.post("/seed")
async def seed_data(session: DbSession, redis=Depends(get_redis)):
    """Seed test data for E2E suite."""
    settings = get_settings()
    if settings.environment != "e2e_testing":
        from fastapi import HTTPException
        raise HTTPException(403, "Only allowed in e2e_testing")

    import subprocess
    import sys
    import os
    
    script_path = os.path.join(os.path.dirname(__file__), "..", "..", "scripts", "seed_e2e_qdrant.py")
    try:
        result = subprocess.run(
            [sys.executable, script_path],
            capture_output=True,
            text=True,
            check=True
        )
        return {"status": "seeded", "output": result.stdout}
    except subprocess.CalledProcessError as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Seed failed: {e.stderr}")


@router.post("/seed-user")
async def seed_user(
    request: dict,
    auth_service: AuthService = Depends(get_auth_service)
):
    """Seed a specific test user for E2E login testing."""
    settings = get_settings()
    if settings.environment != "e2e_testing":
        from fastapi import HTTPException
        raise HTTPException(403, "Only allowed in e2e_testing")

    import os
    import base64
    from cryptography.hazmat.primitives.kdf.hkdf import HKDF
    from cryptography.hazmat.primitives import hashes
    from app.core.security import hash_password
    from app.models.user import User
    from app.models.e2ee_key import E2EEKey

    email = request.get("email", "test@example.com").lower().strip()
    password = request.get("password", "Pass123!")
    
    # 1. Generate 16-byte salt
    salt_bytes = os.urandom(16)
    salt_b64 = base64.b64encode(salt_bytes).decode("utf-8")
    
    # 2. Replicate Dart's _FakeCryptographyService LMK derivation
    # _FakeCryptographyService uses Hkdf(hmac: Hmac.sha256(), outputLength: 32)
    # with secretKey=password, info=salt_bytes (expand step)
    # Note: Dart package's Hkdf without defined salt in constructor uses zero salt (extract step)
    hkdf_lmk = HKDF(
        algorithm=hashes.SHA256(),
        length=32,
        salt=b"\x00" * 32, # SHA256 hash length in bytes? Actually it depends on the lib.
        info=salt_bytes,
    )
    lmk = hkdf_lmk.derive(password.encode("utf-8"))
    
    # 3. Replicate Dart's CryptographyService.deriveAuthToken
    # Uses Hkdf(hmac: Hmac.sha256(), outputLength: 32) with secretKey=lmk, info='auth_token_derivation'
    hkdf_auth = HKDF(
        algorithm=hashes.SHA256(),
        length=32,
        salt=b"\x00" * 32,
        info=b"auth_token_derivation",
    )
    auth_token_bytes = hkdf_auth.derive(lmk)
    auth_token = base64.urlsafe_b64encode(auth_token_bytes).decode("utf-8")
    
    # 4. Hash the auth token as the backend normally would
    pw_hash = hash_password(auth_token)

    user = User(
        email=email,
        password_hash=pw_hash,
        role="user",
    )
    auth_service._session.add(user)
    await auth_service._session.flush()

    # Dummy wrapped keys since E2E login doesn't unwrap these for the test unless strictly checked
    wrapped_ak = "dGVzdA==" # "test"
    wrapped_recovery_ak = "cmVjb3Zlcnk=" # "recovery"
    
    e2ee_key = E2EEKey(
        user_id=user.id,
        salt=salt_bytes,
        wrapped_account_key=wrapped_ak,
        recovery_wrapped_ak=wrapped_recovery_ak,
    )
    auth_service._session.add(e2ee_key)
    await auth_service._session.commit()

    return {"status": "user_seeded", "email": email}
