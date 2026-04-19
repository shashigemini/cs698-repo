import base64
import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch

import pytest

from app.core.exceptions import (
    AccountNotFoundError,
    AuthError,
    EmailExistsError,
    KeysNotFoundError,
)
from app.services.auth_service import AuthService


# Mock models
class MockUser:
    def __init__(
        self, id=None, email="test@example.com", password_hash="hash", role="user"
    ):
        self.id = id or uuid.uuid4()
        self.email = email
        self.password_hash = password_hash
        self.role = role


class MockE2EEKeys:
    def __init__(
        self,
        user_id=None,
        salt=b"salt",
        wrapped_account_key="wak",
        recovery_wrapped_ak="rwak",
    ):
        self.user_id = user_id or uuid.uuid4()
        self.salt = salt
        self.wrapped_account_key = wrapped_account_key
        self.recovery_wrapped_ak = recovery_wrapped_ak


@pytest.fixture
def mock_session():
    return AsyncMock()


@pytest.fixture
def auth_service(test_settings, mock_session):
    with (
        patch("app.services.auth_service.UserRepository") as mock_repo_class,
        patch("app.services.auth_service.TokenService") as mock_token_class,
    ):
        mock_repo = mock_repo_class.return_value
        # Ensure all async methods are AsyncMocks
        mock_repo.get_by_email = AsyncMock()
        mock_repo.get_by_id = AsyncMock()
        mock_repo.create = AsyncMock()
        mock_repo.create_e2ee_keys = AsyncMock()
        mock_repo.get_e2ee_keys = AsyncMock()
        mock_repo.update_e2ee_keys = AsyncMock()
        mock_repo.delete = AsyncMock()

        mock_token_service = mock_token_class.return_value
        mock_token_service.rotate_refresh_token = AsyncMock()
        mock_token_service.revoke_refresh_token = AsyncMock()

        service = AuthService(test_settings, mock_session)
        # Re-assign mocks to the service instance for easier access in tests
        service._user_repo = mock_repo
        service._token_service = mock_token_service

        return service


def test_auth_service_init_auth_01(test_settings, mock_session):
    """AUTH-01: Service initializes with correct dependencies."""
    service = AuthService(test_settings, mock_session)
    assert service._settings == test_settings
    assert service._session == mock_session
    assert service._user_repo is not None
    assert service._token_service is not None


@pytest.mark.asyncio
async def test_register_success_auth_02(auth_service, mock_session):
    """AUTH-02: Successful registration returns token dict."""
    email = "new@example.com"
    user = MockUser(email=email)
    auth_service._user_repo.get_by_email.return_value = None
    auth_service._user_repo.create.return_value = user
    auth_service._token_service.generate_token_pair.return_value = {
        "access_token": "at",
        "refresh_token": "rt",
        "access_expires_at": datetime.now(timezone.utc),
    }

    result = await auth_service.register(
        email=email,
        client_auth_token="token",
        salt=base64.urlsafe_b64encode(b"salt").decode(),
        wrapped_account_key="wak",
        recovery_wrapped_ak="rwak",
    )

    assert result["user_id"] == str(user.id)
    assert result["access_token"] == "at"
    mock_session.commit.assert_called_once()
    auth_service._user_repo.create_e2ee_keys.assert_called_once()


@pytest.mark.asyncio
async def test_register_duplicate_email_auth_03(auth_service):
    """AUTH-03: Duplicate email raises EmailExistsError."""
    auth_service._user_repo.get_by_email.return_value = MockUser()

    with pytest.raises(EmailExistsError):
        await auth_service.register(
            email="exists@example.com",
            client_auth_token="token",
            salt="salt",
            wrapped_account_key="wak",
            recovery_wrapped_ak="rwak",
        )


@pytest.mark.asyncio
async def test_register_standard_base64_salt_auth_04(auth_service):
    """AUTH-04: Standard base64 salt decoded via fallback."""
    auth_service._user_repo.get_by_email.return_value = None
    auth_service._user_repo.create.return_value = MockUser()
    auth_service._token_service.generate_token_pair.return_value = {
        "access_token": "at",
        "refresh_token": "rt",
        "access_expires_at": datetime.now(timezone.utc),
    }

    # Standard base64 often has '+' or '/'
    standard_salt = base64.b64encode(b"salt_with_+_and_/").decode()

    await auth_service.register(
        email="new@example.com",
        client_auth_token="token",
        salt=standard_salt,
        wrapped_account_key="wak",
        recovery_wrapped_ak="rwak",
    )

    # Verify salt_bytes was passed correctly to create_e2ee_keys
    args, kwargs = auth_service._user_repo.create_e2ee_keys.call_args
    assert kwargs["salt"] == b"salt_with_+_and_/"


@pytest.mark.asyncio
async def test_register_hashes_token_auth_05(auth_service):
    """AUTH-05: Hashes the client auth token."""
    auth_service._user_repo.get_by_email.return_value = None
    auth_service._user_repo.create.return_value = MockUser()
    auth_service._token_service.generate_token_pair.return_value = {
        "access_token": "at",
        "refresh_token": "rt",
        "access_expires_at": datetime.now(timezone.utc),
    }

    await auth_service.register(
        email="new@example.com",
        client_auth_token="secret-token",
        salt=base64.b64encode(b"salt").decode(),
        wrapped_account_key="wak",
        recovery_wrapped_ak="rwak",
    )

    args, kwargs = auth_service._user_repo.create.call_args
    assert kwargs["password_hash"].startswith("$argon2id$")
    assert kwargs["password_hash"] != "secret-token"


@pytest.mark.asyncio
async def test_register_e2ee_keys_stored_auth_06(auth_service):
    """AUTH-06: E2EE keys stored with correct parameters."""
    auth_service._user_repo.get_by_email.return_value = None
    auth_service._user_repo.create.return_value = MockUser()
    auth_service._token_service.generate_token_pair.return_value = {
        "access_token": "at",
        "refresh_token": "rt",
        "access_expires_at": datetime.now(timezone.utc),
    }

    await auth_service.register(
        email="new@example.com",
        client_auth_token="token",
        salt=base64.b64encode(b"salt").decode(),
        wrapped_account_key="my-wak",
        recovery_wrapped_ak="my-rwak",
    )

    args, kwargs = auth_service._user_repo.create_e2ee_keys.call_args
    assert kwargs["wrapped_account_key"] == "my-wak"
    assert kwargs["recovery_wrapped_ak"] == "my-rwak"


@pytest.mark.asyncio
async def test_login_challenge_existing_user_auth_07(auth_service):
    """AUTH-07: Existing user returns real salt."""
    user = MockUser()
    keys = MockE2EEKeys(salt=b"real-salt", recovery_wrapped_ak="real-rwak")
    auth_service._user_repo.get_by_email.return_value = user
    auth_service._user_repo.get_e2ee_keys.return_value = keys

    result = await auth_service.login_challenge(email="exists@example.com")

    assert result["salt"] == base64.urlsafe_b64encode(b"real-salt").decode()
    assert result["recovery_wrapped_ak"] == "real-rwak"


@pytest.mark.asyncio
async def test_login_challenge_ghost_user_auth_08(auth_service):
    """AUTH-08: Non-existent user returns fake salt (anti-enumeration)."""
    auth_service._user_repo.get_by_email.return_value = None

    result = await auth_service.login_challenge(email="ghost@example.com")

    assert "salt" in result
    assert "recovery_wrapped_ak" in result
    # Ensure it's valid base64
    base64.urlsafe_b64decode(result["salt"])


@pytest.mark.asyncio
async def test_login_challenge_fake_salt_deterministic_auth_09(auth_service):
    """AUTH-09: Fake salt is deterministic per email."""
    auth_service._user_repo.get_by_email.return_value = None

    r1 = await auth_service.login_challenge(email="ghost@example.com")
    r2 = await auth_service.login_challenge(email="ghost@example.com")

    assert r1["salt"] == r2["salt"]
    assert r1["recovery_wrapped_ak"] == r2["recovery_wrapped_ak"]


@pytest.mark.asyncio
async def test_login_challenge_keys_missing_auth_10(auth_service):
    """AUTH-10: User exists but no keys raises KeysNotFoundError."""
    auth_service._user_repo.get_by_email.return_value = MockUser()
    auth_service._user_repo.get_e2ee_keys.return_value = None

    with pytest.raises(KeysNotFoundError):
        await auth_service.login_challenge(email="nokeys@example.com")


@pytest.mark.asyncio
async def test_login_verify_success_auth_11(auth_service):
    """AUTH-11: Correct credentials return token dict + wrapped AK."""
    from app.core.security import hash_password

    pw_hash = hash_password("secret-token")
    user = MockUser(password_hash=pw_hash)
    keys = MockE2EEKeys(wrapped_account_key="my-wak")

    auth_service._user_repo.get_by_email.return_value = user
    auth_service._user_repo.get_e2ee_keys.return_value = keys
    auth_service._token_service.generate_token_pair.return_value = {
        "access_token": "at",
        "refresh_token": "rt",
        "access_expires_at": datetime.now(timezone.utc),
    }

    result = await auth_service.login_verify(
        email="user@example.com", client_auth_token="secret-token"
    )

    assert result["user_id"] == str(user.id)
    assert result["wrapped_account_key"] == "my-wak"
    assert result["access_token"] == "at"


@pytest.mark.asyncio
async def test_login_verify_ghost_user_auth_12(auth_service):
    """AUTH-12: Non-existent user raises AuthError (timing-safe)."""
    auth_service._user_repo.get_by_email.return_value = None

    with pytest.raises(AuthError):
        await auth_service.login_verify(
            email="ghost@example.com", client_auth_token="any"
        )


@pytest.mark.asyncio
async def test_login_verify_wrong_token_auth_13(auth_service):
    """AUTH-13: Wrong token raises AuthError."""
    from app.core.security import hash_password

    user = MockUser(password_hash=hash_password("real-token"))
    auth_service._user_repo.get_by_email.return_value = user

    with pytest.raises(AuthError):
        await auth_service.login_verify(
            email="user@example.com", client_auth_token="wrong-token"
        )


@pytest.mark.asyncio
async def test_login_verify_keys_missing_auth_14(auth_service):
    """AUTH-14: User exists, correct token, but no keys raises KeysNotFoundError."""
    from app.core.security import hash_password

    user = MockUser(password_hash=hash_password("token"))
    auth_service._user_repo.get_by_email.return_value = user
    auth_service._user_repo.get_e2ee_keys.return_value = None

    with pytest.raises(KeysNotFoundError):
        await auth_service.login_verify(
            email="user@example.com", client_auth_token="token"
        )


@pytest.mark.asyncio
async def test_refresh_tokens_success_auth_15(auth_service):
    """AUTH-15: Queries DB for current role, passes it to TokenService rotation."""
    import uuid
    from unittest.mock import AsyncMock

    exp = datetime.now(timezone.utc)
    user_id = str(uuid.uuid4())

    # validate_refresh_token returns payload with user_id
    auth_service._token_service.validate_refresh_token = AsyncMock(
        return_value={"sub": user_id}
    )
    # User in DB has admin role
    admin_user = MockUser(role="admin")
    auth_service._user_repo.get_by_id = AsyncMock(return_value=admin_user)
    # rotate_refresh_token returns new pair
    auth_service._token_service.rotate_refresh_token = AsyncMock(
        return_value={
            "access_token": "new-at",
            "refresh_token": "new-rt",
            "access_expires_at": exp,
        }
    )

    result = await auth_service.refresh_tokens(refresh_token="old-rt")

    assert result["access_token"] == "new-at"
    assert result["access_expires_at"] == exp
    # Must pass the DB role, not a stale value from the refresh token
    auth_service._token_service.rotate_refresh_token.assert_called_once_with(
        "old-rt", role="admin"
    )


@pytest.mark.asyncio
async def test_logout_success_auth_16(auth_service):
    """AUTH-16: Calls revoke_refresh_token on TokenService."""
    await auth_service.logout(user_id="u1", token_jti="jti", token_exp=1700000000.0)

    auth_service._token_service.revoke_refresh_token.assert_called_once()
    args, kwargs = auth_service._token_service.revoke_refresh_token.call_args
    assert kwargs["token_jti"] == "jti"
    assert kwargs["user_id"] == "u1"


@pytest.mark.asyncio
async def test_logout_timestamp_conversion_auth_17(auth_service):
    """AUTH-17: Correctly converts float timestamp to UTC datetime."""
    ts = 1700000000.0  # 2023-11-14 22:13:20 UTC

    await auth_service.logout(user_id="u1", token_jti="jti", token_exp=ts)

    args, kwargs = auth_service._token_service.revoke_refresh_token.call_args
    expected_dt = datetime.fromtimestamp(ts, tz=timezone.utc)
    assert kwargs["expires_at"] == expected_dt


@pytest.mark.asyncio
async def test_delete_account_success_auth_18(auth_service, mock_session):
    """AUTH-18: Existing user deleted -> returns True."""
    uid = str(uuid.uuid4())
    auth_service._user_repo.delete.return_value = True

    result = await auth_service.delete_account(user_id=uid)

    assert result is True
    mock_session.commit.assert_called_once()
    auth_service._user_repo.delete.assert_called_once_with(uuid.UUID(uid))


@pytest.mark.asyncio
async def test_delete_account_fail_auth_19(auth_service, mock_session):
    """AUTH-19: Non-existent user -> returns False."""
    auth_service._user_repo.delete.return_value = False

    result = await auth_service.delete_account(user_id=str(uuid.uuid4()))

    assert result is False
    mock_session.commit.assert_not_called()


@pytest.mark.asyncio
async def test_change_password_success_auth_20(auth_service, mock_session):
    """AUTH-20: Updates hash and wrapped AK in DB."""
    uid = str(uuid.uuid4())

    await auth_service.change_password(
        user_id=uid, new_auth_token="new-token", new_wrapped_account_key="new-wak"
    )

    mock_session.commit.assert_called_once()
    args, kwargs = auth_service._user_repo.update_e2ee_keys.call_args
    assert args[0] == uuid.UUID(uid)
    assert kwargs["password_hash"].startswith("$argon2id$")
    assert kwargs["wrapped_account_key"] == "new-wak"


@pytest.mark.asyncio
async def test_recover_account_success_auth_21(auth_service, mock_session):
    """AUTH-21: Existing user recovery returns tokens + wrapped AK."""
    user = MockUser()
    auth_service._user_repo.get_by_email.return_value = user
    auth_service._token_service.generate_token_pair.return_value = {
        "access_token": "at",
        "refresh_token": "rt",
        "access_expires_at": datetime.now(timezone.utc),
    }

    result = await auth_service.recover_account(
        email="user@example.com",
        new_auth_token="new-token",
        new_wrapped_account_key="new-wak",
    )

    assert result["user_id"] == str(user.id)
    assert result["wrapped_account_key"] == "new-wak"
    mock_session.commit.assert_called_once()


@pytest.mark.asyncio
async def test_recover_account_not_found_auth_22(auth_service):
    """AUTH-22: Non-existent user raises AccountNotFoundError."""
    auth_service._user_repo.get_by_email.return_value = None

    with pytest.raises(AccountNotFoundError):
        await auth_service.recover_account(
            email="ghost@example.com",
            new_auth_token="any",
            new_wrapped_account_key="any",
        )


@pytest.mark.asyncio
async def test_recover_account_hashes_token_auth_23(auth_service):
    """AUTH-23: Password is hashed before storage during recovery."""
    auth_service._user_repo.get_by_email.return_value = MockUser()
    auth_service._token_service.generate_token_pair.return_value = {
        "access_token": "at",
        "refresh_token": "rt",
        "access_expires_at": datetime.now(timezone.utc),
    }

    await auth_service.recover_account(
        email="user@example.com",
        new_auth_token="secret-new-token",
        new_wrapped_account_key="wak",
    )

    args, kwargs = auth_service._user_repo.update_e2ee_keys.call_args
    assert kwargs["password_hash"].startswith("$argon2id$")
    assert kwargs["password_hash"] != "secret-new-token"


@pytest.fixture
def auth_service_with_admin_email(test_settings, mock_session):
    """AuthService configured with boss@example.com in the admin allowlist."""
    admin_settings = test_settings.model_copy(
        update={"admin_emails": ["boss@example.com"]}
    )
    with (
        patch("app.services.auth_service.UserRepository") as mock_repo_class,
        patch("app.services.auth_service.TokenService") as mock_token_class,
    ):
        mock_repo = mock_repo_class.return_value
        mock_repo.get_by_email = AsyncMock()
        mock_repo.get_e2ee_keys = AsyncMock()
        mock_token_service = mock_token_class.return_value
        service = AuthService(admin_settings, mock_session)
        service._user_repo = mock_repo
        service._token_service = mock_token_service
        return service


@pytest.mark.asyncio
async def test_login_does_not_promote_unlisted_user(auth_service, mock_session):
    """Non-allowlisted users keep their existing role after login."""
    from app.core.security import hash_password

    pw_hash = hash_password("secret-token")
    user = MockUser(email="regular@example.com", password_hash=pw_hash, role="user")
    keys = MockE2EEKeys()
    auth_service._user_repo.get_by_email.return_value = user
    auth_service._user_repo.get_e2ee_keys.return_value = keys
    auth_service._token_service.generate_token_pair.return_value = {
        "access_token": "at",
        "refresh_token": "rt",
        "access_expires_at": datetime.now(timezone.utc),
    }

    await auth_service.login_verify(
        email="regular@example.com", client_auth_token="secret-token"
    )

    _, kwargs = auth_service._token_service.generate_token_pair.call_args
    assert kwargs["role"] == "user"
    mock_session.commit.assert_not_called()


@pytest.mark.asyncio
async def test_login_promotes_allowlisted_email_to_admin(
    auth_service_with_admin_email, mock_session
):
    """Users whose email is in ADMIN_EMAILS are promoted to admin on login."""
    from app.core.security import hash_password

    pw_hash = hash_password("secret-token")
    user = MockUser(email="boss@example.com", password_hash=pw_hash, role="user")
    keys = MockE2EEKeys()
    auth_service_with_admin_email._user_repo.get_by_email.return_value = user
    auth_service_with_admin_email._user_repo.get_e2ee_keys.return_value = keys
    auth_service_with_admin_email._token_service.generate_token_pair.return_value = {
        "access_token": "at",
        "refresh_token": "rt",
        "access_expires_at": datetime.now(timezone.utc),
    }

    await auth_service_with_admin_email.login_verify(
        email="boss@example.com", client_auth_token="secret-token"
    )

    assert user.role == "admin"
    _, kwargs = (
        auth_service_with_admin_email._token_service.generate_token_pair.call_args
    )
    assert kwargs["role"] == "admin"
    mock_session.commit.assert_called()
