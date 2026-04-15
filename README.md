# Spiritual Q&A Platform

**Course**: CS 698 - Software Engineering  
**Architecture**: Flutter frontend + containerized FastAPI backend on AWS EC2 + Amplify hosting.

## Local development

### Backend
```bash
cd backend
poetry install --with dev --no-interaction
poetry run uvicorn app.main:app --reload
```

### Frontend
```bash
cd frontend
flutter pub get
# ensure frontend/.env exists
flutter run
```

### Full-stack integration from clean checkout
```bash
bash frontend/tool/run_e2e.sh
```

## Deployment architecture (production)

- Backend: Docker Compose stack (`backend/docker-compose.prod.yml`) running on EC2 provisioned by Terraform.
- Dependencies: PostgreSQL, Redis, Qdrant containers in same host stack.
- Frontend: AWS Amplify-hosted Flutter web artifact, deployed via GitHub Actions webhooks.

## Health/readiness model

- `GET /health`: lightweight liveness only.
- `GET /health/full`: readiness for PostgreSQL + Redis + Qdrant + OpenAI path. Used for deployment validation and container health checks.

## CI/CD workflows

- `.github/workflows/run-backend-tests.yml`
  - canonical backend verification gate (ruff + format + full pytest suite).
- `.github/workflows/run-frontend-tests.yml`
  - canonical frontend verification gate (format + analyze + tests + production web build).
- `.github/workflows/run-integration-tests.yml`
  - local full-stack integration path for PRs and optional cloud-targeted manual execution.
- `.github/workflows/deploy-aws-amplify.yml`
  - frontend deployment path. Production deployment only from verified `main`; staging webhook is separate.
- `.github/workflows/deploy-aws-lambda.yml`
  - **filename kept for course artifact compatibility**; deploys the approved **containerized backend**, not Lambda.

## AWS setup for forked repos

1. Create repository secrets:
   - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
   - `OPENAI_API_KEY`, `CSRF_SECRET`, `JWT_PRIVATE_KEY`, `JWT_PUBLIC_KEY`
   - `AMPLIFY_PROD_WEBHOOK_URL`, `AMPLIFY_STAGING_WEBHOOK_URL`
2. Update `terraform/provider.tf` region if needed.
3. Validate infra locally:
   ```bash
   cd terraform
   terraform init
   terraform validate
   ```
4. Deploy backend via workflow dispatch of `deploy-aws-lambda.yml` (or verified `main` trigger).

## Frontend/backend configuration expectations

- Frontend API base URL is env-driven through `API_BASE_URL` in `frontend/.env`.
- Integration tests may override backend target via `E2E_BASE_URL`.
- Backend production logging emits JSON-structured logs.
- Deployment readiness checks must call `/health/full`.

## Submission artifacts

This repository includes required workflow filenames for submission:
- `run-backend-tests.yml`
- `run-frontend-tests.yml`
- `run-integration-tests.yml`
- `deploy-aws-amplify.yml`
- `deploy-aws-lambda.yml`
