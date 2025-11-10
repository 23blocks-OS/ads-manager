#!/bin/bash

###############################################################################
# AI Ads Manager - Deployment Script
#
# Deploy the application to AWS ECS using docker images
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <environment> [--skip-build] [--skip-migration]"
    echo ""
    echo "Environments:"
    echo "  dev        - Development environment"
    echo "  staging    - Staging environment"
    echo "  prod       - Production environment"
    echo ""
    echo "Options:"
    echo "  --skip-build     - Skip Docker build and push"
    echo "  --skip-migration - Skip database migration"
    echo ""
    exit 1
fi

ENVIRONMENT=$1
SKIP_BUILD=false
SKIP_MIGRATION=false

# Parse options
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-migration)
            SKIP_MIGRATION=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Set environment-specific variables
case $ENVIRONMENT in
    dev|development)
        ENV="development"
        AWS_REGION="us-east-1"
        ECS_CLUSTER="ads-manager-development-cluster"
        ECS_SERVICE_BACKEND="ads-manager-development-backend"
        ECS_SERVICE_FRONTEND="ads-manager-development-frontend"
        ECR_REPO_BACKEND="ads-manager/development/backend"
        ECR_REPO_FRONTEND="ads-manager/development/frontend"
        ;;
    staging)
        ENV="staging"
        AWS_REGION="us-east-1"
        ECS_CLUSTER="ads-manager-staging-cluster"
        ECS_SERVICE_BACKEND="ads-manager-staging-backend"
        ECS_SERVICE_FRONTEND="ads-manager-staging-frontend"
        ECR_REPO_BACKEND="ads-manager/staging/backend"
        ECR_REPO_FRONTEND="ads-manager/staging/frontend"
        ;;
    prod|production)
        ENV="production"
        AWS_REGION="us-east-1"
        ECS_CLUSTER="ads-manager-production-cluster"
        ECS_SERVICE_BACKEND="ads-manager-production-backend"
        ECS_SERVICE_FRONTEND="ads-manager-production-frontend"
        ECR_REPO_BACKEND="ads-manager/production/backend"
        ECR_REPO_FRONTEND="ads-manager/production/frontend"

        # Extra confirmation for production
        echo -e "${YELLOW}⚠ WARNING: You are about to deploy to PRODUCTION!${NC}"
        read -p "Type 'deploy-prod' to confirm: " CONFIRM
        if [ "$CONFIRM" != "deploy-prod" ]; then
            echo "Deployment cancelled."
            exit 1
        fi
        ;;
    *)
        print_error "Invalid environment: $ENVIRONMENT"
        exit 1
        ;;
esac

print_header "Deploying to $ENV"

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
print_info "AWS Account: $ACCOUNT_ID"
print_info "Region: $AWS_REGION"

# Login to ECR
print_header "Logging in to Amazon ECR"
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
print_success "Logged in to ECR"

if [ "$SKIP_BUILD" = false ]; then
    # Build and push backend
    print_header "Building Backend Image"

    docker build \
        -t $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_BACKEND:latest \
        -t $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_BACKEND:$(git rev-parse --short HEAD) \
        -f backend/Dockerfile \
        backend/

    print_success "Backend image built"

    print_info "Pushing backend image to ECR..."
    docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_BACKEND:latest
    docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_BACKEND:$(git rev-parse --short HEAD)
    print_success "Backend image pushed"

    # Build and push frontend
    print_header "Building Frontend Image"

    docker build \
        -t $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_FRONTEND:latest \
        -t $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_FRONTEND:$(git rev-parse --short HEAD) \
        -f frontend/Dockerfile \
        frontend/

    print_success "Frontend image built"

    print_info "Pushing frontend image to ECR..."
    docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_FRONTEND:latest
    docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_FRONTEND:$(git rev-parse --short HEAD)
    print_success "Frontend image pushed"
else
    print_info "Skipping Docker build (--skip-build)"
fi

# Update ECS services
print_header "Updating ECS Services"

print_info "Updating backend service..."
aws ecs update-service \
    --cluster $ECS_CLUSTER \
    --service $ECS_SERVICE_BACKEND \
    --force-new-deployment \
    --region $AWS_REGION \
    > /dev/null

print_success "Backend service updated"

print_info "Updating frontend service..."
aws ecs update-service \
    --cluster $ECS_CLUSTER \
    --service $ECS_SERVICE_FRONTEND \
    --force-new-deployment \
    --region $AWS_REGION \
    > /dev/null

print_success "Frontend service updated"

# Wait for services to stabilize
print_header "Waiting for Services to Stabilize"

print_info "This may take a few minutes..."
aws ecs wait services-stable \
    --cluster $ECS_CLUSTER \
    --services $ECS_SERVICE_BACKEND $ECS_SERVICE_FRONTEND \
    --region $AWS_REGION

print_success "Services are stable"

# Run database migrations
if [ "$SKIP_MIGRATION" = false ]; then
    print_header "Running Database Migrations"

    # Get a running task
    TASK_ARN=$(aws ecs list-tasks \
        --cluster $ECS_CLUSTER \
        --service-name $ECS_SERVICE_BACKEND \
        --desired-status RUNNING \
        --region $AWS_REGION \
        --query 'taskArns[0]' \
        --output text)

    if [ "$TASK_ARN" != "None" ] && [ -n "$TASK_ARN" ]; then
        print_info "Running migrations on task: ${TASK_ARN##*/}"

        aws ecs execute-command \
            --cluster $ECS_CLUSTER \
            --task $TASK_ARN \
            --container backend \
            --interactive \
            --command "npx prisma migrate deploy" \
            --region $AWS_REGION

        print_success "Database migrations completed"
    else
        print_info "No running tasks found. Migrations will run on first task start."
    fi
else
    print_info "Skipping database migration (--skip-migration)"
fi

# Deployment summary
print_header "Deployment Complete!"

echo "Environment: $ENV"
echo "Cluster: $ECS_CLUSTER"
echo "Backend Service: $ECS_SERVICE_BACKEND"
echo "Frontend Service: $ECS_SERVICE_FRONTEND"
echo "Commit: $(git rev-parse --short HEAD)"
echo ""

print_success "🎉 Deployment successful!"
echo ""
echo "Check service status:"
echo "  aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE_BACKEND"
echo ""
echo "View logs:"
echo "  aws logs tail /ecs/ads-manager-$ENV-backend --follow"
echo ""
