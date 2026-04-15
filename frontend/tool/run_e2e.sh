#!/usr/bin/env bash
# Full-stack E2E runner from a clean checkout.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/frontend"
BACKEND_DIR="$ROOT_DIR/backend"
COMPOSE_FILE="${E2E_COMPOSE_FILE:-$BACKEND_DIR/docker_configs/docker-compose.e2e.yml}"
E2E_TARGET_PATH="${E2E_TARGET_PATH:-integration_test/e2e}"
E2E_BASE_URL="${E2E_BASE_URL:-http://localhost:8000}"

TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
RESULTS_DIR="$FRONTEND_DIR/test_results/e2e_$TIMESTAMP"
mkdir -p "$RESULTS_DIR"

info(){ echo -e "\033[0;36m[INFO]\033[0m $*"; }
step(){ echo -e "\033[0;33m[STEP]\033[0m $*"; }

cleanup() {
  step "Tearing down E2E services"
  docker compose -f "$COMPOSE_FILE" down -v || true
}
trap cleanup EXIT

step "Starting full-stack E2E environment"
docker compose -f "$COMPOSE_FILE" up -d --build --force-recreate

step "Waiting for readiness: $E2E_BASE_URL/health/full"
for i in {1..45}; do
  if curl -fsS "$E2E_BASE_URL/health/full" >/dev/null; then
    info "Backend readiness check passed"
    break
  fi
  sleep 2
  if [ "$i" -eq 45 ]; then
    echo "[ERROR] backend failed readiness check" >&2
    echo "[INFO] Dumping compose service status and app logs for diagnosis" >&2
    docker compose -f "$COMPOSE_FILE" ps >&2 || true
    docker compose -f "$COMPOSE_FILE" logs app --no-color >&2 || true
    exit 1
  fi
done

step "Seeding E2E data"
curl -fsS -X POST "$E2E_BASE_URL/api/test/seed" >/dev/null

step "Running integration tests from target: $E2E_TARGET_PATH"
cd "$FRONTEND_DIR"
if [ ! -f .env ]; then
  cat <<EOF > .env
API_BASE_URL=http://localhost:8000
ANDROID_PACKAGE_NAME=com.example.frontend
ANDROID_CERT_HASH=DUMMY
IOS_BUNDLE_ID=com.example.frontend
IOS_TEAM_ID=DUMMY
SECURITY_WATCHER_MAIL=security@example.org
SSL_CERT_FINGERPRINT=DUMMY
USE_SSL_PINNING=false
EOF
fi
dart run build_runner build --delete-conflicting-outputs
LOG_FILE="$RESULTS_DIR/frontend_tests.log"
dart run tool/run_integration_tests.dart "$E2E_TARGET_PATH" --log-file "$LOG_FILE"

step "Capturing backend logs"
docker compose -f "$COMPOSE_FILE" logs --no-color > "$RESULTS_DIR/backend_compose.log"

info "E2E run completed. Artifacts: $RESULTS_DIR"
