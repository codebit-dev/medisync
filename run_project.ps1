# MEDISYNC Project Launcher
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    MEDISYNC EHR Integration Platform   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if a port is in use
function Test-Port {
    param($Port)
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    try {
        $tcpClient.Connect("127.0.0.1", $Port)
        $tcpClient.Close()
        return $true
    } catch {
        return $false
    }
}

# Check if ports are already in use
if (Test-Port 5000) {
    Write-Host "WARNING: Port 5000 is already in use. Flask backend might be running." -ForegroundColor Yellow
    $stopBackend = Read-Host "Do you want to stop the existing backend? (y/n)"
    if ($stopBackend -eq 'y') {
        Get-Process -Name python* | Where-Object {$_.MainWindowTitle -like "*flask*" -or $_.CommandLine -like "*app.py*"} | Stop-Process -Force
        Start-Sleep -Seconds 2
    }
}

if (Test-Port 3000) {
    Write-Host "WARNING: Port 3000 is already in use. React frontend might be running." -ForegroundColor Yellow
    $stopFrontend = Read-Host "Do you want to stop the existing frontend? (y/n)"
    if ($stopFrontend -eq 'y') {
        Get-Process -Name node* | Where-Object {$_.MainWindowTitle -like "*react*"} | Stop-Process -Force
        Start-Sleep -Seconds 2
    }
}

Write-Host "Starting MEDISYNC services..." -ForegroundColor Green
Write-Host ""

# Start Backend (Flask API)
Write-Host "1. Starting Flask Backend API on port 5000..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
    cd 'D:\coding\Project\MEDISYNC'
    Write-Host '========================================' -ForegroundColor Green
    Write-Host '     MEDISYNC Backend API Server       ' -ForegroundColor Green
    Write-Host '========================================' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Activating Python virtual environment...' -ForegroundColor Cyan
    .\venv\Scripts\Activate.ps1
    Write-Host 'Starting Flask server...' -ForegroundColor Cyan
    python app.py
"@

# Wait for backend to start
Write-Host "Waiting for backend to start..." -ForegroundColor Gray
Start-Sleep -Seconds 5

# Start Frontend (React)
Write-Host "2. Starting React Frontend on port 3000..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", @"
    cd 'D:\coding\Project\MEDISYNC\medisync-frontend'
    Write-Host '========================================' -ForegroundColor Blue
    Write-Host '     MEDISYNC Frontend React App       ' -ForegroundColor Blue
    Write-Host '========================================' -ForegroundColor Blue
    Write-Host ''
    Write-Host 'Starting React development server...' -ForegroundColor Cyan
    npm start
"@

# Wait for services to fully start
Write-Host ""
Write-Host "Waiting for services to fully initialize..." -ForegroundColor Gray
Start-Sleep -Seconds 10

# Display access information
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "    MEDISYNC Services are Starting!    " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access Points:" -ForegroundColor Cyan
Write-Host "  Frontend Application:  http://localhost:3000" -ForegroundColor White
Write-Host "  Backend API:          http://localhost:5000" -ForegroundColor White
Write-Host "  API Documentation:    http://localhost:5000/docs" -ForegroundColor White
Write-Host "  Health Check:         http://localhost:5000/health" -ForegroundColor White
Write-Host ""
Write-Host "Demo Login Credentials:" -ForegroundColor Cyan
Write-Host "  Username: demo" -ForegroundColor White
Write-Host "  Password: demo123" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C in each terminal window to stop the services" -ForegroundColor Yellow
Write-Host ""

# Open browser
$openBrowser = Read-Host "Do you want to open the application in browser? (y/n)"
if ($openBrowser -eq 'y') {
    Start-Sleep -Seconds 5
    Start-Process "http://localhost:3000"
}

Write-Host ""
Write-Host "Services are running. This window can be closed." -ForegroundColor Green
