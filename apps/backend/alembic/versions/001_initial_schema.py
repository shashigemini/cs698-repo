"""Initial schema

Revision ID: 001_initial
Revises:
Create Date: 2026-03-05

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID, JSONB

# revision identifiers
revision: str = "001_initial"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # --- Users ---
    op.create_table(
        "users",
        sa.Column("id", UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text("gen_random_uuid()")),
        sa.Column("email", sa.String(255), unique=True, nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("role", sa.String(50), nullable=False,
                  server_default="user"),
        sa.Column("is_e2ee", sa.Boolean(), nullable=False,
                  server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("CURRENT_TIMESTAMP")),
    )
    op.create_index("idx_users_email", "users", ["email"])

    # --- E2EE Keys ---
    op.create_table(
        "user_e2ee_keys",
        sa.Column("user_id", UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="CASCADE"),
                  primary_key=True),
        sa.Column("salt", sa.LargeBinary(), nullable=False),
        sa.Column("wrapped_account_key", sa.Text(), nullable=False),
        sa.Column("recovery_wrapped_ak", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("CURRENT_TIMESTAMP")),
    )

    # --- Revoked Tokens ---
    op.create_table(
        "revoked_tokens",
        sa.Column("id", UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text("gen_random_uuid()")),
        sa.Column("token_jti", sa.String(255), unique=True, nullable=False),
        sa.Column("user_id", UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="CASCADE"),
                  nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("idx_revoked_tokens_jti",
                    "revoked_tokens", ["token_jti"])
    op.create_index("idx_revoked_tokens_expires",
                    "revoked_tokens", ["expires_at"])

    # --- Chat Sessions ---
    op.create_table(
        "chat_sessions",
        sa.Column("id", UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="CASCADE"),
                  nullable=False),
        sa.Column("title", sa.String(500), nullable=True),
        sa.Column("wrapped_conversation_key", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("CURRENT_TIMESTAMP")),
    )
    op.create_index("idx_sessions_user",
                    "chat_sessions", ["user_id"])
    op.create_index("idx_sessions_updated",
                    "chat_sessions", ["updated_at"])

    # --- Chat Messages ---
    op.create_table(
        "chat_messages",
        sa.Column("id", UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text("gen_random_uuid()")),
        sa.Column("session_id", UUID(as_uuid=True),
                  sa.ForeignKey("chat_sessions.id", ondelete="CASCADE"),
                  nullable=False),
        sa.Column("sender", sa.String(20), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("rag_metadata", JSONB(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("CURRENT_TIMESTAMP")),
    )
    op.create_index("idx_messages_session",
                    "chat_messages", ["session_id"])
    op.create_index("idx_messages_created",
                    "chat_messages", ["created_at"])

    # --- Documents ---
    op.create_table(
        "documents",
        sa.Column("id", UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text("gen_random_uuid()")),
        sa.Column("logical_book_id", sa.String(255), nullable=False),
        sa.Column("title", sa.String(500), nullable=False),
        sa.Column("author", sa.String(255), nullable=True),
        sa.Column("edition", sa.String(255), nullable=True),
        sa.Column("file_path", sa.String(1000), nullable=False),
        sa.Column("total_pages", sa.Integer(), nullable=True),
        sa.Column("chunks_created", sa.Integer(), nullable=False,
                  server_default=sa.text("0")),
        sa.Column("embedding_model", sa.String(100), nullable=False,
                  server_default="text-embedding-ada-002"),
        sa.Column("ingestion_status", sa.String(50), nullable=False,
                  server_default="pending"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("CURRENT_TIMESTAMP")),
    )
    op.create_index("idx_documents_book",
                    "documents", ["logical_book_id"])
    op.create_index("idx_documents_status",
                    "documents", ["ingestion_status"])


def downgrade() -> None:
    op.drop_table("chat_messages")
    op.drop_table("chat_sessions")
    op.drop_table("documents")
    op.drop_table("revoked_tokens")
    op.drop_table("user_e2ee_keys")
    op.drop_table("users")
