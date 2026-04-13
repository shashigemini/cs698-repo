#!/bin/bash
# run_e2e.sh
# Automated E2E Orchestration Script for CS698 Project (Linux/Docker version)

# 1. Setup paths and timestamp
timestamp=$(date +"%Y%m%d_%H%M%S")
resultsDir="test_results/e2e_$timestamp"
backendDir="../backend"
composeFile="$backendDir/docker_configs/docker-compose.e2e.yml"

echo -e "\033[0;36m[INFO] Starting E2E Orchestrated Run: e2e_$timestamp\033[0m"
mkdir -p "$resultsDir"
echo -e "\033[0;37m[INFO] Results folder: $resultsDir\033[0m"

# 2. Fresh Start (Down then Up)
echo -e "\033[0;33m[STEP 1/6] Ensuring fresh environment...\033[0m"
docker compose -f "$composeFile" down
docker compose -f "$composeFile" up -d --force-recreate --build
if [ $? -ne 0 ]; then
    echo -e "\033[0;31m[ERROR] Failed to start Docker services.\033[0m"
    exit 1
fi

echo -e "\033[0;37m[INFO] Waiting for services to initialize (15s)...\033[0m"
sleep 15

# 3. Seed Data
echo -e "\033[0;33m[STEP 2/6] Seeding E2E database...\033[0m"
# Detect Docker Gateway for Devcontainer -> Host communication
GATEWAY_IP=$(ip route show | grep default | awk '{print $3}')
if [ -z "$GATEWAY_IP" ]; then GATEWAY_IP="localhost"; fi
seedUrl="http://$GATEWAY_IP:8000/api/test/seed"
maxRetries=5
retryCount=0
seeded=false

while [ "$seeded" = false ] && [ $retryCount -lt $maxRetries ]; do
    if curl -s -X POST "$seedUrl" > /dev/null; then
        echo -e "\033[0;32m[INFO] Seeding request successful!\033[0m"
        seeded=true
    else
        ((retryCount++))
        echo -e "\033[0;37m[WARN] Seeding attempt $retryCount failed. Retrying in 5s...\033[0m"
        sleep 5
    fi
done

if [ "$seeded" = false ]; then
    echo -e "\033[0;31m[ERROR] Seeding failed after $maxRetries attempts.\033[0m"
    exit 1
fi

# 4. Execute Tests
echo -e "\033[0;33m[STEP 3/6] Executing Frontend Integration Tests...\033[0m"
frontendLog="$resultsDir/frontend_tests.log"
orchestratorLog="$resultsDir/orchestrator_live.log"

# Run integration tests under xvfb-run for headless GUI support
xvfb-run --auto-servernum dart run tool/run_integration_tests.dart integration_test/e2e/ --log-file "$frontendLog" 2>&1 | tee "$orchestratorLog"
testExitCode=${PIPESTATUS[0]}
testPassed=false
if [ $testExitCode -eq 0 ]; then
    testPassed=true
fi

# 5. Capture Service Logs
echo -e "\033[0;33m[STEP 4/6] Capturing individual service logs...\033[0m"
services=("app" "db" "redis" "qdrant")
for s in "${services[@]}"; do
    sLog="$resultsDir/$s.log"
    echo -e "   -> Saving logs for $s..."
    docker compose -f "$composeFile" logs "$s" --no-color > "$sLog"
done

# 6. Teardown
echo -e "\033[0;33m[STEP 5/6] Tearing down E2E Backend services...\033[0m"
docker compose -f "$composeFile" down

echo -e "\033[0;36m[STEP 6/6] E2E Orchestration Complete.\033[0m"
if [ "$testPassed" = true ]; then
    echo -e "\033[0;32m[SUCCESS] ALL TESTS PASSED.\033[0m"
else
    echo -e "\033[0;31m[FAILURE] SOME TESTS FAILED. Check $frontendLog for details.\033[0m"
fi
echo -e "[INFO] Summary and logs available in: $resultsDir"
