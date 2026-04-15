# Integration Test Specification (P6)

## Goal
Validate end-to-end behavior across Flutter frontend, FastAPI backend, PostgreSQL, Redis, Qdrant, and OpenAI readiness conditions.

## Local entrypoint
Use a single command from repository root:

```bash
bash frontend/tool/run_e2e.sh
```

## Required behavior
1. Start backend stack from `backend/docker_configs/docker-compose.e2e.yml`.
2. Wait for `/health/full` readiness.
3. Seed deterministic E2E data via `POST /api/test/seed`.
4. Execute frontend tests under `frontend/integration_test/e2e/`.
5. Collect compose logs into `frontend/test_results/e2e_<timestamp>/`.
6. Teardown all services.

## Configuration
- `E2E_BASE_URL`: Backend target URL.
- `E2E_TARGET_PATH`: Integration test file or directory.
- `E2E_COMPOSE_FILE`: Override compose file path.

## CI coverage
- PRs automatically run local full-stack integration in `.github/workflows/run-integration-tests.yml`.
- A manual dispatch path accepts `target_url` for deployed-environment validation.
