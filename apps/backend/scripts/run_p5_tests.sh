#!/usr/bin/env bash
# apps/backend/scripts/run_p5_tests.sh
# Runs P5 backend unit tests with coverage

set -e

# Navigate to backend directory
cd "$(dirname "$0")/.."

echo "========================================"
echo " Running Backend P5 Unit Tests"
echo "========================================"

# Activate virtual environment if present
if [ -d ".venv" ]; then
    source .venv/bin/activate
fi

# Run pytest on the targeted files
pytest \
    tests/test_security.py \
    tests/test_auth_service.py \
    -v \
    --cov=app.core.security \
    --cov=app.services.auth_service \
    --cov-report=term-missing

echo ""
echo "Backend P5 Tests: ✅ SUCCESS"
