"""Tests for app.core.logging — scrub, setup_logging, get_logger."""

import logging

from app.core.logging import get_logger, scrub, setup_logging


class TestScrub:
    """Tests for PII scrubbing utility."""

    def test_redacts_sensitive_dict_keys(self):
        data = {
            "email": "user@example.com",
            "password": "secret123",
            "token": "abc",
            "name": "Alice",
        }
        result = scrub(data)
        assert result["password"] == "[REDACTED]"
        assert result["token"] == "[REDACTED]"
        assert result["name"] == "Alice"

    def test_redacts_emails_in_strings(self):
        text = "Contact admin@test.com for help"
        result = scrub(text)
        assert "admin@test.com" not in result
        assert "[EMAIL]" in result

    def test_recurses_into_lists(self):
        data = [{"password": "x"}, "user@a.com"]
        result = scrub(data)
        assert result[0]["password"] == "[REDACTED]"
        assert "[EMAIL]" in result[1]

    def test_passthrough_non_sensitive(self):
        assert scrub(42) == 42
        assert scrub(None) is None
        assert scrub(True) is True


class TestSetupLogging:
    """Tests for logging configuration."""

    def test_setup_debug_mode(self):
        setup_logging(debug=True)
        root = logging.getLogger()
        assert root.level == logging.DEBUG
        assert len(root.handlers) == 1

    def test_setup_production_mode(self):
        setup_logging(debug=False)
        root = logging.getLogger()
        assert root.level == logging.INFO

    def test_quietens_noisy_libraries(self):
        setup_logging(debug=False)
        sa_logger = logging.getLogger("sqlalchemy.engine")
        assert sa_logger.level == logging.WARNING


class TestGetLogger:
    """Tests for get_logger factory."""

    def test_returns_logger_instance(self):
        log = get_logger("test.module")
        assert isinstance(log, logging.Logger)
        assert log.name == "test.module"
