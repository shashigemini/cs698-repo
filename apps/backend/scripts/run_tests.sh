#!/bin/bash
# run_tests.sh
# Convenience script to run backend tests in an isolated Docker environment
# No local Python or Testcontainers required.

set -e

echo "Running backend tests via Docker Compose..."

# Navigate to backend directory if not already there
cd "$(dirname "$0")/.."

# Build and run the test runner, then remove the runner container
docker compose -f docker-compose.test.yml run --build --rm test-runner

# Clean up all spawned services (postgres, redis, qdrant)
echo "Cleaning up test environment..."
docker compose -f docker-compose.test.yml down -v

echo "Tests completed."
