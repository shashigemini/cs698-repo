@echo off
:: run_tests.bat
:: Convenience script to run backend tests in an isolated Docker environment
:: No local Python or Testcontainers required.

echo Running backend tests via Docker Compose...

:: Navigate to backend directory
cd /d "%~dp0\.."

:: Build and run the test runner, then remove the runner container
docker compose -f docker\docker-compose.test.yml run --build --rm test-runner

:: Store the exit code of pytest
set TEST_EXIT_CODE=%ERRORLEVEL%

:: Clean up all spawned services (postgres, redis, qdrant)
echo Cleaning up test environment...
docker compose -f docker\docker-compose.test.yml down -v

echo Tests completed with test exit code %TEST_EXIT_CODE%.
exit /b %TEST_EXIT_CODE%
