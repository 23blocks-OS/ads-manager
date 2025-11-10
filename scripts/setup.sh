#!/bin/bash

###############################################################################
# AI Ads Manager - Interactive Setup Script
#
# This script helps developers set up the entire development environment
# by collecting all required credentials and configuration.
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
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

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Ask for input with default value
ask_with_default() {
    local prompt=$1
    local default=$2
    local var_name=$3

    if [ -n "$default" ]; then
        read -p "$(echo -e ${BLUE}$prompt ${NC}[${GREEN}$default${NC}]: )" input
        eval $var_name="${input:-$default}"
    else
        read -p "$(echo -e ${BLUE}$prompt: ${NC})" input
        eval $var_name="$input"
    fi
}

# Ask for sensitive input (hidden)
ask_secret() {
    local prompt=$1
    local var_name=$2

    read -s -p "$(echo -e ${BLUE}$prompt: ${NC})" input
    echo ""
    eval $var_name="$input"
}

# Confirm action
confirm() {
    local prompt=$1
    read -p "$(echo -e ${YELLOW}$prompt [y/N]: ${NC})" -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

###############################################################################
# Welcome
###############################################################################

clear
print_header "AI Ads Manager - Interactive Setup"
echo "This script will guide you through setting up your development environment."
echo "You'll be asked for various API keys and configuration values."
echo ""
print_warning "Have your credentials ready from:"
echo "  • Google Cloud Console"
echo "  • Meta Developer Portal"
echo "  • LinkedIn Developer Portal"
echo "  • AWS Account"
echo "  • Stripe Dashboard"
echo ""

if ! confirm "Ready to begin setup?"; then
    echo "Setup cancelled."
    exit 0
fi

###############################################################################
# Check Prerequisites
###############################################################################

print_header "Checking Prerequisites"

# Check Node.js
if command_exists node; then
    NODE_VERSION=$(node --version)
    print_success "Node.js installed: $NODE_VERSION"
else
    print_error "Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check npm
if command_exists npm; then
    NPM_VERSION=$(npm --version)
    print_success "npm installed: $NPM_VERSION"
else
    print_error "npm is not installed."
    exit 1
fi

# Check Docker
if command_exists docker; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    print_success "Docker installed: $DOCKER_VERSION"
else
    print_warning "Docker not found. Docker is recommended for local development."
fi

# Check AWS CLI
if command_exists aws; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
    print_success "AWS CLI installed: $AWS_VERSION"
else
    print_warning "AWS CLI not found. Required for production deployment."
fi

# Check git
if command_exists git; then
    GIT_VERSION=$(git --version | cut -d' ' -f3)
    print_success "Git installed: $GIT_VERSION"
else
    print_error "Git is not installed."
    exit 1
fi

###############################################################################
# Environment Selection
###############################################################################

print_header "Environment Configuration"

echo "Select environment to configure:"
echo "  1) Development (local)"
echo "  2) Staging"
echo "  3) Production"
echo ""
read -p "Enter choice [1-3]: " ENV_CHOICE

case $ENV_CHOICE in
    1) ENVIRONMENT="development" ;;
    2) ENVIRONMENT="staging" ;;
    3) ENVIRONMENT="production" ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

print_success "Configuring for: $ENVIRONMENT"

###############################################################################
# Database Configuration
###############################################################################

print_header "Database Configuration"

if [ "$ENVIRONMENT" == "development" ]; then
    DB_HOST="localhost"
    DB_PORT="5432"
    DB_NAME="ads_manager"
    DB_USER="adsmanager"
    ask_secret "Database password" DB_PASSWORD
else
    ask_with_default "Database host" "" DB_HOST
    ask_with_default "Database port" "5432" DB_PORT
    ask_with_default "Database name" "ads_manager" DB_NAME
    ask_with_default "Database username" "adsmanager" DB_USER
    ask_secret "Database password" DB_PASSWORD
fi

DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME"
print_success "Database URL configured"

###############################################################################
# Redis Configuration
###############################################################################

print_header "Redis Configuration"

if [ "$ENVIRONMENT" == "development" ]; then
    REDIS_HOST="localhost"
    REDIS_PORT="6379"
    REDIS_PASSWORD=""
else
    ask_with_default "Redis host" "" REDIS_HOST
    ask_with_default "Redis port" "6379" REDIS_PORT
    ask_secret "Redis password (leave empty if none)" REDIS_PASSWORD
fi

print_success "Redis configured"

###############################################################################
# JWT Configuration
###############################################################################

print_header "JWT Configuration"

ask_with_default "JWT secret (or generate random)" "$(openssl rand -base64 32)" JWT_SECRET
ask_with_default "JWT expiration" "7d" JWT_EXPIRATION

print_success "JWT configured"

###############################################################################
# OpenAI Configuration
###############################################################################

print_header "OpenAI Configuration"

echo "Get your API key from: https://platform.openai.com/api-keys"
ask_secret "OpenAI API key (sk-...)" OPENAI_API_KEY

print_success "OpenAI configured"

###############################################################################
# Anthropic Claude Configuration
###############################################################################

print_header "Anthropic Claude Configuration (Optional)"

if confirm "Do you want to configure Anthropic Claude?"; then
    echo "Get your API key from: https://console.anthropic.com/"
    ask_secret "Anthropic API key (sk-ant-...)" ANTHROPIC_API_KEY
    print_success "Anthropic configured"
else
    ANTHROPIC_API_KEY=""
    print_info "Skipping Anthropic configuration"
fi

###############################################################################
# Google Ads Configuration
###############################################################################

print_header "Google Ads Configuration (Optional)"

if confirm "Do you want to configure Google Ads?"; then
    echo "Follow: docs/integrations/GOOGLE_ADS_SETUP.md"
    ask_with_default "Client ID" "" GOOGLE_ADS_CLIENT_ID
    ask_secret "Client Secret" GOOGLE_ADS_CLIENT_SECRET
    ask_secret "Developer Token" GOOGLE_ADS_DEVELOPER_TOKEN
    ask_secret "Refresh Token" GOOGLE_ADS_REFRESH_TOKEN
    ask_with_default "Customer ID (no dashes)" "" GOOGLE_ADS_CUSTOMER_ID
    print_success "Google Ads configured"
else
    GOOGLE_ADS_CLIENT_ID=""
    GOOGLE_ADS_CLIENT_SECRET=""
    GOOGLE_ADS_DEVELOPER_TOKEN=""
    GOOGLE_ADS_REFRESH_TOKEN=""
    GOOGLE_ADS_CUSTOMER_ID=""
    print_info "Skipping Google Ads configuration"
fi

###############################################################################
# Meta Ads Configuration
###############################################################################

print_header "Meta Ads Configuration (Optional)"

if confirm "Do you want to configure Meta (Facebook) Ads?"; then
    echo "Follow: docs/integrations/META_ADS_SETUP.md"
    ask_with_default "App ID" "" META_APP_ID
    ask_secret "App Secret" META_APP_SECRET
    ask_secret "Access Token" META_ACCESS_TOKEN
    ask_with_default "Ad Account ID (act_...)" "" META_AD_ACCOUNT_ID
    print_success "Meta Ads configured"
else
    META_APP_ID=""
    META_APP_SECRET=""
    META_ACCESS_TOKEN=""
    META_AD_ACCOUNT_ID=""
    print_info "Skipping Meta Ads configuration"
fi

###############################################################################
# LinkedIn Ads Configuration
###############################################################################

print_header "LinkedIn Ads Configuration (Optional)"

if confirm "Do you want to configure LinkedIn Ads?"; then
    echo "Follow: docs/integrations/LINKEDIN_ADS_SETUP.md"
    ask_with_default "Client ID" "" LINKEDIN_CLIENT_ID
    ask_secret "Client Secret" LINKEDIN_CLIENT_SECRET
    ask_secret "Access Token" LINKEDIN_ACCESS_TOKEN
    ask_with_default "Ad Account ID" "" LINKEDIN_AD_ACCOUNT_ID
    print_success "LinkedIn Ads configured"
else
    LINKEDIN_CLIENT_ID=""
    LINKEDIN_CLIENT_SECRET=""
    LINKEDIN_ACCESS_TOKEN=""
    LINKEDIN_AD_ACCOUNT_ID=""
    print_info "Skipping LinkedIn Ads configuration"
fi

###############################################################################
# Stripe Configuration
###############################################################################

print_header "Stripe Configuration (Optional)"

if confirm "Do you want to configure Stripe?"; then
    echo "Get your keys from: https://dashboard.stripe.com/apikeys"
    ask_secret "Secret Key (sk_test_... or sk_live_...)" STRIPE_SECRET_KEY
    ask_with_default "Publishable Key (pk_test_... or pk_live_...)" "" STRIPE_PUBLISHABLE_KEY
    ask_secret "Webhook Secret (whsec_...)" STRIPE_WEBHOOK_SECRET
    print_success "Stripe configured"
else
    STRIPE_SECRET_KEY=""
    STRIPE_PUBLISHABLE_KEY=""
    STRIPE_WEBHOOK_SECRET=""
    print_info "Skipping Stripe configuration"
fi

###############################################################################
# AWS Configuration
###############################################################################

print_header "AWS Configuration"

if [ "$ENVIRONMENT" != "development" ]; then
    ask_with_default "AWS Region" "us-east-1" AWS_REGION
    ask_with_default "AWS Profile Name" "default" AWS_PROFILE
    ask_secret "AWS Access Key ID" AWS_ACCESS_KEY_ID
    ask_secret "AWS Secret Access Key" AWS_SECRET_ACCESS_KEY
    ask_with_default "S3 Bucket for assets" "ads-manager-assets-$ENVIRONMENT" AWS_S3_BUCKET
    print_success "AWS configured"
else
    AWS_REGION="us-east-1"
    AWS_PROFILE="default"
    AWS_ACCESS_KEY_ID=""
    AWS_SECRET_ACCESS_KEY=""
    AWS_S3_BUCKET="ads-manager-assets-dev"
fi

###############################################################################
# Twilio Configuration
###############################################################################

print_header "Twilio Configuration (Optional)"

if confirm "Do you want to configure Twilio for SMS?"; then
    echo "Get credentials from: https://console.twilio.com/"
    ask_secret "Account SID" TWILIO_ACCOUNT_SID
    ask_secret "Auth Token" TWILIO_AUTH_TOKEN
    ask_with_default "Phone Number (+1...)" "" TWILIO_PHONE_NUMBER
    print_success "Twilio configured"
else
    TWILIO_ACCOUNT_SID=""
    TWILIO_AUTH_TOKEN=""
    TWILIO_PHONE_NUMBER=""
    print_info "Skipping Twilio configuration"
fi

###############################################################################
# Frontend Configuration
###############################################################################

print_header "Frontend Configuration"

if [ "$ENVIRONMENT" == "development" ]; then
    FRONTEND_URL="http://localhost:3000"
    API_URL="http://localhost:3001/api/v1"
else
    ask_with_default "Frontend URL (https://...)" "" FRONTEND_URL
    ask_with_default "API URL (https://.../api/v1)" "" API_URL
fi

print_success "Frontend configured"

###############################################################################
# Write Backend .env File
###############################################################################

print_header "Generating Configuration Files"

BACKEND_ENV_FILE="backend/.env"

cat > $BACKEND_ENV_FILE << EOF
# Environment
NODE_ENV=$ENVIRONMENT
PORT=3001
API_PREFIX=api/v1

# Database
DATABASE_URL=$DATABASE_URL

# Redis
REDIS_HOST=$REDIS_HOST
REDIS_PORT=$REDIS_PORT
REDIS_PASSWORD=$REDIS_PASSWORD

# JWT
JWT_SECRET=$JWT_SECRET
JWT_EXPIRATION=$JWT_EXPIRATION
JWT_REFRESH_SECRET=$(openssl rand -base64 32)
JWT_REFRESH_EXPIRATION=30d

# OpenAI
OPENAI_API_KEY=$OPENAI_API_KEY

# Anthropic Claude
ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY

# Google Ads
GOOGLE_ADS_CLIENT_ID=$GOOGLE_ADS_CLIENT_ID
GOOGLE_ADS_CLIENT_SECRET=$GOOGLE_ADS_CLIENT_SECRET
GOOGLE_ADS_DEVELOPER_TOKEN=$GOOGLE_ADS_DEVELOPER_TOKEN
GOOGLE_ADS_REFRESH_TOKEN=$GOOGLE_ADS_REFRESH_TOKEN
GOOGLE_ADS_CUSTOMER_ID=$GOOGLE_ADS_CUSTOMER_ID

# Meta (Facebook) Ads
META_APP_ID=$META_APP_ID
META_APP_SECRET=$META_APP_SECRET
META_ACCESS_TOKEN=$META_ACCESS_TOKEN
META_AD_ACCOUNT_ID=$META_AD_ACCOUNT_ID

# LinkedIn Ads
LINKEDIN_CLIENT_ID=$LINKEDIN_CLIENT_ID
LINKEDIN_CLIENT_SECRET=$LINKEDIN_CLIENT_SECRET
LINKEDIN_ACCESS_TOKEN=$LINKEDIN_ACCESS_TOKEN
LINKEDIN_AD_ACCOUNT_ID=$LINKEDIN_AD_ACCOUNT_ID

# Stripe
STRIPE_SECRET_KEY=$STRIPE_SECRET_KEY
STRIPE_PUBLISHABLE_KEY=$STRIPE_PUBLISHABLE_KEY
STRIPE_WEBHOOK_SECRET=$STRIPE_WEBHOOK_SECRET

# AWS
AWS_REGION=$AWS_REGION
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
AWS_S3_BUCKET=$AWS_S3_BUCKET

# Twilio
TWILIO_ACCOUNT_SID=$TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN=$TWILIO_AUTH_TOKEN
TWILIO_PHONE_NUMBER=$TWILIO_PHONE_NUMBER

# Frontend URL
FRONTEND_URL=$FRONTEND_URL

# Rate Limiting
RATE_LIMIT_TTL=60
RATE_LIMIT_MAX=100

# Logging
LOG_LEVEL=debug

# Encryption Key (for encrypting credentials in database)
ENCRYPTION_KEY=$(openssl rand -hex 32)
EOF

print_success "Backend .env file created: $BACKEND_ENV_FILE"

###############################################################################
# Write Frontend .env File
###############################################################################

FRONTEND_ENV_FILE="frontend/.env.local"

cat > $FRONTEND_ENV_FILE << EOF
NEXT_PUBLIC_API_URL=$API_URL
EOF

print_success "Frontend .env file created: $FRONTEND_ENV_FILE"

###############################################################################
# GitHub Secrets Setup
###############################################################################

print_header "GitHub Secrets Setup (Optional)"

if command_exists gh && confirm "Do you want to set up GitHub secrets for CI/CD?"; then
    print_info "Setting up GitHub secrets..."

    # Check if gh is authenticated
    if ! gh auth status >/dev/null 2>&1; then
        print_warning "GitHub CLI not authenticated. Running 'gh auth login'..."
        gh auth login
    fi

    # Set secrets
    echo "$AWS_ACCESS_KEY_ID" | gh secret set AWS_ACCESS_KEY_ID
    echo "$AWS_SECRET_ACCESS_KEY" | gh secret set AWS_SECRET_ACCESS_KEY
    echo "$AWS_REGION" | gh secret set AWS_REGION
    echo "$DATABASE_URL" | gh secret set DATABASE_URL
    echo "$OPENAI_API_KEY" | gh secret set OPENAI_API_KEY
    echo "$JWT_SECRET" | gh secret set JWT_SECRET

    if [ -n "$GOOGLE_ADS_CLIENT_SECRET" ]; then
        echo "$GOOGLE_ADS_CLIENT_SECRET" | gh secret set GOOGLE_ADS_CLIENT_SECRET
    fi

    if [ -n "$META_APP_SECRET" ]; then
        echo "$META_APP_SECRET" | gh secret set META_APP_SECRET
    fi

    if [ -n "$STRIPE_SECRET_KEY" ]; then
        echo "$STRIPE_SECRET_KEY" | gh secret set STRIPE_SECRET_KEY
    fi

    print_success "GitHub secrets configured"
else
    print_info "Skipping GitHub secrets setup"
fi

###############################################################################
# Install Dependencies
###############################################################################

print_header "Installing Dependencies"

if confirm "Install backend dependencies?"; then
    cd backend
    npm install
    print_success "Backend dependencies installed"
    cd ..
fi

if confirm "Install frontend dependencies?"; then
    cd frontend
    npm install
    print_success "Frontend dependencies installed"
    cd ..
fi

###############################################################################
# Database Setup
###############################################################################

print_header "Database Setup"

if [ "$ENVIRONMENT" == "development" ] && confirm "Start database with Docker?"; then
    docker-compose up -d postgres redis
    sleep 5
    print_success "Database and Redis started"

    if confirm "Run database migrations?"; then
        cd backend
        npx prisma generate
        npx prisma migrate dev
        print_success "Database migrations completed"
        cd ..
    fi
fi

###############################################################################
# Summary
###############################################################################

print_header "Setup Complete!"

echo "Configuration files created:"
echo "  • $BACKEND_ENV_FILE"
echo "  • $FRONTEND_ENV_FILE"
echo ""
echo "Next steps:"
echo ""
echo "1. Start the application:"
if [ "$ENVIRONMENT" == "development" ]; then
    echo "   docker-compose up -d"
    echo ""
    echo "   Or start services separately:"
    echo "   cd backend && npm run start:dev"
    echo "   cd frontend && npm run dev"
else
    echo "   Deploy to $ENVIRONMENT using GitHub Actions or:"
    echo "   cd terraform/environments/$ENVIRONMENT"
    echo "   terraform apply"
fi
echo ""
echo "2. Access the application:"
echo "   Frontend: $FRONTEND_URL"
echo "   Backend API: ${API_URL%/api/v1}"
echo "   API Docs: ${API_URL%/api/v1}/api/docs"
echo ""
echo "3. Review documentation:"
echo "   • docs/GETTING_STARTED.md"
echo "   • docs/DEPLOYMENT.md"
echo "   • docs/integrations/"
echo ""

print_success "🎉 Setup completed successfully!"
echo ""
