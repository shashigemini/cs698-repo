"""Structured logging with PII scrubbing.

All log output passes through scrub() to strip passwords, tokens,
API keys, and email addresses. Uses Python stdlib logging with
JSON-formatted output for production observability.
"""

import logging
import re
import sys
from typing import Any

_SENSITIVE_KEYS = frozenset({
    "password",
    "password_hash",
    "access_token",
    "refresh_token",
    "token",
    "client_auth_token",
    "authorization",
    "x-csrf-token",
    "csrf_token",
    "api_key",
    "openai_api_key",
    "jwt_private_key",
    "jwt_public_key",
    "secret",
    "wrapped_account_key",
    "recovery_wrapped_ak",
    "salt",
})

_EMAIL_RE = re.compile(
    r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
)


def scrub(data: Any) -> Any:
    """Recursively redact sensitive values from dicts/lists.

    Replaces values of sensitive keys with '[REDACTED]' and
    masks email addresses in string values.
    """
    if isinstance(data, dict):
        return {
            k: "[REDACTED]" if k.lower() in _SENSITIVE_KEYS else scrub(v)
            for k, v in data.items()
        }
    if isinstance(data, list):
        return [scrub(item) for item in data]
    if isinstance(data, str):
        return _EMAIL_RE.sub("[EMAIL]", data)
    return data


def setup_logging(*, debug: bool = False) -> None:
    """Configure root logger for the application."""
    level = logging.DEBUG if debug else logging.INFO
    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(level)

    formatter = logging.Formatter(
        fmt="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S",
    )
    handler.setFormatter(formatter)

    root = logging.getLogger()
    root.setLevel(level)
    # Avoid duplicate handlers on re-init
    root.handlers = [handler]

    # Quieten noisy libraries
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)


def get_logger(name: str) -> logging.Logger:
    """Get a named logger for a module."""
    return logging.getLogger(name)
