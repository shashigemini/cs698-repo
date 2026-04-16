"""Structured logging with PII scrubbing."""

import json
import logging
import re
import sys
from datetime import datetime, timezone
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
    """Recursively redact sensitive values from dicts/lists."""
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


class JsonFormatter(logging.Formatter):
    """JSON formatter for production logs."""

    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": scrub(record.getMessage()),
        }
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload)


def setup_logging(*, debug: bool = False, structured: bool = False) -> None:
    """Configure root logger for the application."""
    level = logging.DEBUG if debug else logging.INFO
    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(level)

    if structured:
        handler.setFormatter(JsonFormatter())
    else:
        handler.setFormatter(logging.Formatter(
            fmt="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
            datefmt="%Y-%m-%dT%H:%M:%S",
        ))

    root = logging.getLogger()
    root.setLevel(level)
    root.handlers = [handler]

    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)


def get_logger(name: str) -> logging.Logger:
    return logging.getLogger(name)
