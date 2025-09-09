Write-Host "Checking MEDISYNC Services Status..." -ForegroundColor Cyan
Write-Host ""

# Check Flask Backend
Write-Host "Backend API (Port 5000):" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:5000/health" -Method Get -ErrorAction Stop
    Write-Host "  ✓ Flask API is running" -ForegroundColor Green
    Write-Host "  Status: $($response.status)" -ForegroundColor Gray
    Write-Host "  Service: $($response.service)" -ForegroundColor Gray
} catch {
    Write-Host "  ✗ Flask API is not responding" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Gray
}

Write-Host ""

# Check React Frontend
Write-Host "Frontend App (Port 3000):" -ForegroundColor Yellow
try {
    $webResponse = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -ErrorAction Stop
    if ($webResponse.StatusCode -eq 200) {
        Write-Host "  ✓ React Frontend is running" -ForegroundColor Green
        Write-Host "  Status Code: $($webResponse.StatusCode)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ✗ React Frontend is not responding" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Gray
}

Write-Host ""

# Check Swagger Documentation
Write-Host "API Documentation:" -ForegroundColor Yellow
try {
    $swaggerResponse = Invoke-WebRequest -Uri "http://localhost:5000/docs" -UseBasicParsing -ErrorAction Stop
    if ($swaggerResponse.StatusCode -eq 200) {
        Write-Host "  ✓ Swagger docs available at http://localhost:5000/docs" -ForegroundColor Green
    }
} catch {
    Write-Host "  ✗ Swagger docs not accessible" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Quick Access Links:" -ForegroundColor White
Write-Host "  Frontend: http://localhost:3000" -ForegroundColor Gray
Write-Host "  API Docs: http://localhost:5000/docs" -ForegroundColor Gray
Write-Host "  Health:   http://localhost:5000/health" -ForegroundColor Gray
