# Spiritual Q&A Platform

**Course**: CS 698 - Software Engineering  
**Architecture**: Flutter frontend + containerized FastAPI backend on AWS EC2 + Amplify hosting.

## Repo map

- `apps/backend`: FastAPI backend, tests, Docker assets, and backend scripts.
- `apps/frontend`: Flutter client, integration tests, and frontend tooling.
- `apps/docs-site`: Docusaurus site for published project docs.
- `infra/terraform`: AWS infrastructure definitions.
- `infra/production`: EC2 production Docker Compose and reverse-proxy assets.
- `docs/product`: Product and engineering reference docs.
- `docs/course`: Course artifacts, specs, and reflection material.
- `tools/dev`: Durable developer utilities.
- `tools/ops`: Repo maintenance and operational helpers.
- `tools/archive`: Archived one-off utilities and tracked diagnostics.
- `submission`: Submission bundles and course deliverables.

## Local development

### Backend
```bash
cd apps/backend
poetry install --with dev --no-interaction
poetry run uvicorn app.main:app --reload
```

### Frontend
```bash
cd apps/frontend
flutter pub get
# ensure apps/frontend/.env exists
flutter run
```

### Full-stack integration from clean checkout
```bash
bash apps/frontend/tool/run_e2e.sh
```

## Deployment architecture (production)

- Backend: Docker Compose stack (`infra/production/docker-compose.prod.yml`) running on EC2 provisioned by Terraform.
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
- `.github/workflows/deploy-aws-ec2.yml`
  - **filename kept as deploy-aws-ec2.yml despite course artifacts mentioning lambda**; this workflow deploys the EC2-hosted Docker backend and does not use AWS Lambda.

## AWS setup for forked repos

1. Create repository secrets:
   - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
   - `OPENAI_API_KEY`, `CSRF_SECRET`, `JWT_PRIVATE_KEY`, `JWT_PUBLIC_KEY`
   - `EC2_KEY_NAME`, `EC2_SSH_PRIVATE_KEY`
   - `AMPLIFY_PROD_WEBHOOK_URL`, `AMPLIFY_STAGING_WEBHOOK_URL`
2. Update `infra/terraform/provider.tf` region if needed.
3. Validate infra locally:
   ```bash
   cd infra/terraform
   terraform init
   terraform validate
   ```
4. Deploy backend via workflow dispatch of `deploy-aws-ec2.yml` (despite the previous lambda naming, this deploys the EC2/Docker backend) or via the verified `main` trigger.

## Frontend/backend configuration expectations

- Frontend API base URL is env-driven through `API_BASE_URL` in `apps/frontend/.env`.
- Integration tests may override backend target via `E2E_BASE_URL`.
- Backend production logging emits JSON-structured logs.
- Deployment readiness checks must call `/health/full`.

## Submission artifacts

This repository includes required workflow filenames for submission:
- `run-backend-tests.yml`
- `run-frontend-tests.yml`
- `run-integration-tests.yml`
- `deploy-aws-amplify.yml`
- `deploy-aws-ec2.yml` (Renamed from deploy-aws-lambda.yml)
