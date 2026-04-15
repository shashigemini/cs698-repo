import pytest
import re
from datetime import datetime, timezone
from jose import jwt
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    generate_csrf_token,
)
from app.core.exceptions import TokenError

def test_hash_password_format_sec_01():
    """SEC-01: Returns Argon2id-format string."""
    pw = "MyP@ssw0rd!"
    hashed = hash_password(pw)
    assert hashed.startswith("$argon2id$")

def test_hash_password_uniqueness_sec_02():
    """SEC-02: Different calls produce different hashes (unique salts)."""
    pw = "same-password"
    h1 = hash_password(pw)
    h2 = hash_password(pw)
    assert h1 != h2

def test_hash_password_empty_sec_03():
    """SEC-03: Handles empty string input."""
    hashed = hash_password("")
    assert hashed.startswith("$argon2id$")
    assert verify_password("", hashed) is True

def test_hash_password_long_sec_04():
    """SEC-04: Handles long input (1000 chars)."""
    pw = "A" * 1000
    hashed = hash_password(pw)
    assert hashed.startswith("$argon2id$")
    assert verify_password(pw, hashed) is True

def test_hash_password_special_chars_sec_05():
    """SEC-05: Handles special characters."""
    pw = "pÄ$$wörd!@#☺"
    hashed = hash_password(pw)
    assert hashed.startswith("$argon2id$")
    assert verify_password(pw, hashed) is True

def test_verify_password_success_sec_06():
    """SEC-06: Correct password verifies successfully."""
    pw = "pw"
    hashed = hash_password(pw)
    assert verify_password(pw, hashed) is True

def test_verify_password_fail_sec_07():
    """SEC-07: Wrong password fails verification."""
    hashed = hash_password("pw")
    assert verify_password("wrong", hashed) is False

def test_verify_password_empty_sec_08():
    """SEC-08: Empty password correctly fails."""
    hashed = hash_password("hello")
    assert verify_password("", hashed) is False

def test_verify_password_case_sensitive_sec_09():
    """SEC-09: Verification is case-sensitive."""
    hashed = hash_password("Password")
    assert verify_password("password", hashed) is False

def test_create_access_token_claims_sec_10(test_settings):
    """SEC-10: Payload contains required claims."""
    user_id = "u1"
    role = "user"
    token, expires_at = create_access_token(test_settings, user_id=user_id, role=role)
    
    payload = jwt.decode(token, test_settings.jwt_public_key, algorithms=[test_settings.jwt_algorithm])
    assert payload["sub"] == user_id
    assert payload["role"] == role
    assert payload["type"] == "access"
    assert "jti" in payload
    assert "iat" in payload
    assert "exp" in payload

def test_create_access_token_default_role_sec_11(test_settings):
    """SEC-11: Default role is 'user'."""
    token, _ = create_access_token(test_settings, user_id="u1")
    payload = jwt.decode(token, test_settings.jwt_public_key, algorithms=[test_settings.jwt_algorithm])
    assert payload["role"] == "user"

def test_create_access_token_extra_claims_sec_12(test_settings):
    """SEC-12: Extra claims are merged into payload."""
    extra = {"custom": "val", "scope": "read"}
    token, _ = create_access_token(test_settings, user_id="u1", extra_claims=extra)
    payload = jwt.decode(token, test_settings.jwt_public_key, algorithms=[test_settings.jwt_algorithm])
    assert payload["custom"] == "val"
    assert payload["scope"] == "read"

def test_create_access_token_override_role_sec_13(test_settings):
    """SEC-13: Extra claims can override role."""
    token, _ = create_access_token(test_settings, user_id="u1", role="user", extra_claims={"role": "admin"})
    payload = jwt.decode(token, test_settings.jwt_public_key, algorithms=[test_settings.jwt_algorithm])
    assert payload["role"] == "admin"

def test_create_access_token_expiry_sec_14(test_settings):
    """SEC-14: Returns valid datetime for expiry."""
    _, expires_at = create_access_token(test_settings, user_id="u1")
    assert isinstance(expires_at, datetime)
    assert expires_at > datetime.now(timezone.utc)

def test_create_access_token_unique_jti_sec_15(test_settings):
    """SEC-15: Each call produces unique JTI."""
    token1, _ = create_access_token(test_settings, user_id="u1")
    token2, _ = create_access_token(test_settings, user_id="u1")
    p1 = jwt.decode(token1, test_settings.jwt_public_key, algorithms=[test_settings.jwt_algorithm])
    p2 = jwt.decode(token2, test_settings.jwt_public_key, algorithms=[test_settings.jwt_algorithm])
    assert p1["jti"] != p2["jti"]

def test_create_refresh_token_claims_sec_16(test_settings):
    """SEC-16: Payload contains required claims."""
    user_id = "u1"
    token, expires_at, jti = create_refresh_token(test_settings, user_id=user_id)
    
    payload = jwt.decode(token, test_settings.jwt_public_key, algorithms=[test_settings.jwt_algorithm])
    assert payload["sub"] == user_id
    assert payload["type"] == "refresh"
    assert payload["jti"] == jti

def test_create_refresh_token_tuple_sec_17(test_settings):
    """SEC-17: Returns (token, expires_at, jti) tuple."""
    result = create_refresh_token(test_settings, user_id="u1")
    assert len(result) == 3
    assert isinstance(result[0], str)
    assert isinstance(result[1], datetime)
    assert isinstance(result[2], str)

def test_create_refresh_token_jti_match_sec_18(test_settings):
    """SEC-18: JTI in decoded payload matches returned JTI."""
    token, _, returned_jti = create_refresh_token(test_settings, user_id="u1")
    payload = jwt.decode(token, test_settings.jwt_public_key, algorithms=[test_settings.jwt_algorithm])
    assert payload["jti"] == returned_jti

def test_decode_token_access_sec_19(test_settings):
    """SEC-19: Valid access token decodes correctly."""
    token, _ = create_access_token(test_settings, user_id="u1")
    payload = decode_token(test_settings, token, expected_type="access")
    assert payload["sub"] == "u1"
    assert payload["type"] == "access"

def test_decode_token_refresh_sec_20(test_settings):
    """SEC-20: Valid refresh token decodes correctly."""
    token, _, _ = create_refresh_token(test_settings, user_id="u1")
    payload = decode_token(test_settings, token, expected_type="refresh")
    assert payload["sub"] == "u1"
    assert payload["type"] == "refresh"

def test_decode_token_invalid_jwt_sec_21(test_settings):
    """SEC-21: Invalid token raises TokenError."""
    with pytest.raises(TokenError) as exc:
        decode_token(test_settings, "not-a-jwt")
    assert "Invalid token" in str(exc.value)

def test_decode_token_type_mismatch_sec_22(test_settings):
    """SEC-22: Type mismatch raises TokenError."""
    token, _ = create_access_token(test_settings, user_id="u1")
    with pytest.raises(TokenError) as exc:
        decode_token(test_settings, token, expected_type="refresh")
    assert "Expected refresh token, got access" in str(exc.value)

def test_decode_token_logging_invalid_sec_23(test_settings, caplog):
    """SEC-23: Logs error on invalid JWT."""
    with pytest.raises(TokenError):
        decode_token(test_settings, "garbage")
    assert "JWT Validation Error" in caplog.text

def test_decode_token_logging_mismatch_sec_24(test_settings, caplog):
    """SEC-24: Logs error on type mismatch."""
    token, _ = create_access_token(test_settings, user_id="u1")
    with pytest.raises(TokenError):
        decode_token(test_settings, token, expected_type="refresh")
    assert "Token type mismatch" in caplog.text

def test_generate_csrf_token_length_sec_25():
    """SEC-25: Returns ~43 character URL-safe string."""
    token = generate_csrf_token()
    # secrets.token_urlsafe(32) produces 32 bytes, which is 42.66 characters in base64
    assert len(token) >= 42
    assert len(token) <= 44

def test_generate_csrf_token_unique_sec_26():
    """SEC-26: Two tokens are unique."""
    t1 = generate_csrf_token()
    t2 = generate_csrf_token()
    assert t1 != t2

def test_generate_csrf_token_chars_sec_27():
    """SEC-27: Token contains only URL-safe characters."""
    token = generate_csrf_token()
    assert re.match(r"^[A-Za-z0-9_-]+$", token)
