---
description: How to run End-to-End (E2E) integration tests for Flutter + FastAPI
---
# Running E2E Integration Tests

This workflow covers how to launch the E2E backend infrastructure, seed the test data, and run the Flutter integration tests against the live backend services. 

1. Start the backend E2E services (PostgreSQL, Redis, Qdrant, FastAPI) using Docker Compose. Since the E2E environment uses `tmpfs` mounts, data is intentionally ephemeral but the containers will stay running for fast iteration.
```bash
cd apps/backend
docker compose -f docker-compose.e2e.yml up -d
```

2. Wait for the services to become healthy, then seed the test data. This will recreate the Qdrant collection, insert the test document chunks with predetermined vectors, and initialize the E2E configurations.

**Bash:**
```bash
curl -X POST http://localhost:8000/api/test/seed
```

**PowerShell:**
```powershell
Invoke-RestMethod -Method Post -Uri http://localhost:8000/api/test/seed
```

// turbo-all
3. Run the E2E integration tests using the automated orchestration script. This script handles the full lifecycle: starting the backend, seeding data with retries, executing the tests sequentially, capturing all logs, and tearing down the environment.

**Windows (PowerShell):**
```powershell
cd apps/frontend
.\tool\run_e2e.ps1
```

**Linux / Devcontainer (Bash):**
```bash
cd apps/frontend
bash tool/run_e2e.sh
```
The shell script uses `xvfb-run` to provide a virtual display for headless Flutter GUI testing inside the devcontainer. The Dart test runner auto-detects Linux and uses `-d linux` instead of `-d windows`.

The script creates a timestamped folder in `apps/frontend/test_results/` containing `frontend_tests.log` and individual service logs (e.g., `app.log`, `db.log`).

**Manual Execution (For Debugging):**
If you need to keep the environment alive for debugging, follow these steps:
1. `docker compose -f ../backend/docker-compose.e2e.yml up -d`
2. `curl -X POST http://127.0.0.1:8000/api/test/seed`
3. `dart run tool/run_integration_tests.dart integration_test/e2e/ --log-file e2e_manual.log`

> [!IMPORTANT]
> **Process Stability**: The automated script and the Dart runner handle sequential execution and process cleanup gracefully. Avoid manual process termination (`taskkill`) as it can leave the environment in an inconsistent state.

> [!NOTE]
> **Devcontainer / Headless Linux**: When running inside the devcontainer, `xvfb-run` is used automatically by both the shell script and the Dart runner to provide a virtual X display. Ensure `xvfb` is installed in the Dockerfile (already configured).

4. Once you have finished your testing session, you can cleanly tear down the E2E backend infrastructure:
```bash
cd apps/backend
docker compose -f docker-compose.e2e.yml down
```
