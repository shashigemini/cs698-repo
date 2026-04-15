# run_e2e.ps1
# Automated E2E Orchestration Script for CS698 Project

# 1. Setup paths and timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$resultsDir = "test_results\e2e_$timestamp"
$backendDir = "..\backend"
$composeFile = "$backendDir\docker\docker-compose.e2e.yml"

Write-Host "[INFO] Starting E2E Orchestrated Run: e2e_$timestamp" -ForegroundColor Cyan
if (!(Test-Path $resultsDir)) {
    New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null
}
Write-Host "[INFO] Results folder: $resultsDir" -ForegroundColor Gray

# 2. Fresh Start (Down then Up)
Write-Host "[STEP 1/6] Ensuring fresh environment..." -ForegroundColor Yellow
docker compose -f $composeFile down
docker compose -f $composeFile up -d --force-recreate --build
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Failed to start Docker services." -ForegroundColor Red; exit 1 }

Write-Host "[INFO] Waiting for services to initialize (15s)..." -ForegroundColor Gray
Start-Sleep -Seconds 15

# 3. Seed Data
Write-Host "[STEP 2/6] Seeding E2E database..." -ForegroundColor Yellow
$seedUrl = "http://127.0.0.1:8000/api/test/seed"
$maxRetries = 5
$retryCount = 0
$seeded = $false

while (-not $seeded -and $retryCount -lt $maxRetries) {
    try {
        $response = Invoke-RestMethod -Method Post -Uri $seedUrl -ErrorAction Stop
        Write-Host "[INFO] Seeding request successful!" -ForegroundColor Green
        $seeded = $true
    } catch {
        $retryCount++
        Write-Host "[WARN] Seeding attempt $retryCount failed. Retrying in 5s... ($($_.Exception.Message))" -ForegroundColor Gray
        Start-Sleep -Seconds 5
    }
}

if (-not $seeded) {
    Write-Host "[ERROR] Seeding failed after $maxRetries attempts." -ForegroundColor Red
    exit 1
}

# 4. Execute Tests
Write-Host "[STEP 3/6] Executing Frontend Integration Tests..." -ForegroundColor Yellow
$frontendLog = "$resultsDir\frontend_tests.log"
# Use Start-Process -Wait to be explicitly synchronous if needed, 
# although 'dart run' in PS is usually synchronous, we ensure it pipes correctly.
# We also use Tee-Object to show output while saving to log.
dart run tool/run_integration_tests.dart integration_test/e2e/ --log-file $frontendLog | Tee-Object -FilePath "$resultsDir\orchestrator_live.log"
$testPassed = ($LASTEXITCODE -eq 0)

# 5. Capture Service Logs
Write-Host "[STEP 4/6] Capturing individual service logs..." -ForegroundColor Yellow
$services = @("app", "db", "redis", "qdrant")
foreach ($s in $services) {
    $sLog = "$resultsDir\$s.log"
    Write-Host "   -> Saving logs for $s..." -ForegroundColor Gray
    docker compose -f $composeFile logs $s --no-color | Out-File -FilePath $sLog -Encoding utf8
}

# 6. Teardown
Write-Host "[STEP 5/6] Tearing down E2E Backend services..." -ForegroundColor Yellow
docker compose -f $composeFile down

Write-Host "[STEP 6/6] E2E Orchestration Complete." -ForegroundColor Cyan
if ($testPassed) {
    Write-Host "[SUCCESS] ALL TESTS PASSED." -ForegroundColor Green
} else {
    Write-Host "[FAILURE] SOME TESTS FAILED. Check $frontendLog for details." -ForegroundColor Red
}
Write-Host "[INFO] Summary and logs available in: $resultsDir" -ForegroundColor White
