# -----------------------------------------------------------
# Production Dockerfile for the Spiritual Q&A Backend
#
# Multi-stage build:
#   1. Builder: Install dependencies into a virtualenv
#   2. Runtime: Copy virtualenv into a slim image
#
# Usage:
#   docker build -t spiritual-qa-backend .
#   docker run -p 8000:8000 --env-file .env spiritual-qa-backend
# -----------------------------------------------------------

# Stage 1: Builder
FROM python:3.11-slim AS builder

WORKDIR /app

# Install system deps for compiling extensions (asyncpg, argon2-cffi)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    libffi-dev \
    libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install --no-cache-dir poetry==1.8.2

# Copy dependency files first (Docker layer caching)
COPY pyproject.toml poetry.lock* ./

# Install production dependencies into a virtualenv
RUN poetry config virtualenvs.in-project true
RUN poetry config keyring.enabled false
RUN poetry config installer.max-workers 1
RUN poetry install --only main --no-interaction --no-ansi

# Stage 2: Runtime
FROM python:3.11-slim AS runtime

# Security: non-root user
RUN useradd --create-home --shell /bin/bash appuser

WORKDIR /app

# Install runtime-only system deps
RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq5 && \
    rm -rf /var/lib/apt/lists/*

# Copy virtualenv from builder
COPY --from=builder /app/.venv /app/.venv

# Copy application code
COPY app/ /app/app/
COPY scripts/ /app/scripts/
COPY alembic/ /app/alembic/
COPY alembic.ini /app/

# Set PATH to use virtualenv
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONPATH="/app" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create data directory for PDF storage
RUN mkdir -p /app/data/pdfs && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health/full')"

# Expose port
EXPOSE 8000

# Run with uvicorn (4 workers for production)
CMD ["uvicorn", "app.main:app", \
    "--host", "0.0.0.0", \
    "--port", "8000", \
    "--workers", "4", \
    "--proxy-headers", \
    "--forwarded-allow-ips", "*"]
