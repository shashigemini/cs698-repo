"""Auth router — /api/auth/* endpoints.

Handles E2EE registration, challenge-verify login, token refresh,
logout, account deletion, password change, and account recovery.
"""

from typing import Optional
from fastapi import APIRouter, Cookie, Query, Request, Response, HTTPException

from app.dependencies import AuthSvc, CurrentUser, RateLimitSvc, ClientIP
from app.schemas.auth_schemas import (
    AuthResponse,
    ChangePasswordRequest,
    LoginChallengeRequest,
    LoginChallengeResponse,
    LoginVerifyRequest,
    LoginVerifyResponse,
    RecoverAccountRequest,
    RecoverAccountResponse,
    RefreshRequest,
    RefreshResponse,
    RegisterRequest,
)
from app.schemas.common_schemas import MessageResponse

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/register", response_model=AuthResponse)
async def register(
    body: RegisterRequest,
    request: Request,
    response: Response,
    auth_service: AuthSvc,
    rate_limiter: RateLimitSvc,
    client_ip: ClientIP,
    use_cookies: bool = Query(False, description="Return tokens in HttpOnly cookies"),
) -> AuthResponse:
    """Register a new user with E2EE key material."""
    headers = await rate_limiter.check_register(ip=client_ip)
    for k, v in headers.items():
        response.headers[k] = v

    result = await auth_service.register(
        email=body.email,
        client_auth_token=body.client_auth_token,
        salt=body.salt,
        wrapped_account_key=body.wrapped_account_key,
        recovery_wrapped_ak=body.recovery_wrapped_ak,
    )
    
    if use_cookies:
        response.set_cookie(
            "access_token", result["access_token"], httponly=True, secure=True, samesite="strict"
        )
        response.set_cookie(
            "refresh_token", result["refresh_token"], httponly=True, secure=True, samesite="strict", path="/api/auth/refresh"
        )
        
    return AuthResponse(**result)


@router.post("/login", response_model=LoginChallengeResponse)
async def login_challenge(
    body: LoginChallengeRequest,
    request: Request,
    response: Response,
    auth_service: AuthSvc,
    rate_limiter: RateLimitSvc,
    client_ip: ClientIP,
) -> LoginChallengeResponse:
    """Step 1: Get user's salt for client-side key derivation."""
    headers = await rate_limiter.check_login(ip=client_ip, email=body.email)
    for k, v in headers.items():
        response.headers[k] = v

    result = await auth_service.login_challenge(email=body.email)
    return LoginChallengeResponse(**result)


@router.post("/login/verify", response_model=LoginVerifyResponse)
async def login_verify(
    body: LoginVerifyRequest,
    request: Request,
    response: Response,
    auth_service: AuthSvc,
    rate_limiter: RateLimitSvc,
    client_ip: ClientIP,
    use_cookies: bool = Query(False, description="Return tokens in HttpOnly cookies"),
) -> LoginVerifyResponse:
    """Step 2: Verify client auth token and return JWT pair + wrapped AK."""
    headers = await rate_limiter.check_login(ip=client_ip, email=body.email)
    for k, v in headers.items():
        response.headers[k] = v

    result = await auth_service.login_verify(
        email=body.email,
        client_auth_token=body.client_auth_token,
    )
    
    # Reset limit on success
    await rate_limiter.reset_login(ip=client_ip, email=body.email)
    
    if use_cookies:
        response.set_cookie(
            "access_token", result["access_token"], httponly=True, secure=True, samesite="strict"
        )
        response.set_cookie(
            "refresh_token", result["refresh_token"], httponly=True, secure=True, samesite="strict", path="/api/auth/refresh"
        )
    
    return LoginVerifyResponse(**result)


@router.post("/refresh", response_model=RefreshResponse)
async def refresh_tokens(
    response: Response,
    auth_service: AuthSvc,
    body: Optional[RefreshRequest] = None,
    refresh_token_cookie: Optional[str] = Cookie(None, alias="refresh_token"),
    use_cookies: bool = Query(False, description="Return tokens in HttpOnly cookies"),
) -> RefreshResponse:
    """Rotate refresh token and issue new JWT pair."""
    token = body.refresh_token if body else refresh_token_cookie
    if not token:
        raise HTTPException(status_code=401, detail="Refresh token required")
        
    result = await auth_service.refresh_tokens(
        refresh_token=token,
    )
    
    if use_cookies:
        response.set_cookie(
            "access_token", result["access_token"], httponly=True, secure=True, samesite="strict"
        )
        response.set_cookie(
            "refresh_token", result["refresh_token"], httponly=True, secure=True, samesite="strict", path="/api/auth/refresh"
        )
        
    return RefreshResponse(**result)


@router.post("/logout", response_model=MessageResponse)
async def logout(
    user: CurrentUser,
    auth_service: AuthSvc,
    response: Response,
) -> MessageResponse:
    """Revoke the current refresh token."""
    await auth_service.logout(
        user_id=user["sub"],
        token_jti=user.get("jti", ""),
        token_exp=user.get("exp", 0),
    )
    response.delete_cookie("access_token")
    response.delete_cookie("refresh_token")
    return MessageResponse(message="Logged out successfully")


@router.delete("/account", response_model=MessageResponse)
async def delete_account(
    user: CurrentUser,
    auth_service: AuthSvc,
) -> MessageResponse:
    """Permanently delete user account and all data."""
    await auth_service.delete_account(user_id=user["sub"])
    return MessageResponse(message="Account and data deleted successfully")


@router.post("/change-password", response_model=MessageResponse)
async def change_password(
    body: ChangePasswordRequest,
    user: CurrentUser,
    auth_service: AuthSvc,
) -> MessageResponse:
    """Update auth credentials after client-side password change."""
    await auth_service.change_password(
        user_id=user["sub"],
        new_auth_token=body.new_auth_token,
        new_wrapped_account_key=body.new_wrapped_account_key,
    )
    return MessageResponse(message="Password changed successfully")


@router.post("/recover", response_model=RecoverAccountResponse)
async def recover_account(
    body: RecoverAccountRequest,
    auth_service: AuthSvc,
) -> RecoverAccountResponse:
    """Recover account with new credentials (after mnemonic verification)."""
    result = await auth_service.recover_account(
        email=body.email,
        new_auth_token=body.new_auth_token,
        new_wrapped_account_key=body.new_wrapped_account_key,
    )
    return RecoverAccountResponse(**result)
