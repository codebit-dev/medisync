Write-Host "`n===========================================" -ForegroundColor Cyan
Write-Host "   MEDISYNC Services Health Check" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Wait for services to be ready
Write-Host "Waiting for services to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

$allGood = $true

# Test Backend API
Write-Host "`n1. Backend API Tests:" -ForegroundColor Yellow
Write-Host "---------------------" -ForegroundColor Gray

# Health Check
try {
    $health = Invoke-RestMethod -Uri "http://localhost:5000/health" -Method Get -ErrorAction Stop
    Write-Host "  ✓ Health Check: $($health.status)" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Health Check Failed: $_" -ForegroundColor Red
    $allGood = $false
}

# Test Search Endpoint (no auth required)
try {
    $search = Invoke-RestMethod -Uri "http://localhost:5000/valueset/search?q=test" -Method Get -ErrorAction Stop
    Write-Host "  ✓ Search API: Working" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Search API Failed: $_" -ForegroundColor Red
    $allGood = $false
}

# Check Swagger Docs
try {
    $swagger = Invoke-WebRequest -Uri "http://localhost:5000/docs" -UseBasicParsing -ErrorAction Stop
    if ($swagger.StatusCode -eq 200) {
        Write-Host "  ✓ Swagger Docs: Available" -ForegroundColor Green
    }
} catch {
    Write-Host "  ✗ Swagger Docs Failed: $_" -ForegroundColor Red
    $allGood = $false
}

# Test Frontend
Write-Host "`n2. Frontend Application Tests:" -ForegroundColor Yellow
Write-Host "------------------------------" -ForegroundColor Gray

try {
    $frontend = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -ErrorAction Stop
    if ($frontend.StatusCode -eq 200) {
        Write-Host "  ✓ React App: Running" -ForegroundColor Green
        
        # Check if it contains expected content
        if ($frontend.Content -match "MEDISYNC" -or $frontend.Content -match "root") {
            Write-Host "  ✓ React App: Content Loaded" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "  ✗ React App Failed: $_" -ForegroundColor Red
    $allGood = $false
}

# Test CORS (Frontend calling Backend)
Write-Host "`n3. Cross-Origin Resource Sharing (CORS):" -ForegroundColor Yellow
Write-Host "-----------------------------------------" -ForegroundColor Gray

try {
    $headers = @{
        "Origin" = "http://localhost:3000"
        "Content-Type" = "application/json"
    }
    $corsTest = Invoke-WebRequest -Uri "http://localhost:5000/health" -Headers $headers -UseBasicParsing -ErrorAction Stop
    
    if ($corsTest.Headers["Access-Control-Allow-Origin"]) {
        Write-Host "  ✓ CORS: Properly configured" -ForegroundColor Green
        Write-Host "    Allowed Origin: $($corsTest.Headers["Access-Control-Allow-Origin"])" -ForegroundColor Gray
    } else {
        Write-Host "  ⚠ CORS headers not found (may still work)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ✗ CORS Test Failed: $_" -ForegroundColor Red
}

# Summary
Write-Host "`n===========================================" -ForegroundColor Cyan
Write-Host "            Test Summary" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

if ($allGood) {
    Write-Host "`n✓ All services are running correctly!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now access:" -ForegroundColor White
    Write-Host "  • Frontend App:    http://localhost:3000" -ForegroundColor Cyan
    Write-Host "  • Backend API:     http://localhost:5000" -ForegroundColor Cyan
    Write-Host "  • API Docs:        http://localhost:5000/docs" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Login with:" -ForegroundColor White
    Write-Host "  • Username: demo" -ForegroundColor Gray
    Write-Host "  • Password: demo123" -ForegroundColor Gray
} else {
    Write-Host "`n⚠ Some services have issues. Please check the errors above." -ForegroundColor Yellow
}

Write-Host "`n==========================================="  -ForegroundColor Cyan
