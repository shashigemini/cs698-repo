---
name: run-tests
description: Run backend or frontend tests for this project. Supports backend-local (fast SQLite), backend-full (Docker), backend-mutation, frontend unit, and frontend integration (E2E) modes.
---

Choose the test mode based on what you need:

## Backend Tests

### Fast local suite (use during development)
Uses SQLite + mocked Redis — runs in seconds, no Docker needed.
```bash
cd apps/backend && ./scripts/run_local_tests.sh
```

### Single test file
```bash
cd apps/backend && poetry run pytest tests/test_auth_service.py -v
```

### Full Docker suite (real Postgres/Redis/Qdrant)
Use before merging or when testing infra-dependent behavior.
```bash
cd apps/backend && ./scripts/run_tests.sh
```

### Mutation tests
Checks test quality by introducing code mutations. Slow — run intentionally.
```bash
cd apps/backend && ./scripts/run_mutation_tests.sh
```

## Frontend Tests

### Unit and widget tests
```bash
cd apps/frontend && flutter test
```

### Single feature
```bash
cd apps/frontend && flutter test test/features/auth/
```

### Lint
```bash
cd apps/frontend && flutter analyze
```

### Full E2E integration tests
Starts a backend in e2e_testing mode (OpenAI stubbed), seeds Qdrant, runs Flutter integration tests.
```bash
bash apps/frontend/tool/run_e2e.sh
```

## CI equivalent
The GitHub Actions workflows run:
- `run-backend-tests.yml` → ruff + pytest full suite
- `run-frontend-tests.yml` → flutter analyze + flutter test + web build
- `run-integration-tests.yml` → full-stack integration
