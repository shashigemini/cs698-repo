#!/bin/bash
# run_local_tests.sh
# Convenience script to run backend tests locally using SQLite and Mocked Redis.
# Automatically installs any missing development dependencies before running.

set -e

# Navigate to backend directory if not already there
cd "$(dirname "$0")/.."

echo "Ensuring development dependencies are installed..."
poetry install --with dev --no-interaction

echo "Running local pytest..."
poetry run pytest "$@"

echo "Local tests completed."
