"""E2EE key storage ORM model."""

import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, LargeBinary, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class E2EEKey(Base):
    """Stores E2EE key material for a user.

    The server stores wrapped (encrypted) keys — it never has
    access to the plaintext AccountKey. The salt is used by the
    client to re-derive the LocalMasterKey from the password.
    """

    __tablename__ = "user_e2ee_keys"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    salt: Mapped[bytes] = mapped_column(
        LargeBinary, nullable=False
    )
    wrapped_account_key: Mapped[str] = mapped_column(
        Text, nullable=False
    )
    recovery_wrapped_ak: Mapped[str] = mapped_column(
        Text, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    user = relationship("User", back_populates="e2ee_keys")
