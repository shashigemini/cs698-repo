#!/usr/bin/env bash
# scripts/run_all_p5_tests.sh
# Combined runner for all P5 unit tests

set -u # Don't use -e yet so we can report both results

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Ensure scripts are executable
chmod +x "$REPO_ROOT/frontend/scripts/run_tests.sh"
chmod +x "$REPO_ROOT/backend/scripts/run_p5_tests.sh"

echo "Running Frontend P5 Tests..."
"$REPO_ROOT/frontend/scripts/run_tests.sh"
FRONTEND_EXIT=$?

echo ""
echo "Running Backend P5 Tests..."
"$REPO_ROOT/backend/scripts/run_p5_tests.sh"
BACKEND_EXIT=$?

echo ""
echo "========================================"
echo " Combined P5 Results"
echo "========================================"
[ $FRONTEND_EXIT -eq 0 ] && echo "  Frontend: ✅ PASS" || echo "  Frontend: ❌ FAIL"
[ $BACKEND_EXIT  -eq 0 ] && echo "  Backend:  ✅ PASS" || echo "  Backend:  ❌ FAIL"

if [ $FRONTEND_EXIT -eq 0 ] && [ $BACKEND_EXIT -eq 0 ]; then
    echo "========================================"
    echo " ALL P5 TESTS PASSED! 🎉"
    exit 0
else
    echo "========================================"
    echo " ONE OR MORE TEST SUITES FAILED. ❌"
    exit 1
fi
