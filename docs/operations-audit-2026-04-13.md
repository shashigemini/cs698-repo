# Operations Audit

Date: 2026-04-13

Scope: repository audit against deployment automation, quality assurance and CI gates, staged deployments, and monitoring infrastructure.

## Summary

The repository has useful local development and testing assets, but its delivery controls are uneven. Static site deployment is automated, while backend deployment is not codified in-repo. CI exists, but two generic test workflows act as smoke tests rather than full release gates. Environment separation is weak for the frontend, and observability is limited to logging plus shallow health checks.

## Findings

### 1. Frontend deploy bypasses staging

Severity: P1

File: `.github/workflows/deploy.yml`

The frontend deployment workflow publishes pushes from both `frontend_development` and `main` to the same GitHub Pages target. It does not use protected GitHub environments, approval gates, or a promotion step from a non-production artifact to production.

Impact:

- A development-branch push can replace the live site.
- Deployment is not tied to successful verification jobs.
- There is no clean distinction between preview/staging and production releases.

### 2. Backend test check is only a smoke test

Severity: P1

File: `.github/workflows/run-backend-tests.yml`

The generic backend test workflow only runs `tests/test_security.py` and `tests/test_auth_service.py`. The repository contains a much broader backend suite, including API, middleware, repository, logging, and rate-limiter tests, but those are not part of this workflow.

Impact:

- CI can report backend success while large portions of the backend are failing.
- PR status signals are weaker than the workflow name suggests.
- Contributors may mistake a smoke test for a release gate.

### 3. Frontend test check covers only two files

Severity: P1

File: `.github/workflows/run-frontend-tests.yml`

The generic frontend test workflow runs only two selected test files and does not run `flutter analyze`, formatter checks, or a production-oriented build verification step.

Impact:

- Frontend regressions outside those two files can ship undetected.
- Static analysis and formatting drift are not enforced in CI.
- Web build breakage can remain invisible until deployment time.

### 4. E2E automation points at missing or stale paths

Severity: P2

Files:

- `frontend/tool/run_e2e.sh`
- `docs/test_suite_report.md`

The scripted E2E orchestration refers to `../backend/docker/docker-compose.e2e.yml`, but the repository stores the compose file at `backend/docker_configs/docker-compose.e2e.yml`. The test report also instructs contributors to run `tool/run_e2e_integration.sh`, which does not exist in the repository.

Impact:

- The documented end-to-end verification path is unreliable.
- New contributors are likely to fail before reaching the intended test flow.
- The strongest available QA layer is harder to trust operationally.

### 5. Health checks can stay green with broken RAG dependencies

Severity: P2

Files:

- `backend/app/api/health_router.py`
- `backend/app/main.py`
- `backend/Dockerfile`

The base `/health` endpoint always reports `healthy`, and the container healthcheck uses that shallow endpoint. The more detailed `/health/full` route checks PostgreSQL and Redis, but leaves `qdrant` and `openai` as `unknown`.

Impact:

- Containers can be treated as healthy while core retrieval and generation dependencies are unavailable.
- Orchestration status can drift from actual user-facing readiness.
- Monitoring cannot reliably distinguish partial degradation in the RAG path.

### 6. Monitoring infrastructure is minimal

Severity: P3

Files:

- `backend/app/core/logging.py`
- `frontend/lib/core/utils/app_logger.dart`

The codebase includes logging and some log redaction, but there is no in-repo evidence of metrics collection, tracing, alerting, external log shipping, uptime monitoring, or service-level dashboards. The backend logging module also documents JSON logging for production while configuring plain text output.

Impact:

- Operational diagnosis depends on ad hoc log access.
- There is no clear path from failure to alerting.
- Service health trends and latency/error-rate tracking are not represented in the repo.

## Recommendations

1. Turn the generic frontend and backend test workflows into true gates by running the full maintained suites, plus analysis and build verification where appropriate.
2. Separate frontend staging and production deployments with distinct branches or environments, and require successful verification before promotion.
3. Fix the stale E2E paths and make the documented full-stack test entrypoint runnable from a clean checkout.
4. Add a codified backend deployment pipeline that covers image build, migration rollout, environment scoping, and promotion.
5. Upgrade health checks so readiness reflects Qdrant and OpenAI dependency status for the real RAG path.
6. Define a baseline observability stack: structured logs, metrics, alerting, and an external uptime/readiness signal.
