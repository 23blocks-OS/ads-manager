#!/bin/bash

###############################################################################
# Setup GitHub Secrets
#
# This script reads your .env file and creates GitHub secrets for CI/CD
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is not installed"
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    print_info "Not authenticated with GitHub. Running 'gh auth login'..."
    gh auth login
fi

print_header "GitHub Secrets Setup"

# Ask for environment
echo "Select environment:"
echo "  1) Development"
echo "  2) Staging"
echo "  3) Production"
echo "  4) All environments"
echo ""
read -p "Enter choice [1-4]: " ENV_CHOICE

case $ENV_CHOICE in
    1) ENVIRONMENTS=("dev") ;;
    2) ENVIRONMENTS=("staging") ;;
    3) ENVIRONMENTS=("prod") ;;
    4) ENVIRONMENTS=("dev" "staging" "prod") ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

# Read .env file
if [ ! -f "backend/.env" ]; then
    print_error "backend/.env file not found"
    echo "Run ./scripts/setup.sh first to create environment configuration"
    exit 1
fi

print_info "Reading backend/.env file..."

# Define secrets to upload
# Format: SECRET_NAME:ENV_VAR_NAME
SECRETS=(
    "AWS_ACCESS_KEY_ID:AWS_ACCESS_KEY_ID"
    "AWS_SECRET_ACCESS_KEY:AWS_SECRET_ACCESS_KEY"
    "AWS_REGION:AWS_REGION"
    "JWT_SECRET:JWT_SECRET"
    "OPENAI_API_KEY:OPENAI_API_KEY"
    "ANTHROPIC_API_KEY:ANTHROPIC_API_KEY"
    "GOOGLE_ADS_CLIENT_SECRET:GOOGLE_ADS_CLIENT_SECRET"
    "GOOGLE_ADS_DEVELOPER_TOKEN:GOOGLE_ADS_DEVELOPER_TOKEN"
    "GOOGLE_ADS_REFRESH_TOKEN:GOOGLE_ADS_REFRESH_TOKEN"
    "META_APP_SECRET:META_APP_SECRET"
    "META_ACCESS_TOKEN:META_ACCESS_TOKEN"
    "LINKEDIN_CLIENT_SECRET:LINKEDIN_CLIENT_SECRET"
    "LINKEDIN_ACCESS_TOKEN:LINKEDIN_ACCESS_TOKEN"
    "STRIPE_SECRET_KEY:STRIPE_SECRET_KEY"
    "STRIPE_WEBHOOK_SECRET:STRIPE_WEBHOOK_SECRET"
    "TWILIO_AUTH_TOKEN:TWILIO_AUTH_TOKEN"
)

# Load .env file
export $(grep -v '^#' backend/.env | xargs)

# Upload secrets
for env in "${ENVIRONMENTS[@]}"; do
    print_header "Setting up $env secrets"

    # Environment-specific secrets
    case $env in
        dev)
            ENV_PREFIX="DEV"
            ;;
        staging)
            ENV_PREFIX="STAGING"
            ;;
        prod)
            ENV_PREFIX="PROD"
            ;;
    esac

    # Database URL (environment-specific)
    if [ -n "$DATABASE_URL" ]; then
        echo "$DATABASE_URL" | gh secret set "${ENV_PREFIX}_DATABASE_URL" 2>/dev/null && \
            print_success "${ENV_PREFIX}_DATABASE_URL set" || \
            print_error "Failed to set ${ENV_PREFIX}_DATABASE_URL"
    fi

    # Redis Host (environment-specific)
    if [ -n "$REDIS_HOST" ]; then
        echo "$REDIS_HOST" | gh secret set "${ENV_PREFIX}_REDIS_HOST" 2>/dev/null && \
            print_success "${ENV_PREFIX}_REDIS_HOST set" || \
            print_error "Failed to set ${ENV_PREFIX}_REDIS_HOST"
    fi

    # API URL (environment-specific)
    read -p "Enter ${ENV_PREFIX} API URL (e.g., https://${env}-api.yourdomain.com/api/v1): " API_URL
    if [ -n "$API_URL" ]; then
        echo "$API_URL" | gh secret set "${ENV_PREFIX}_API_URL" 2>/dev/null && \
            print_success "${ENV_PREFIX}_API_URL set" || \
            print_error "Failed to set ${ENV_PREFIX}_API_URL"
    fi
done

# Common secrets (shared across environments)
print_header "Setting up common secrets"

for secret_def in "${SECRETS[@]}"; do
    SECRET_NAME=$(echo $secret_def | cut -d: -f1)
    ENV_VAR=$(echo $secret_def | cut -d: -f2)

    # Get value from environment
    VALUE="${!ENV_VAR}"

    if [ -n "$VALUE" ] && [ "$VALUE" != "" ]; then
        echo "$VALUE" | gh secret set "$SECRET_NAME" 2>/dev/null && \
            print_success "$SECRET_NAME set" || \
            print_error "Failed to set $SECRET_NAME"
    else
        print_info "Skipping $SECRET_NAME (not set in .env)"
    fi
done

print_header "Setup Complete!"

print_info "View secrets in GitHub:"
echo "  https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/settings/secrets/actions"

echo ""
print_success "🎉 GitHub secrets configured!"
echo ""
echo "You can now use GitHub Actions to deploy to:"
for env in "${ENVIRONMENTS[@]}"; do
    echo "  • $env environment"
done
echo ""
