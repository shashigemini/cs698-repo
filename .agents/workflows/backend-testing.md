---
description: How to run backend tests and mock core modules
---

# Backend Testing Workflow and Guide

This workflow explains how to execute the backend test suite using Docker and how to correctly mock and test the core application services.

## Running Tests

### 1. Run the entire test suite

This script spins up necessary databases (PostgreSQL, Redis, Qdrant) in Docker and runs `pytest`. Wait for the script to finish and clean up.

```bash
// turbo
.\scripts\run_tests.bat
```
*(On Linux/macOS, use `./scripts/run_tests.sh`)*

### 2. Run a specific test file or test case

If you are debugging a specific failure, you should use the `docker-compose.test.yml` file to spin up an ephemeral container for that specific test instead of running the whole suite.

```bash
// turbo
docker compose -f docker-compose.test.yml run --rm test-runner pytest tests/test_services_extra.py -vv
```

Or for a specific class/method:
```bash
// turbo
docker compose -f docker-compose.test.yml run --rm test-runner pytest tests/test_services_extra.py::TestAuthServiceAdditional::test_register_service -vv
```

> [!TIP]
> **Non-Destructive Cleanup**: Avoid killing Docker processes or shell runners forcefully. Use `docker compose down` or Ctrl+C to allow processes to exit gracefully and maintain environment health.

## Testing Core Modules

### 1. Mocking Database Dependencies
When unit testing services (e.g., `DocumentService`, `AuthService`, `ConversationService`), always mock the `AsyncSession` and pass it to the service constructor.
- Use `AsyncMock()` for the session itself.
- Remember that `repo._session.commit()` is asynchronous, so it must be mocked as an `AsyncMock()`.

Example:
```python
mock_session = AsyncMock()
service = AuthService(settings, mock_session)
```

### 2. Mocking Repositories inside Services
When isolating a service, you must mock its internal repositories to prevent actual database interactions.
- Avoid passing `MagicMock` instances as the returned user objects where the application intends to serialize the response to JSON (e.g. `fastapi.responses.JSONResponse`). Set serializable dictionary-like keys or explicit standard types instead.
- For async repository methods like `repo.get_by_email`, use `AsyncMock(return_value=your_mock_user)`.

Example:
```python
user = MagicMock()
user.id = uuid.uuid4()
user.role = "user"
# DO NOT let mock properties default to MagicMock if they are JSON serialized later.
auth._user_repo.get_by_email = AsyncMock(return_value=user)
```

### 3. Mocking JWT / TokenService
`TokenService.generate_token_pair` is a **synchronous** function, unlike many other service methods.
When testing services that use the `TokenService` (like `AuthService.register` or `AuthService.login_verify`), mock the token service synchronously:

```python
auth._token_service = MagicMock()
auth._token_service.generate_token_pair = MagicMock(return_value={
    "access_token": "mock_access",
    "refresh_token": "mock_refresh",
    "access_expires_at": 123456789
})
```
*Attempting to use `AsyncMock()` here will cause a `TypeError: 'coroutine' object is not subscriptable` when the service tries to read the token dictionaries.*

### 4. Background Tasks (`DocumentService`)
Background pipelines like document ingestion require thorough dependency mocking:
- Use `unittest.mock.patch` to patch `app.dependencies._database` entirely so it doesn't attempt to spin up a connection pool.
- Patch RAG components synchronously or asynchronously depending on their true signatures:
  - `parse_pdf` (sync)
  - `chunk_text` (sync)
  - `Embedder.embed_batch` (async)
  - `QdrantStore.upsert_document_chunks` (async)

Example testing of RAG pipeline without real DB:
```python
with patch("app.dependencies._database"), \
     patch("app.rag.chunker.chunk_text") as mock_chunk, \
     patch("app.rag.embedder.Embedder") as mock_embedder:
    # Set up mock returns
    mock_chunk.return_value = [MagicMock(text="chunk")]
    mock_embedder.return_value.embed_batch = AsyncMock(return_value=[[0.1]*1536])
    
    # Run async pipeline
    await service._process_document_pipeline(...)
```

By following this workflow, testing the backend services will remain deterministic and isolated.
