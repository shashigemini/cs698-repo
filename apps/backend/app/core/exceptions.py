"""Application exception hierarchy.

Every domain exception maps to a specific HTTP status code via
the error handlers. This keeps business logic free from HTTP concerns.
"""

from typing import Any, Optional


class AppError(Exception):
    """Base exception for all application errors."""

    error_code: str = "INTERNAL_ERROR"
    status_code: int = 500
    message: str = "An unexpected error occurred."

    def __init__(
        self,
        message: Optional[str] = None,
        *,
        error_code: Optional[str] = None,
        details: Optional[dict[str, Any]] = None,
    ) -> None:
        self.message = message or self.__class__.message
        if error_code:
            self.error_code = error_code
        self.details = details
        super().__init__(self.message)


class AuthError(AppError):
    """Authentication failure (invalid credentials, expired token)."""

    error_code = "INVALID_CREDENTIALS"
    status_code = 401
    message = "Email or password is incorrect."


class TokenError(AppError):
    """Token-specific errors (expired, revoked, malformed)."""

    error_code = "UNAUTHORIZED"
    status_code = 401
    message = "Invalid or expired access token."


class RefreshTokenError(AppError):
    """Invalid or expired refresh token."""

    error_code = "INVALID_REFRESH_TOKEN"
    status_code = 401
    message = "Refresh token is invalid or expired."


class ValidationError(AppError):
    """Input validation failure."""

    error_code = "VALIDATION_ERROR"
    status_code = 400
    message = "Invalid input format."


class EmailExistsError(AppError):
    """Registration conflict — email already taken."""

    error_code = "EMAIL_ALREADY_EXISTS"
    status_code = 409
    message = "An account with this email already exists."


class AccountNotFoundError(AppError):
    """Account lookup failure (for recovery, etc.)."""

    error_code = "ACCOUNT_NOT_FOUND"
    status_code = 404
    message = "Account not found."


class RateLimitError(AppError):
    """Rate limit exceeded."""

    error_code = "RATE_LIMIT_EXCEEDED"
    status_code = 429
    message = "Rate limit exceeded. Please try again later."


class NotFoundError(AppError):
    """Resource not found."""

    error_code = "CONVERSATION_NOT_FOUND"
    status_code = 404
    message = "Resource not found."


class ForbiddenError(AppError):
    """Insufficient permissions."""

    error_code = "FORBIDDEN"
    status_code = 403
    message = "You do not have permission to access this resource."


class LLMError(AppError):
    """OpenAI API failure."""

    error_code = "LLM_ERROR"
    status_code = 503
    message = "AI service is temporarily unavailable."


class RetrievalError(AppError):
    """Vector DB query failure."""

    error_code = "RETRIEVAL_ERROR"
    status_code = 503
    message = "Document retrieval service is temporarily unavailable."


class KeysNotFoundError(AppError):
    """E2EE keys not available."""

    error_code = "KEYS_NOT_FOUND"
    status_code = 400
    message = "Encryption keys unavailable."
