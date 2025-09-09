# MEDISYNC Deployment Guide

## 📋 Table of Contents
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Docker Deployment](#docker-deployment)
- [Cloud Deployment](#cloud-deployment)
- [Production Configuration](#production-configuration)
- [SSL/HTTPS Setup](#sslhttps-setup)
- [Monitoring & Maintenance](#monitoring--maintenance)

## Prerequisites

### Required Software
- **Docker Desktop** (Windows/Mac) or Docker Engine (Linux)
- **Docker Compose** v2.0+
- **Node.js** 18+ (for local development)
- **Python** 3.11+ (for local development)
- **Git** for version control

### System Requirements
- **Minimum**: 4GB RAM, 2 CPU cores, 20GB storage
- **Recommended**: 8GB RAM, 4 CPU cores, 50GB storage
- **Production**: 16GB RAM, 8 CPU cores, 100GB+ storage

## 🚀 Quick Start

### Windows (PowerShell)
```powershell
# Quick development start
.\deploy.ps1 -Target quick

# Docker deployment
.\deploy.ps1 -Environment production -Target docker
```

### Linux/Mac (Bash)
```bash
# Make script executable
chmod +x deploy.sh

# Quick development start
./deploy.sh --target docker --env development

# Production deployment
./deploy.sh --target docker --env production
```

## 🐳 Docker Deployment

### 1. Local Docker Deployment

```bash
# Clone the repository
git clone https://github.com/your-org/medisync.git
cd medisync

# Copy environment file
cp .env.production .env

# Edit .env with your configuration
nano .env

# Build and deploy
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### 2. Docker Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart services
docker-compose restart

# View logs
docker-compose logs -f [service-name]

# Execute commands in container
docker-compose exec backend bash
docker-compose exec database mysql -u root -p

# Backup database
docker-compose exec database mysqldump -u root -p medisync > backup.sql

# Restore database
docker-compose exec -T database mysql -u root -p medisync < backup.sql
```

## ☁️ Cloud Deployment

### AWS Deployment

#### 1. Using AWS ECS

```bash
# Install AWS CLI
pip install awscli

# Configure AWS credentials
aws configure

# Create ECR repositories
aws ecr create-repository --repository-name medisync-backend
aws ecr create-repository --repository-name medisync-frontend

# Deploy
./deploy.sh --target aws --env production
```

#### 2. Using AWS EC2

```bash
# Launch EC2 instance (Ubuntu 22.04 LTS)
# Security Group: Open ports 80, 443, 22, 5000

# SSH into instance
ssh -i medisync-key.pem ubuntu@your-ec2-ip

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Clone and deploy
git clone https://github.com/your-org/medisync.git
cd medisync
sudo docker-compose up -d
```

### Azure Deployment

#### Using Azure Container Instances

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Create resource group
az group create --name medisync-rg --location centralindia

# Create container registry
az acr create --resource-group medisync-rg --name medisyncregistry --sku Basic

# Deploy
./deploy.sh --target azure --env production
```

### Google Cloud Platform (GCP)

```bash
# Install gcloud CLI
curl https://sdk.cloud.google.com | bash

# Initialize gcloud
gcloud init

# Create GKE cluster
gcloud container clusters create medisync-cluster \
    --zone asia-south1-a \
    --num-nodes 3

# Deploy to GKE
kubectl apply -f kubernetes/
```

### Heroku Deployment

```bash
# Install Heroku CLI
curl https://cli-assets.heroku.com/install.sh | sh

# Login to Heroku
heroku login

# Create apps
heroku create medisync-backend
heroku create medisync-frontend

# Deploy
./deploy.sh --target heroku --env production
```

## 🔒 Production Configuration

### 1. Environment Variables

Create `.env.production` with:

```env
# Security
SECRET_KEY=$(openssl rand -hex 32)
JWT_SECRET_KEY=$(openssl rand -hex 32)
FLASK_ENV=production
DEBUG=false

# Database
MYSQL_HOST=your-db-host
MYSQL_USER=medisync_user
MYSQL_PASSWORD=strong-password-here
MYSQL_DATABASE=medisync

# ABHA Integration
ABHA_CLIENT_ID=your-abha-client-id
ABHA_CLIENT_SECRET=your-abha-client-secret
ABHA_AUTH_URL=https://healthid.abdm.gov.in/api/v1/auth

# WHO ICD-11 API
ICD11_CLIENT_ID=your-icd11-client-id
ICD11_CLIENT_SECRET=your-icd11-client-secret

# Redis
REDIS_URL=redis://redis:6379/0

# Email
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=app-specific-password
```

### 2. Database Setup

```sql
-- Create production database
CREATE DATABASE medisync CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create user
CREATE USER 'medisync_user'@'%' IDENTIFIED BY 'strong-password';

-- Grant privileges
GRANT ALL PRIVILEGES ON medisync.* TO 'medisync_user'@'%';
FLUSH PRIVILEGES;
```

### 3. Security Hardening

```yaml
# docker-compose.prod.yml
services:
  backend:
    environment:
      - FLASK_ENV=production
      - DEBUG=false
      - SESSION_COOKIE_SECURE=true
      - SESSION_COOKIE_HTTPONLY=true
      - WTF_CSRF_ENABLED=true
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

## 🔐 SSL/HTTPS Setup

### Using Let's Encrypt with Certbot

```bash
# Install Certbot
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d medisync.in -d www.medisync.in

# Auto-renewal
sudo certbot renew --dry-run
```

### Using Cloudflare

1. Add your domain to Cloudflare
2. Update DNS records
3. Enable "Full (strict)" SSL/TLS encryption
4. Enable "Always Use HTTPS"

### Nginx SSL Configuration

```nginx
server {
    listen 443 ssl http2;
    server_name medisync.in;

    ssl_certificate /etc/letsencrypt/live/medisync.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/medisync.in/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    location / {
        proxy_pass http://frontend:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /api {
        proxy_pass http://backend:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 📊 Monitoring & Maintenance

### 1. Health Monitoring

```bash
# Check application health
curl http://localhost:5000/health
curl http://localhost/health

# Monitor with Prometheus
docker-compose --profile monitoring up -d

# Access Grafana
http://localhost:3000 (admin/admin)
```

### 2. Logging

```bash
# View logs
docker-compose logs -f backend
docker-compose logs -f frontend

# Export logs
docker-compose logs > medisync_logs_$(date +%Y%m%d).txt

# Log rotation (add to crontab)
0 0 * * * find /var/log/medisync -name "*.log" -mtime +30 -delete
```

### 3. Backup Strategy

```bash
# Automated backup script (backup.sh)
#!/bin/bash
BACKUP_DIR="/backups/medisync"
DATE=$(date +%Y%m%d_%H%M%S)

# Database backup
docker-compose exec -T database mysqldump -u root -p$MYSQL_ROOT_PASSWORD medisync > $BACKUP_DIR/db_$DATE.sql

# Compress
gzip $BACKUP_DIR/db_$DATE.sql

# Upload to S3 (optional)
aws s3 cp $BACKUP_DIR/db_$DATE.sql.gz s3://medisync-backups/

# Keep only last 30 days
find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete
```

### 4. Performance Optimization

```yaml
# Add to docker-compose.yml
services:
  redis:
    image: redis:7-alpine
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru
    
  backend:
    environment:
      - GUNICORN_WORKERS=4
      - GUNICORN_THREADS=2
      - GUNICORN_TIMEOUT=120
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Container won't start
```bash
# Check logs
docker-compose logs backend

# Rebuild image
docker-compose build --no-cache backend
docker-compose up -d
```

#### 2. Database connection error
```bash
# Check database is running
docker-compose ps database

# Test connection
docker-compose exec database mysql -u root -p

# Reset database
docker-compose down -v
docker-compose up -d
```

#### 3. Port already in use
```bash
# Find process using port
netstat -tulpn | grep :5000

# Kill process
kill -9 <PID>

# Or change port in docker-compose.yml
```

## 📝 Deployment Checklist

- [ ] Environment variables configured
- [ ] Database credentials secured
- [ ] SSL certificates installed
- [ ] Firewall rules configured
- [ ] Backup strategy implemented
- [ ] Monitoring setup
- [ ] Health checks passing
- [ ] Load testing completed
- [ ] Security scan passed
- [ ] Documentation updated

## 🚨 Emergency Procedures

### Rollback
```bash
# Stop current deployment
docker-compose down

# Checkout previous version
git checkout <previous-tag>

# Redeploy
docker-compose up -d
```

### Emergency Maintenance Mode
```nginx
# Add to nginx.conf
location / {
    return 503;
    error_page 503 @maintenance;
}

location @maintenance {
    root /usr/share/nginx/html;
    rewrite ^.*$ /maintenance.html break;
}
```

## 📞 Support

For deployment assistance:
- Email: support@medisync.in
- Documentation: https://docs.medisync.in
- Issues: https://github.com/your-org/medisync/issues

---

**Last Updated**: November 2024
**Version**: 1.0.0
