# MEDISYNC Deployment Script for Windows
# PowerShell script for deploying MEDISYNC on Windows

param(
    [string]$Environment = "production",
    [string]$Target = "docker"
)

# Colors for output
$Host.UI.RawUI.ForegroundColor = 'White'

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "→ $Message" -ForegroundColor Yellow
}

function Write-Header {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " $Message" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
}

Write-Header "MEDISYNC Deployment Script"
Write-Host "Environment: " -NoNewline
Write-Host $Environment -ForegroundColor Yellow
Write-Host "Target: " -NoNewline
Write-Host $Target -ForegroundColor Yellow

# Check prerequisites
function Check-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    # Check Docker
    try {
        docker --version | Out-Null
        Write-Success "Docker is installed"
    } catch {
        Write-Error "Docker is not installed"
        Write-Host "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
        exit 1
    }
    
    # Check Docker Compose
    try {
        docker-compose --version | Out-Null
        Write-Success "Docker Compose is installed"
    } catch {
        Write-Error "Docker Compose is not installed"
        exit 1
    }
    
    # Check if Docker is running
    try {
        docker ps | Out-Null
        Write-Success "Docker is running"
    } catch {
        Write-Error "Docker is not running. Please start Docker Desktop"
        exit 1
    }
}

# Load environment variables
function Load-Environment {
    Write-Header "Loading Environment Variables"
    
    $envFile = ".env.$Environment"
    if (Test-Path $envFile) {
        Write-Success "Loading from $envFile"
        Get-Content $envFile | ForEach-Object {
            if ($_ -notmatch '^#' -and $_ -match '=') {
                $parts = $_ -split '=', 2
                [Environment]::SetEnvironmentVariable($parts[0], $parts[1], 'Process')
            }
        }
    } else {
        Write-Info ".env.$Environment not found, using defaults"
    }
}

# Generate secrets
function Generate-Secret {
    $bytes = New-Object byte[] 32
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return [Convert]::ToBase64String($bytes)
}

# Build Docker images
function Build-Docker {
    Write-Header "Building Docker Images"
    
    # Build backend
    Write-Info "Building backend..."
    docker build -t medisync-backend:latest .
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build backend"
        exit 1
    }
    Write-Success "Backend built successfully"
    
    # Build frontend
    Write-Info "Building frontend..."
    Set-Location medisync-frontend
    docker build -t medisync-frontend:latest .
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build frontend"
        exit 1
    }
    Set-Location ..
    Write-Success "Frontend built successfully"
}

# Deploy with Docker Compose
function Deploy-Docker {
    Write-Header "Deploying with Docker Compose"
    
    # Stop existing containers
    Write-Info "Stopping existing containers..."
    docker-compose down
    
    # Start services
    Write-Info "Starting services..."
    if ($Environment -eq "production") {
        docker-compose --profile production up -d
    } else {
        docker-compose up -d
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to start services"
        exit 1
    }
    
    # Wait for services to be healthy
    Write-Info "Waiting for services to be healthy..."
    Start-Sleep -Seconds 15
    
    # Run database migrations
    Write-Info "Running database migrations..."
    docker-compose exec -T backend flask db init 2>$null
    docker-compose exec -T backend flask db migrate -m "Initial migration"
    docker-compose exec -T backend flask db upgrade
    
    Write-Success "Deployment completed successfully"
}

# Deploy to local Docker
function Deploy-Local {
    Write-Header "Deploying Locally with Docker"
    
    # Use SQLite for local deployment
    [Environment]::SetEnvironmentVariable('USE_SQLITE', 'true', 'Process')
    
    # Build and run
    Build-Docker
    Deploy-Docker
}

# Health checks
function Health-Check {
    Write-Header "Running Health Checks"
    
    # Check backend
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5000/health" -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Success "Backend is healthy"
        }
    } catch {
        Write-Error "Backend health check failed"
    }
    
    # Check frontend
    try {
        $response = Invoke-WebRequest -Uri "http://localhost/health" -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Success "Frontend is healthy"
        }
    } catch {
        Write-Info "Frontend health check failed (may need more time to start)"
    }
    
    # Check database
    $dbHealth = docker-compose exec -T database mysqladmin ping -h localhost 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Database is healthy"
    } else {
        Write-Info "Database health check failed (SQLite may be in use)"
    }
}

# Quick start for development
function Quick-Start {
    Write-Header "Quick Start for Development"
    
    # Stop any running containers
    docker-compose down 2>$null
    
    # Use SQLite for quick start
    [Environment]::SetEnvironmentVariable('USE_SQLITE', 'true', 'Process')
    [Environment]::SetEnvironmentVariable('FLASK_ENV', 'development', 'Process')
    
    # Start backend without Docker
    Write-Info "Starting backend..."
    Start-Process -FilePath "python" -ArgumentList "app.py" -NoNewWindow
    
    # Start frontend
    Write-Info "Starting frontend..."
    Set-Location medisync-frontend
    Start-Process -FilePath "npm" -ArgumentList "start" -NoNewWindow
    Set-Location ..
    
    Write-Success "Development servers started"
    Write-Host "`nAccess the application at:"
    Write-Host "  Frontend: " -NoNewline
    Write-Host "http://localhost:3000" -ForegroundColor Yellow
    Write-Host "  Backend API: " -NoNewline
    Write-Host "http://localhost:5000" -ForegroundColor Yellow
    Write-Host "  API Docs: " -NoNewline
    Write-Host "http://localhost:5000/docs" -ForegroundColor Yellow
}

# Main execution
function Main {
    # Check prerequisites
    Check-Prerequisites
    
    # Load environment
    Load-Environment
    
    # Generate secrets if not set
    if (-not $env:SECRET_KEY) {
        $env:SECRET_KEY = Generate-Secret
        Write-Info "Generated SECRET_KEY"
    }
    
    if (-not $env:JWT_SECRET_KEY) {
        $env:JWT_SECRET_KEY = Generate-Secret
        Write-Info "Generated JWT_SECRET_KEY"
    }
    
    # Deploy based on target
    switch ($Target) {
        "docker" {
            Build-Docker
            Deploy-Docker
            Health-Check
        }
        "local" {
            Deploy-Local
            Health-Check
        }
        "quick" {
            Quick-Start
        }
        default {
            Write-Error "Unknown deployment target: $Target"
            Write-Host "Valid targets: docker, local, quick"
            exit 1
        }
    }
    
    Write-Header "Deployment Complete!"
    
    if ($Target -ne "quick") {
        Write-Host "`nAccess the application at:"
        Write-Host "  Frontend: " -NoNewline
        Write-Host "http://localhost" -ForegroundColor Yellow
        Write-Host "  Backend API: " -NoNewline
        Write-Host "http://localhost:5000" -ForegroundColor Yellow
        Write-Host "  API Docs: " -NoNewline
        Write-Host "http://localhost:5000/docs" -ForegroundColor Yellow
        
        Write-Host "`nUseful commands:"
        Write-Host "  View logs: " -NoNewline
        Write-Host "docker-compose logs -f" -ForegroundColor Gray
        Write-Host "  Stop services: " -NoNewline
        Write-Host "docker-compose down" -ForegroundColor Gray
        Write-Host "  Restart services: " -NoNewline
        Write-Host "docker-compose restart" -ForegroundColor Gray
    }
}

# Run main function
Main
