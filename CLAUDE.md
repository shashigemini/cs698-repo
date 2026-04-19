# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Spiritual Q&A Platform — a Flutter web/mobile client backed by a FastAPI RAG (Retrieval-Augmented Generation) service. Users authenticate, then ask spiritual questions; the backend retrieves relevant passages from a Qdrant vector store and generates answers via OpenAI.

**Stack**: Flutter (Riverpod + GoRouter) · FastAPI · PostgreSQL · Qdrant · Redis · AWS EC2 + Amplify

## Repository layout

```
apps/backend/        FastAPI backend (Python 3.11, Poetry)
apps/frontend/       Flutter client (Dart 3, build_runner codegen)
apps/docs-site/      Docusaurus documentation site
infra/terraform/     AWS infrastructure definitions
infra/production/    EC2 Docker Compose + reverse-proxy configs
tools/               Dev utilities and operational scripts
```

## Backend (`apps/backend`)

### Development

```bash
cd apps/backend
poetry install --with dev --no-interaction
poetry run uvicorn app.main:app --reload
```

Or use Docker Compose (starts Postgres, Redis, Qdrant, and the API with hot-reload):

```bash
cp apps/backend/.env.example apps/backend/.env  # fill in OPENAI_API_KEY and JWT keys
docker compose -f apps/backend/dev_test/docker-compose.dev.yml up -d --build
```

### Testing

```bash
# Fast local suite (SQLite + mocked Redis) — use during development
cd apps/backend && ./scripts/run_local_tests.sh

# Run a single test file
cd apps/backend && poetry run pytest tests/test_auth_service.py -v

# Full Docker suite (real Postgres/Redis/Qdrant containers)
cd apps/backend && ./scripts/run_tests.sh

# Mutation tests
cd apps/backend && ./scripts/run_mutation_tests.sh
```

### Linting / formatting

```bash
cd apps/backend
poetry run ruff check .
poetry run ruff format .
```

### Architecture

The backend follows a **router → service → repository** layering:

- `app/api/` — FastAPI routers (`auth_router`, `chat_router`, `admin_router`, `health_router`). Only HTTP concerns: request parsing, auth deps, response shaping.
- `app/services/` — Business logic (`auth_service`, `rag_service`, `conversation_service`, `token_service`, etc.). No HTTP knowledge.
- `app/repositories/` — Database access via SQLAlchemy async sessions (`user_repo`, `session_repo`, `document_repo`, `revoked_token_repo`).
- `app/rag/` — RAG pipeline: `pdf_parser` → `chunker` → `embedder` → `qdrant_store` (write path); `embedder` → `retriever` → `llm_client` (query path).
- `app/core/` — Infrastructure: async database pool, Redis client, security utilities, structured logging, error handlers.
- `app/middleware/` — CSRF, body-size limit, request ID, security headers.
- `app/config.py` — Pydantic-settings `Settings` class; all config comes from environment variables or `.env`.
- `app/dependencies.py` — FastAPI dependency injection wiring (get_db_session, get_redis, etc.).
- `app/main.py` — App factory (`create_app`), middleware ordering, lifespan hooks. The `e2e_testing` environment loads `e2e_overrides.py` to stub out OpenAI.

**Three data stores**: PostgreSQL (users, sessions, messages, revoked tokens), Qdrant (vector embeddings in the `spiritual_docs` collection, 1536-dim cosine), Redis (rate limiting by IP and session ID).

**JWT**: RS256 asymmetric keys. Access tokens (15 min), refresh tokens (7 days). Generate keys with `scripts/generate_keys.py`.

**RAG flow**: user query → embed via OpenAI → similarity search in Qdrant → top-k passages → prompt assembly (`app/rag/prompts.py`) → OpenAI chat completion → streamed response.

### Key environment variables

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | PostgreSQL async connection string |
| `REDIS_URL` | Redis connection |
| `QDRANT_HOST` / `QDRANT_PORT` | Qdrant location |
| `OPENAI_API_KEY` | Embeddings + chat completions |
| `JWT_PRIVATE_KEY` / `JWT_PUBLIC_KEY` | RS256 PEM keys |
| `CSRF_SECRET` | CSRF token signing (production only) |
| `ENVIRONMENT` | `development` \| `staging` \| `production` \| `testing` \| `e2e_testing` |

## Frontend (`apps/frontend`)

### Development

```bash
cd apps/frontend
cp .env.example .env  # set API_BASE_URL=http://localhost:8000
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # re-run after changing annotated files
flutter run
```

Entry points: `main.dart` (production), `main_dev.dart` (development), `main_dev_e2e.dart` (E2E testing).

### Testing

```bash
cd apps/frontend
flutter analyze
flutter test                                 # all unit/widget tests
flutter test test/features/auth/             # single feature
flutter test integration_test/               # integration tests (needs running backend)
flutter build web --release                  # production build verification
```

### Architecture

The frontend follows a **feature-slice** pattern. Each feature under `lib/features/<name>/` has four layers:

- `presentation/` — Widgets and screens
- `application/` — Riverpod controllers/notifiers (business logic, state)
- `domain/` — Pure models and interfaces
- `data/` — Repository implementations, API clients

Shared infrastructure lives in `lib/core/`:
- `router/app_router.dart` — GoRouter with auth-aware redirects. Uses `authControllerProvider` to guard routes; unauthenticated users go to `/login`, authenticated away from it. Uses `riverpod_generator` (`@riverpod` annotation) — changes require `build_runner`.
- `network/` — Dio HTTP client setup
- `providers/` — Cross-feature Riverpod providers
- `services/` — Local settings store, security service (freeRASP for jailbreak detection)
- `theme/` — `AppTheme` with light/dark themes

**State management**: Riverpod throughout. Generated providers use `@riverpod` annotation; run `build_runner` after changes to `*.dart` files with `@riverpod`, `@freezed`, or `@JsonSerializable`.

**Code generation**: `riverpod_generator`, `freezed`, `json_serializable`, `envied` (env vars). Always run `dart run build_runner build --delete-conflicting-outputs` after modifying annotated files.

**Security features**: `freeRASP` (root/jailbreak detection), `secure_application` (screenshot prevention in app switcher), `flutter_secure_storage` (token storage), `http_certificate_pinning`.

**Routes**: `/` (startup/splash), `/login`, `/home`, `/settings`, `/admin` (admin-only, guarded in router).

## Full-stack E2E

```bash
bash apps/frontend/tool/run_e2e.sh
```

This starts a backend in `e2e_testing` mode (OpenAI stubbed out), seeds Qdrant, and runs Flutter integration tests.

## CI/CD

| Workflow | Trigger | Purpose |
|---|---|---|
| `run-backend-tests.yml` | PR / push | ruff + pytest full suite |
| `run-frontend-tests.yml` | PR / push | analyze + test + web build |
| `run-integration-tests.yml` | PR / manual | full-stack integration |
| `deploy-aws-amplify.yml` | verified `main` | Flutter web → Amplify |
| `deploy-aws-ec2.yml` | verified `main` | Docker backend → EC2 |

Health endpoints: `GET /health` (liveness) · `GET /health/full` (readiness — checks Postgres, Redis, Qdrant, OpenAI).
