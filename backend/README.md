# CS698 Project 4 Backend

This directory contains the unified FastAPI backend for the Spiritual Guide application, serving both authentication and RAG-based AI chat capabilities.

## External Dependencies

This project relies heavily on the following external frameworks and libraries:
*   **FastAPI**: For the asynchronous HTTP web framework.
*   **SQLAlchemy & Alembic**: For ORM database modeling and asynchronous database migrations.
*   **LlamaIndex**: Essential for orchestrating the RAG pipeline, chunking PDFs, and managing the vector store.
*   **OpenAI**: Uses the `gpt-4.1-mini` API endpoint for final answer generation.
*   **Qdrant-Client**: Python driver for the Qdrant vector database.
*   **Passlib (Argon2) & PyJWT**: For secure password hashing and stateless token management.
*   **Redis.asyncio**: For distributed rate limiting and connection pooling.

## Databases
This backend interacts with three distinct data stores:
1.  **PostgreSQL (Relational)**:
    *   **Operations**: Created, read, and written.
    *   **Purpose**: Stores `users`, `revoked_tokens` (for auth), `chat_sessions`, and `chat_messages` (with RAG metadata JSON fields).
2.  **Qdrant (Vector)**:
    *   **Operations**: Read and written (via LlamaIndex).
    *   **Purpose**: Stores chunked text embeddings representing the spiritual guide PDFs (inside the `spiritual_docs` collection) for semantic similarity search.
3.  **Redis (Key-Value Key/Cache)**:
    *   **Operations**: Read and written.
    *   **Purpose**: Tracks IP addresses and session IDs for brute-force and chat rate-limiting.

---

## Operations Guide

This project is optimized for containerized development, ensuring a consistent environment with all required databases natively integrated.

### 1. Devcontainer Setup (Recommended)
This repository includes a full `.devcontainer` configuration. Opening this project in VS Code (or Cursor) with the Devcontainer extension will automatically build the environment, install all Python dependencies via Poetry, and set up your workspace without affecting your host machine.

### 2. Local Development (Docker Compose)
We use a dedicated development compose file (`dev_test/docker-compose.dev.yml`) to spin up the entire backend along with its databases (Postgres, Redis, Qdrant). This file also runs the FastAPI server with hot-reloading enabled.

1. **Create your environment variables:**
   ```bash
   cp .env.example .env
   ```
   *Make sure to fill in your `OPENAI_API_KEY` and set a secure `SECRET_KEY`.*

2. **Start the development environment:**
   ```bash
   docker compose -f backend/dev_test/docker-compose.dev.yml up -d --build
   ```
   *This starts the databases, runs Alembic migrations automatically, and starts the FastAPI server on `http://localhost:8000` with auto-reload enabled. Swagger docs are available at `http://localhost:8000/docs`.*

3. **View application logs:**
   ```bash
   docker compose -f backend/dev_test/docker-compose.dev.yml logs -f app
   ```

### 3. Testing
We support two testing workflows. For comprehensive details, see the backend testing workflow guide.

- **Containerized Integration Tests (Recommended):** Tests against real, ephemeral Postgres, Redis, and Qdrant containers.
  ```bash
  # Linux/macOS
  ./backend/scripts/run_tests.sh
  
  # Windows
  .\backend\scripts\run_tests.bat
  ```
- **Local SQLite/Mocked Tests (Fast):** Tests using a local SQLite database and mocked Redis. Perfect for fast iterations.
  ```bash
  bash ./backend/scripts/run_local_tests.sh
  ```

### 4. Teardown
To cleanly stop the development containers without destroying your database data:
```bash
docker compose -f backend/dev_test/docker-compose.dev.yml stop
```

### 5. Resetting Data (Hard Teardown)
If you need to completely wipe all data (users, vector embeddings, chat history) and start fresh:
```bash
docker compose -f backend/dev_test/docker-compose.dev.yml down -v
```
