"""Tests for remaining uncovered service methods and background tasks."""

import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime, timedelta, timezone
import uuid
import base64

from app.services.token_cleanup import TokenCleanupTask
from app.services.auth_service import AuthService
from app.services.token_service import TokenService
from app.services.document_service import DocumentService
from app.repositories.revoked_token_repo import RevokedTokenRepository
from app.repositories.user_repo import UserRepository
from app.repositories.document_repo import DocumentRepository
from app.core.exceptions import RefreshTokenError, AuthError, ValidationError, AccountNotFoundError

class TestTokenCleanupTask:
    @pytest.mark.asyncio
    async def test_token_cleanup_run(self, test_settings):
        with patch("app.dependencies._database") as mock_db:
            mock_session = AsyncMock()
            mock_session.commit = AsyncMock()
            
            async def mock_get_session():
                yield mock_session
            
            mock_db.get_session = mock_get_session
            
            with patch.object(RevokedTokenRepository, "cleanup_expired", new_callable=AsyncMock) as mock_cleanup:
                mock_cleanup.return_value = 5
                
                cleanup_task = TokenCleanupTask(interval_hours=1)
                await cleanup_task._cleanup()
                
                assert mock_cleanup.called
                assert mock_session.commit.called

    @pytest.mark.asyncio
    async def test_start_stop(self):
        cleanup_task = TokenCleanupTask(interval_hours=24)
        with patch.object(cleanup_task, "_run_loop", new_callable=AsyncMock) as mock_loop:
            cleanup_task.start()
            assert cleanup_task._task is not None
            await cleanup_task.stop()
            assert cleanup_task._task is None

class TestAuthServiceAdditional:
    @pytest.mark.asyncio
    async def test_logout(self, test_settings):
        mock_session = AsyncMock()
        auth = AuthService(test_settings, mock_session)
        auth._token_service = AsyncMock()
        user_id = str(uuid.uuid4())
        await auth.logout(user_id=user_id, token_jti="test-jti", token_exp=int(datetime.now().timestamp()) + 3600)
        assert auth._token_service.revoke_refresh_token.called

    @pytest.mark.asyncio
    async def test_refresh_tokens_failure(self, test_settings):
        mock_session = AsyncMock()
        auth = AuthService(test_settings, mock_session)
        auth._token_service = MagicMock()
        auth._token_service.rotate_refresh_token = AsyncMock(side_effect=RefreshTokenError("Invalid"))
        with pytest.raises(RefreshTokenError):
            await auth.refresh_tokens(refresh_token="bad-token")

    @pytest.mark.asyncio
    async def test_register_service(self, test_settings):
        mock_session = AsyncMock()
        auth = AuthService(test_settings, mock_session)
        auth._user_repo = AsyncMock()
        auth._user_repo.get_by_email = AsyncMock(return_value=None)
        
        user = MagicMock()
        user.id = uuid.uuid4()
        user.role = "user"
        user.email = "new@test.com"
        auth._user_repo.create = AsyncMock(return_value=user)
        
        auth._token_service = MagicMock()
        auth._token_service.generate_token_pair = MagicMock(return_value={
            "access_token": "a", 
            "refresh_token": "r", 
            "access_expires_at": 123,
            "_refresh_jti": "jti",
            "_refresh_expires_at": 456
        })
        
        res = await auth.register(
            email="new@test.com", client_auth_token="token", salt="salt",
            wrapped_account_key="wak", recovery_wrapped_ak="rwak"
        )
        assert "user_id" in res

    @pytest.mark.asyncio
    async def test_login_service(self, test_settings):
        mock_session = AsyncMock()
        auth = AuthService(test_settings, mock_session)
        auth._user_repo = AsyncMock()
        user = MagicMock()
        user.id = uuid.uuid4()
        auth._user_repo.get_by_email = AsyncMock(return_value=user)
        
        keys = MagicMock()
        keys.salt = b"salt-bytes-16xx"
        auth._user_repo.get_e2ee_keys = AsyncMock(return_value=keys)
        
        res = await auth.login_challenge(email="user@test.com")
        assert "salt" in res

    @pytest.mark.asyncio
    async def test_recover_account_success(self, test_settings):
        mock_session = AsyncMock()
        auth = AuthService(test_settings, mock_session)
        auth._user_repo = AsyncMock()
        user = MagicMock()
        user.id = uuid.uuid4()
        user.role = "user"
        auth._user_repo.get_by_email = AsyncMock(return_value=user)
        
        auth._token_service = MagicMock()
        auth._token_service.generate_token_pair = MagicMock(return_value={
            "access_token": "a", 
            "refresh_token": "r",
            "access_expires_at": 123
        })
        
        await auth.recover_account(email="user@test.com", new_auth_token="new", new_wrapped_account_key="wak")
        assert auth._user_repo.update_e2ee_keys.called
        assert mock_session.commit.called

    @pytest.mark.asyncio
    async def test_delete_account(self, test_settings):
        mock_session = AsyncMock()
        auth = AuthService(test_settings, mock_session)
        auth._user_repo = AsyncMock()
        user = MagicMock()
        user.id = uuid.uuid4()
        auth._user_repo.get_by_id = AsyncMock(return_value=user)
        auth._user_repo.delete = AsyncMock(return_value=True)
        await auth.delete_account(user_id=str(uuid.uuid4()))
        assert auth._user_repo.delete.called
        assert mock_session.commit.called

    @pytest.mark.asyncio
    async def test_refresh_tokens_success(self, test_settings):
        mock_session = AsyncMock()
        auth = AuthService(test_settings, mock_session)
        auth._token_service = AsyncMock()
        auth._token_service.rotate_refresh_token = AsyncMock(return_value={
            "access_token": "a", "refresh_token": "r", "access_expires_at": 123
        })
        res = await auth.refresh_tokens(refresh_token="valid")
        assert res["access_token"] == "a"

class TestDocumentServiceAdditional:
    @pytest.mark.asyncio
    async def test_validate_file_size(self, test_settings):
        svc = DocumentService(test_settings, AsyncMock())
        with pytest.raises(ValidationError, match="limit"):
            svc._validate_file(b"a" * (test_settings.max_upload_bytes + 1), "test.pdf")

    @pytest.mark.asyncio
    async def test_validate_file_type(self, test_settings):
        svc = DocumentService(test_settings, AsyncMock())
        with pytest.raises(ValidationError, match="not a valid PDF"):
            svc._validate_file(b"not-pdf", "test.pdf")
        with pytest.raises(ValidationError, match="Only PDF"):
            svc._validate_file(b"%PDF-1.4", "test.txt")

    @pytest.mark.asyncio
    async def test_ingest_mock_pipeline(self, test_settings):
        mock_session = AsyncMock()
        svc = DocumentService(test_settings, mock_session)
        svc._doc_repo = MagicMock()
        svc._doc_repo.create = AsyncMock(return_value=MagicMock(id=uuid.uuid4()))
        svc._doc_repo.update_status = AsyncMock()
        svc._doc_repo._session = mock_session
        
        mock_background_tasks = MagicMock()
        await svc.ingest(
            file_content=b"%PDF-1.4 test", filename="test.pdf",
            title="Test Title", logical_book_id="book-123",
            background_tasks=mock_background_tasks
        )
        assert svc._doc_repo.create.called
        assert mock_session.commit.called

    @pytest.mark.asyncio
    async def test_full_process_document_pipeline_success(self, test_settings):
        # Mock dependencies
        mock_session = AsyncMock()
        mock_session.commit = AsyncMock()
        
        async def mock_get_session():
            yield mock_session
            
        with patch("app.dependencies._database") as mock_db, \
             patch("app.rag.pdf_parser.parse_pdf") as mock_parse, \
             patch("app.rag.chunker.chunk_text") as mock_chunk, \
             patch("app.rag.embedder.Embedder") as mock_embedder_class, \
             patch("app.rag.qdrant_store.QdrantStore") as mock_qdrant_class, \
             patch("builtins.open", MagicMock()), \
             patch("os.path.exists", return_value=True):
            
            mock_db.get_session = mock_get_session
            mock_parse.return_value = ["Page 1 text"]
            mock_chunk.return_value = [MagicMock(text="chunk 1")]
            
            mock_embedder = mock_embedder_class.return_value
            mock_embedder.embed_batch = AsyncMock(return_value=[[0.1] * 1536])
            
            mock_qdrant = mock_qdrant_class.return_value
            mock_qdrant.upsert_document_chunks = AsyncMock()
            
            svc = DocumentService(test_settings, AsyncMock())
            
            with patch.object(DocumentRepository, "update_status", new_callable=AsyncMock) as mock_update:
                await svc._process_document_pipeline(
                    doc_id=uuid.uuid4(),
                    file_path="/tmp/test.pdf",
                    title="Test Doc"
                )
                
                assert mock_update.called
                assert mock_parse.called
                assert mock_chunk.called
                assert mock_embedder.embed_batch.called
                assert mock_qdrant.upsert_document_chunks.called
                assert mock_session.commit.called

class TestTokenServiceAdditional:
    @pytest.mark.asyncio
    async def test_validate_refresh_token_revoked(self, test_settings):
        mock_session = AsyncMock()
        svc = TokenService(test_settings, mock_session)
        with patch("app.services.token_service.decode_token") as mock_decode:
            mock_decode.return_value = {"jti": "revoked-jti", "sub": "user1", "exp": 1234567890}
            svc._revoked_repo = AsyncMock()
            svc._revoked_repo.is_revoked = AsyncMock(return_value=True)
            with pytest.raises(RefreshTokenError, match="revoked"):
                await svc.validate_refresh_token("some-token")
