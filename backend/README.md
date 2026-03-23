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

### 1. Installation

Ensure you have Python 3.11+ installed. We use `poetry` for dependency management. Access the `.env.example` file and copy it to `.env`, filling in your `OPENAI_API_KEY` and setting a secure `SECRET_KEY`.

```bash
cd backend
poetry install
```

### 2. Starting Databases

The required databases (PostgreSQL, Qdrant, Redis) are containerized. You must start them before running migrations or the backend application.

```bash
cd backend
docker-compose up -d
```
*Wait ~5 seconds for PostgreSQL to accept connections.*

### 3. Running Migrations

Database schemas are managed by Alembic. Run the migrations to set up the PostgreSQL tables. Qdrant collections are initialized automatically by the app payload, but Postgres requires this step.

```bash
cd backend
poetry run alembic upgrade head
```

### 4. Application Startup

Start the FastAPI unified backend server. It will run on `http://localhost:8000` by default.

```bash
cd backend
poetry run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
*You can access the auto-generated Swagger documentation at `http://localhost:8000/docs`.*

### 5. Application Teardown

To cleanly stop the application:
1. Hit `CTRL+C` in the terminal running the `uvicorn` server to allow background cleanup tasks to finish gracefully.
2. Stop the data containers without destroying the data:
```bash
cd backend
docker-compose stop
```

### 6. Resetting Data (Hard Teardown)

If you need to completely wipe all users, chat history, and vector embeddings (useful during active development):

```bash
cd backend
docker-compose down -v
```
This command destroys the containers and their attached volumes. You will need to run the Alembic migrations again (`alembic upgrade head`) before starting the app.
