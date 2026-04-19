"""Application configuration loaded from environment variables.

Uses pydantic-settings for validation and type coercion.
All secrets come from environment variables — never hardcoded.
"""

from functools import lru_cache
import typing
from typing import Optional

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings with environment variable binding."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # --- Application ---
    app_name: str = "Spiritual Q&A Backend"
    app_version: str = "0.1.0"
    debug: bool = False
    environment: str = Field(default="development", pattern="^(development|staging|production|testing|e2e_testing)$")

    # --- Server ---
    host: str = "0.0.0.0"
    port: int = 8000

    # --- Database (PostgreSQL) ---
    database_url: str = Field(
        default="postgresql+asyncpg://postgres:postgres@localhost:5432/spiritual_qa",
        description="Async SQLAlchemy connection string",
    )
    db_pool_size: int = Field(default=5, ge=1, le=50)
    db_max_overflow: int = Field(default=10, ge=0, le=100)
    db_pool_timeout: int = Field(default=30, ge=5)

    # --- Redis ---
    redis_url: str = Field(default="redis://localhost:6379/0")

    # --- JWT ---
    jwt_private_key: str = Field(
        default="",
        description="RS256 private key (PEM) for signing JWTs",
    )
    jwt_public_key: str = Field(
        default="",
        description="RS256 public key (PEM) for verifying JWTs",
    )
    jwt_algorithm: str = "RS256"
    jwt_access_token_ttl_minutes: int = Field(default=15, ge=1)
    jwt_refresh_token_ttl_days: int = Field(default=7, ge=1)

    # --- CORS ---
    cors_origins: typing.Any = Field(
        default=["http://localhost:3000", "http://localhost:8080"],
        description="Allowed CORS origins",
    )

    # --- Rate Limiting ---
    rate_limit_login_max: int = Field(default=5, ge=1)
    rate_limit_login_window_minutes: int = Field(default=15, ge=1)
    rate_limit_register_max: int = Field(default=3, ge=1)
    rate_limit_register_window_minutes: int = Field(default=60, ge=1)
    rate_limit_guest_query_max: int = Field(default=3, ge=1)
    rate_limit_guest_query_window_hours: int = Field(default=24, ge=1)
    rate_limit_global_max: int = Field(default=100, ge=1)
    rate_limit_global_window_seconds: int = Field(default=60, ge=1)

    # --- OpenAI ---
    openai_api_key: str = Field(default="")
    openai_model: str = Field(default="gpt-4.1-mini")
    openai_embedding_model: str = Field(default="text-embedding-ada-002")
    openai_max_response_tokens: int = Field(default=1024, ge=1)
    openai_temperature: float = Field(default=0.7, ge=0.0, le=2.0)
    openai_timeout_seconds: int = Field(default=30, ge=5)
    openai_max_retries: int = Field(default=3, ge=0)

    # --- Qdrant ---
    qdrant_host: str = Field(default="localhost")
    qdrant_port: int = Field(default=6333)
    qdrant_collection: str = Field(default="spiritual_docs")

    # --- RAG ---
    rag_top_k: int = Field(default=5, ge=1, le=20)
    rag_similarity_threshold: float = Field(default=0.7, ge=0.0, le=1.0)
    rag_chunk_size_tokens: int = Field(default=500, ge=100)
    rag_chunk_overlap_tokens: int = Field(default=50, ge=0)
    rag_max_history_pairs: int = Field(default=5, ge=0)

    # --- Security ---
    csrf_secret: str = Field(default="change-me-in-production")
    max_request_body_bytes: int = Field(default=1_048_576, ge=1024)
    max_query_length: int = Field(default=2000, ge=1)
    max_upload_bytes: int = Field(default=52_428_800)  # 50MB

    # --- PDF Storage ---
    pdf_storage_path: str = Field(default="./data/pdfs")

    @field_validator("cors_origins", mode="before")
    @classmethod
    def _parse_cors_origins(cls, v: typing.Any) -> list[str]:
        """Parse CORS origins from JSON list or comma-separated string."""
        if isinstance(v, str):
            # Strip potential shell quotes
            v = v.strip("'").strip('"').strip()
            
            if not v:
                return []
                
            # Case 1: JSON array (starts with [)
            if v.startswith("[") and v.endswith("]"):
                import json
                try:
                    parsed = json.loads(v)
                    if isinstance(parsed, list):
                        return [str(item) for item in parsed]
                except (json.JSONDecodeError, TypeError):
                    # If JSON fails, fall back to stripping [ ] and treating as CSV
                    v = v[1:-1]
            
            # Case 2: Comma-separated string
            return [s.strip() for s in v.split(",") if s.strip()]
        elif isinstance(v, list):
            return [str(item) for item in v]
        return []

    @field_validator("jwt_private_key", "jwt_public_key", mode="before")
    @classmethod
    def _load_key_from_file_or_value(cls, v: str) -> str:
        """Allow key to be a file path (prefixed with @) or raw PEM."""
        if v.startswith("@"):
            with open(v[1:]) as f:
                return f.read()
        return v

    @property
    def is_production(self) -> bool:
        """Whether the application is running in production."""
        return self.environment == "production"

    @property
    def has_jwt_keys(self) -> bool:
        """Whether JWT RS256 keys are configured."""
        return bool(self.jwt_private_key and self.jwt_public_key)


@lru_cache
def get_settings() -> Settings:
    """Cached settings singleton."""
    return Settings()
