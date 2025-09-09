#!/bin/bash

# MEDISYNC Deployment Script
# Supports multiple deployment targets

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="production"
TARGET="docker"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --target)
            TARGET="$2"
            shift 2
            ;;
        --help)
            echo "Usage: ./deploy.sh [--env production|staging|development] [--target docker|aws|azure|heroku|vps]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}🚀 MEDISYNC Deployment Script${NC}"
echo -e "Environment: ${YELLOW}$ENVIRONMENT${NC}"
echo -e "Target: ${YELLOW}$TARGET${NC}"
echo ""

# Load environment variables
if [ -f ".env.$ENVIRONMENT" ]; then
    echo -e "${GREEN}✓${NC} Loading environment variables from .env.$ENVIRONMENT"
    export $(cat .env.$ENVIRONMENT | grep -v '^#' | xargs)
else
    echo -e "${YELLOW}⚠${NC} .env.$ENVIRONMENT not found, using defaults"
fi

# Function to generate secrets
generate_secret() {
    openssl rand -hex 32
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${GREEN}Checking prerequisites...${NC}"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗${NC} Docker is not installed"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} Docker is installed"
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}✗${NC} Docker Compose is not installed"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} Docker Compose is installed"
}

# Function to build Docker images
build_docker() {
    echo -e "\n${GREEN}Building Docker images...${NC}"
    
    # Build backend
    echo -e "${YELLOW}Building backend...${NC}"
    docker build -t medisync-backend:latest .
    
    # Build frontend
    echo -e "${YELLOW}Building frontend...${NC}"
    docker build -t medisync-frontend:latest ./medisync-frontend
    
    echo -e "${GREEN}✓${NC} Docker images built successfully"
}

# Function to deploy with Docker Compose
deploy_docker() {
    echo -e "\n${GREEN}Deploying with Docker Compose...${NC}"
    
    # Stop existing containers
    docker-compose down
    
    # Start services
    if [ "$ENVIRONMENT" == "production" ]; then
        docker-compose --profile production up -d
    else
        docker-compose up -d
    fi
    
    # Wait for services to be healthy
    echo -e "${YELLOW}Waiting for services to be healthy...${NC}"
    sleep 10
    
    # Run database migrations
    echo -e "${YELLOW}Running database migrations...${NC}"
    docker-compose exec backend flask db upgrade
    
    echo -e "${GREEN}✓${NC} Deployment completed successfully"
}

# Function to deploy to AWS
deploy_aws() {
    echo -e "\n${GREEN}Deploying to AWS...${NC}"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}✗${NC} AWS CLI is not installed"
        exit 1
    fi
    
    # Build and push to ECR
    echo -e "${YELLOW}Building and pushing to ECR...${NC}"
    
    # Get ECR login token
    aws ecr get-login-password --region ${AWS_REGION:-ap-south-1} | \
        docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION:-ap-south-1}.amazonaws.com
    
    # Tag and push images
    docker tag medisync-backend:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION:-ap-south-1}.amazonaws.com/medisync-backend:latest
    docker tag medisync-frontend:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION:-ap-south-1}.amazonaws.com/medisync-frontend:latest
    
    docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION:-ap-south-1}.amazonaws.com/medisync-backend:latest
    docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION:-ap-south-1}.amazonaws.com/medisync-frontend:latest
    
    # Deploy with ECS or EKS
    echo -e "${YELLOW}Deploying to ECS...${NC}"
    aws ecs update-service --cluster medisync-cluster --service medisync-backend --force-new-deployment
    aws ecs update-service --cluster medisync-cluster --service medisync-frontend --force-new-deployment
    
    echo -e "${GREEN}✓${NC} AWS deployment completed"
}

# Function to deploy to Azure
deploy_azure() {
    echo -e "\n${GREEN}Deploying to Azure...${NC}"
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        echo -e "${RED}✗${NC} Azure CLI is not installed"
        exit 1
    fi
    
    # Login to Azure Container Registry
    echo -e "${YELLOW}Logging in to Azure Container Registry...${NC}"
    az acr login --name ${AZURE_REGISTRY_NAME}
    
    # Tag and push images
    docker tag medisync-backend:latest ${AZURE_REGISTRY_NAME}.azurecr.io/medisync-backend:latest
    docker tag medisync-frontend:latest ${AZURE_REGISTRY_NAME}.azurecr.io/medisync-frontend:latest
    
    docker push ${AZURE_REGISTRY_NAME}.azurecr.io/medisync-backend:latest
    docker push ${AZURE_REGISTRY_NAME}.azurecr.io/medisync-frontend:latest
    
    # Deploy to Azure Container Instances or AKS
    echo -e "${YELLOW}Deploying to Azure Container Instances...${NC}"
    az container restart --resource-group medisync-rg --name medisync-backend
    az container restart --resource-group medisync-rg --name medisync-frontend
    
    echo -e "${GREEN}✓${NC} Azure deployment completed"
}

# Function to deploy to Heroku
deploy_heroku() {
    echo -e "\n${GREEN}Deploying to Heroku...${NC}"
    
    # Check Heroku CLI
    if ! command -v heroku &> /dev/null; then
        echo -e "${RED}✗${NC} Heroku CLI is not installed"
        exit 1
    fi
    
    # Login to Heroku Container Registry
    echo -e "${YELLOW}Logging in to Heroku Container Registry...${NC}"
    heroku container:login
    
    # Push backend
    echo -e "${YELLOW}Deploying backend to Heroku...${NC}"
    heroku container:push web -a medisync-backend
    heroku container:release web -a medisync-backend
    
    # Push frontend
    echo -e "${YELLOW}Deploying frontend to Heroku...${NC}"
    cd medisync-frontend
    heroku container:push web -a medisync-frontend
    heroku container:release web -a medisync-frontend
    cd ..
    
    # Run migrations
    heroku run flask db upgrade -a medisync-backend
    
    echo -e "${GREEN}✓${NC} Heroku deployment completed"
}

# Function to deploy to VPS
deploy_vps() {
    echo -e "\n${GREEN}Deploying to VPS...${NC}"
    
    # Check if SSH key exists
    if [ ! -f ~/.ssh/medisync_deploy ]; then
        echo -e "${RED}✗${NC} SSH key not found at ~/.ssh/medisync_deploy"
        exit 1
    fi
    
    # Build images locally
    build_docker
    
    # Save images
    echo -e "${YELLOW}Saving Docker images...${NC}"
    docker save medisync-backend:latest | gzip > medisync-backend.tar.gz
    docker save medisync-frontend:latest | gzip > medisync-frontend.tar.gz
    
    # Transfer to VPS
    echo -e "${YELLOW}Transferring to VPS...${NC}"
    scp -i ~/.ssh/medisync_deploy medisync-backend.tar.gz medisync-frontend.tar.gz docker-compose.yml ${VPS_USER}@${VPS_HOST}:/opt/medisync/
    
    # Deploy on VPS
    echo -e "${YELLOW}Deploying on VPS...${NC}"
    ssh -i ~/.ssh/medisync_deploy ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
        cd /opt/medisync
        docker load < medisync-backend.tar.gz
        docker load < medisync-frontend.tar.gz
        docker-compose down
        docker-compose up -d
        docker-compose exec backend flask db upgrade
ENDSSH
    
    # Cleanup
    rm medisync-backend.tar.gz medisync-frontend.tar.gz
    
    echo -e "${GREEN}✓${NC} VPS deployment completed"
}

# Function to run health checks
health_check() {
    echo -e "\n${GREEN}Running health checks...${NC}"
    
    # Check backend
    if curl -f http://localhost:5000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Backend is healthy"
    else
        echo -e "${RED}✗${NC} Backend health check failed"
    fi
    
    # Check frontend
    if curl -f http://localhost/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Frontend is healthy"
    else
        echo -e "${RED}✗${NC} Frontend health check failed"
    fi
    
    # Check database
    if docker-compose exec database mysqladmin ping -h localhost > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Database is healthy"
    else
        echo -e "${RED}✗${NC} Database health check failed"
    fi
}

# Main deployment logic
main() {
    check_prerequisites
    
    # Generate secrets if not set
    if [ -z "$SECRET_KEY" ]; then
        export SECRET_KEY=$(generate_secret)
        echo -e "${YELLOW}Generated SECRET_KEY: $SECRET_KEY${NC}"
    fi
    
    if [ -z "$JWT_SECRET_KEY" ]; then
        export JWT_SECRET_KEY=$(generate_secret)
        echo -e "${YELLOW}Generated JWT_SECRET_KEY: $JWT_SECRET_KEY${NC}"
    fi
    
    # Build Docker images
    build_docker
    
    # Deploy based on target
    case $TARGET in
        docker)
            deploy_docker
            ;;
        aws)
            deploy_aws
            ;;
        azure)
            deploy_azure
            ;;
        heroku)
            deploy_heroku
            ;;
        vps)
            deploy_vps
            ;;
        *)
            echo -e "${RED}Unknown deployment target: $TARGET${NC}"
            exit 1
            ;;
    esac
    
    # Run health checks
    health_check
    
    echo -e "\n${GREEN}🎉 Deployment completed successfully!${NC}"
    echo -e "Access the application at:"
    echo -e "  Frontend: ${YELLOW}http://localhost${NC}"
    echo -e "  Backend API: ${YELLOW}http://localhost:5000${NC}"
    echo -e "  API Docs: ${YELLOW}http://localhost:5000/docs${NC}"
}

# Run main function
main
