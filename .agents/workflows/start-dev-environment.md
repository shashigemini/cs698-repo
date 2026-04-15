---
description: How to start the full dev environment (backend + frontend) for end-to-end testing
---
# Starting the Dev Environment

This workflow launches the full-stack dev environment: PostgreSQL, Redis, Qdrant, FastAPI backend (with real OpenAI), and the Flutter frontend with PDF upload + admin capabilities.

## Prerequisites
- Docker and Docker Compose installed
- Flutter SDK available
- Your OpenAI API key configured in `apps/backend/.env`

> [!IMPORTANT]
> **Devcontainer Networking**: Inside a devcontainer, Docker services are NOT on `localhost`. Use `host.docker.internal` to reach ports published by Docker Compose. The Flutter app's `API_BASE_URL` in `apps/frontend/.env` must also point to `http://host.docker.internal:8000`.

---

// turbo-all
1. Start the backend services (PostgreSQL, Redis, Qdrant, FastAPI) using Docker Compose. Data is persisted across restarts via named volumes.
```bash
cd /workspaces/cs698-repo/apps/backend/dev_test
docker compose -f docker-compose.dev.yml up --build -d
```

2. Wait for all services to be healthy. Check with:
```bash
cd /workspaces/cs698-repo/apps/backend/dev_test
docker compose -f docker-compose.dev.yml ps
```
All services should show `healthy` or `running`. The `app` service runs Alembic migrations on startup.

3. Verify the backend is reachable and all dependencies are connected:
```bash
curl http://host.docker.internal:8000/health/full
```
Expected: `{"status": "healthy", ...}` with database and redis both `"up"`.

> [!NOTE]
> Inside a devcontainer, use `host.docker.internal` instead of `localhost` for all service URLs.

4. Start the Flutter frontend. Since we're in a devcontainer, use `web-server` device:
```bash
cd /workspaces/cs698-repo/apps/frontend
flutter run -d web-server --target lib/main_dev_e2e.dart
```
This starts the app with Marionette MCP integration, demo mode (admin access without auth), and real API backend connection.

5. Open the frontend in a browser at the URL shown in the terminal output (typically `http://localhost:<port>`).

## Testing the Full Pipeline

6. Navigate to the **Admin Dashboard** (accessible from the home screen side menu).

7. **Upload a PDF**: Pick a file, fill in title and book ID, click "Upload & Ingest". Watch the document status transition: `pending` → `processing` → `ingested`.

8. **Test chat**: Go to the Chat screen and ask questions about the uploaded content. The full RAG pipeline (retrieval from Qdrant → LLM generation via OpenAI) should return relevant answers with citations.

## Teardown

9. Stop the frontend with `Ctrl+C` in the terminal.

10. Stop backend services:
```bash
cd /workspaces/cs698-repo/apps/backend/dev_test
docker compose -f docker-compose.dev.yml down
```

> [!TIP]
> To **keep data** between sessions, use `down` without `-v`.
> To **wipe everything** (volumes, database, Qdrant collections), use `down -v`.

## Troubleshooting

- **PDF upload fails with 413**: Ensure `MAX_REQUEST_BODY_BYTES=104857600` is set in the docker compose environment (already configured).
- **Backend can't connect to services**: Make sure no other containers are using ports 5432, 6379, 6333, or 8000.
- **CORS errors in browser**: The compose file allows origins on ports 3000, 5000, and 8080. If Flutter uses a different port, add it to `CORS_ORIGINS` in the compose file.
- **Qdrant collection not created**: The backend auto-creates the collection on startup. Check `docker compose logs app` for errors.
