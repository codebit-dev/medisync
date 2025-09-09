Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "   MEDISYNC Services Health Check" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Wait for services
Write-Host "Waiting for services to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$allGood = $true

# Test Backend
Write-Host ""
Write-Host "1. Backend API Tests:" -ForegroundColor Yellow

try {
    $health = Invoke-RestMethod -Uri "http://localhost:5000/health" -Method Get -ErrorAction Stop
    Write-Host "   Health Check: PASSED" -ForegroundColor Green
} catch {
    Write-Host "   Health Check: FAILED" -ForegroundColor Red
    $allGood = $false
}

# Test Frontend
Write-Host ""
Write-Host "2. Frontend Tests:" -ForegroundColor Yellow

try {
    $frontend = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -ErrorAction Stop
    Write-Host "   React App: RUNNING" -ForegroundColor Green
} catch {
    Write-Host "   React App: NOT RUNNING" -ForegroundColor Red
    $allGood = $false
}

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan

if ($allGood) {
    Write-Host "All services are running!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access points:" -ForegroundColor White
    Write-Host "  Frontend: http://localhost:3000" -ForegroundColor Cyan
    Write-Host "  API Docs: http://localhost:5000/docs" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Login: demo / demo123" -ForegroundColor Gray
} else {
    Write-Host "Some services have issues." -ForegroundColor Yellow
}

Write-Host "===========================================" -ForegroundColor Cyan
