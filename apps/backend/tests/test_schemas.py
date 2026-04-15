"""Tests for Pydantic request schema validation."""

import pytest
from pydantic import ValidationError

from app.schemas.auth_schemas import (
    LoginChallengeRequest,
    LoginVerifyRequest,
    RegisterRequest,
)
from app.schemas.chat_schemas import QueryRequest


class TestRegisterRequestValidation:
    """Tests for RegisterRequest schema validation."""

    def test_valid_register_request(self):
        """Valid registration data should parse successfully."""
        req = RegisterRequest(
            email="valid@example.com",
            client_auth_token="dGVzdC10b2tlbg==",
            salt="AAAAAAAAAAAAAAAAAAAAAA==",
            wrapped_account_key="wrapped-key",
            recovery_wrapped_ak="recovery-key",
        )
        assert req.email == "valid@example.com"

    def test_invalid_email_rejected(self):
        """Invalid email format should be rejected."""
        with pytest.raises(ValidationError) as exc_info:
            RegisterRequest(
                email="not-an-email",
                client_auth_token="token",
                salt="AAAAAAAAAAAAAAAAAAAAAA==",
                wrapped_account_key="wak",
                recovery_wrapped_ak="rwak",
            )
        assert "email" in str(exc_info.value).lower()

    def test_empty_auth_token_rejected(self):
        """Empty client_auth_token should be rejected."""
        with pytest.raises(ValidationError):
            RegisterRequest(
                email="valid@example.com",
                client_auth_token="",
                salt="AAAAAAAAAAAAAAAAAAAAAA==",
                wrapped_account_key="wak",
                recovery_wrapped_ak="rwak",
            )

    def test_short_salt_rejected(self):
        """A salt too short (< 8 bytes decoded) should be rejected."""
        import base64
        short_salt = base64.urlsafe_b64encode(b"\x00" * 4).decode()

        with pytest.raises(ValidationError):
            RegisterRequest(
                email="valid@example.com",
                client_auth_token="token",
                salt=short_salt,
                wrapped_account_key="wak",
                recovery_wrapped_ak="rwak",
            )

    def test_email_max_length_enforced(self):
        """Email exceeding 255 chars should be rejected."""
        long_email = "a" * 250 + "@b.com"

        with pytest.raises(ValidationError):
            RegisterRequest(
                email=long_email,
                client_auth_token="token",
                salt="AAAAAAAAAAAAAAAAAAAAAA==",
                wrapped_account_key="wak",
                recovery_wrapped_ak="rwak",
            )


class TestQueryRequestValidation:
    """Tests for QueryRequest schema validation."""

    def test_valid_query(self):
        """A normal query should pass validation."""
        req = QueryRequest(query="What is dharma?")
        assert req.query == "What is dharma?"
        assert req.is_guest is False

    def test_empty_query_rejected(self):
        """Empty query text should be rejected."""
        with pytest.raises(ValidationError):
            QueryRequest(query="")

    def test_query_max_length_enforced(self):
        """Query exceeding 2000 chars should be rejected."""
        with pytest.raises(ValidationError):
            QueryRequest(query="a" * 2001)

    def test_guest_mode_detected(self):
        """Setting guest_session_id should flag as guest."""
        req = QueryRequest(
            query="test",
            guest_session_id="guest-uuid-123",
        )
        assert req.is_guest is True

    def test_auth_mode_with_conversation_id(self):
        """Setting conversation_id should work for auth mode."""
        req = QueryRequest(
            query="follow up question",
            conversation_id="conv-uuid-456",
        )
        assert req.conversation_id == "conv-uuid-456"
        assert req.is_guest is False
