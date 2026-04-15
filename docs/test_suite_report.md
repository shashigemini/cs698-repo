# Comprehensive Test Suite & Operations Report

This document is the source of truth for how to run tests and operational checks after P6 hardening.

## 1) Quick Start (clean checkout)

### Backend verification
```bash
cd backend
./scripts/run_local_tests.sh
```

### Frontend verification
```bash
cd frontend
flutter pub get
flutter test
```

### Full-stack integration (single entrypoint)
```bash
bash frontend/tool/run_e2e.sh
```

## 2) Backend test matrix

- Unit + integration suite (local Python environment):
  ```bash
  cd backend
  poetry install --with dev --no-interaction
  poetry run pytest -v
  ```
- Containerized backend test run:
  ```bash
  cd backend
  ./scripts/run_tests.sh
  ```

## 3) Frontend test matrix

- Unit/widget tests:
  ```bash
  cd frontend
  flutter test
  ```
- Analyze + format checks:
  ```bash
  cd frontend
  flutter analyze
  dart format --set-exit-if-changed lib test integration_test tool
  ```
- Production web build verification:
  ```bash
  cd frontend
  flutter build web --release
  ```

## 4) Integration/E2E

- Local dockerized full-stack:
  ```bash
  bash frontend/tool/run_e2e.sh
  ```
- Cloud-targeted integration (manual CI dispatch):
  - Trigger `.github/workflows/run-integration-tests.yml`
  - Provide `target_url` input to run against deployed backend.

`frontend/tool/run_e2e.sh` supports:
- `E2E_BASE_URL` (default `http://localhost:8000`)
- `E2E_TARGET_PATH` (default `integration_test/e2e`)
- `E2E_COMPOSE_FILE` (default `backend/docker_configs/docker-compose.e2e.yml`)

## 5) Operational checks

- Liveness:
  ```bash
  curl -fsS http://localhost:8000/health
  ```
- Readiness (deployment gate):
  ```bash
  curl -fsS http://localhost:8000/health/full
  ```

Readiness is degraded when PostgreSQL, Redis, Qdrant, or OpenAI checks fail.
