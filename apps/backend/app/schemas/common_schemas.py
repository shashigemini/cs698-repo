"""Common Pydantic schemas used across endpoints."""

from typing import Any, Optional

from pydantic import BaseModel


class ErrorResponse(BaseModel):
    """Standard error envelope returned by all error handlers."""

    error_code: str
    message: str
    details: Optional[dict[str, Any]] = None


class MessageResponse(BaseModel):
    """Simple message response for operations like logout."""

    message: str


class ConfigUpdateRequest(BaseModel):
    """Request schema for updating app configuration."""

    openai_api_key: Optional[str] = None
    openai_model: Optional[str] = None
    openai_temperature: Optional[float] = None
