# Automation Scripts

This directory contains scripts to help you set up, deploy, and manage the AI Ads Manager platform.

## Available Scripts

### 1. Interactive Setup (`setup.sh`)

**Purpose**: Guides you through setting up your development environment by collecting all required credentials and generating configuration files.

**Usage**:
```bash
./scripts/setup.sh
```

**What it does**:
- Checks prerequisites (Node.js, Docker, AWS CLI, etc.)
- Prompts for environment selection (dev/staging/prod)
- Collects database credentials
- Collects API keys (OpenAI, Anthropic, Google Ads, Meta Ads, LinkedIn Ads)
- Collects AWS and payment provider credentials
- Generates `.env` files for backend and frontend
- Optionally sets up GitHub secrets
- Optionally installs dependencies
- Optionally starts database with Docker

**Interactive prompts**:
- Database configuration
- Redis configuration
- JWT secrets
- OpenAI API key
- Anthropic API key (optional)
- Google Ads credentials (optional)
- Meta Ads credentials (optional)
- LinkedIn Ads credentials (optional)
- Stripe credentials (optional)
- AWS configuration
- Twilio credentials (optional)

**Output**:
- `backend/.env` - Backend environment variables
- `frontend/.env.local` - Frontend environment variables

**Example**:
```bash
$ ./scripts/setup.sh

═══════════════════════════════════════════════════════════════
  AI Ads Manager - Interactive Setup
═══════════════════════════════════════════════════════════════

This script will guide you through setting up your development environment.
...
```

---

### 2. Deploy to AWS (`deploy.sh`)

**Purpose**: Builds Docker images and deploys the application to AWS ECS.

**Usage**:
```bash
./scripts/deploy.sh <environment> [options]
```

**Environments**:
- `dev` or `development` - Development environment
- `staging` - Staging environment
- `prod` or `production` - Production environment

**Options**:
- `--skip-build` - Skip Docker build and push (use existing images)
- `--skip-migration` - Skip database migration

**Examples**:
```bash
# Deploy to development
./scripts/deploy.sh dev

# Deploy to staging (skip migration)
./scripts/deploy.sh staging --skip-migration

# Deploy to production (requires confirmation)
./scripts/deploy.sh prod

# Re-deploy without rebuilding
./scripts/deploy.sh dev --skip-build
```

**What it does**:
1. Validates environment and credentials
2. Logs in to Amazon ECR
3. Builds Docker images for backend and frontend
4. Tags images with commit SHA and `latest`
5. Pushes images to ECR
6. Updates ECS services (force new deployment)
7. Waits for services to stabilize
8. Runs database migrations
9. Shows deployment summary

**Production safety**:
- Requires typing "deploy-prod" to confirm
- Extra validation steps
- Rollback support

**Prerequisites**:
- AWS CLI configured with appropriate credentials
- Docker installed and running
- ECR repositories created
- ECS cluster and services exist

---

### 3. Setup GitHub Secrets (`setup-github-secrets.sh`)

**Purpose**: Automatically uploads secrets from your `.env` file to GitHub for use in CI/CD workflows.

**Usage**:
```bash
./scripts/setup-github-secrets.sh
```

**Interactive prompts**:
1. Select environment(s) to configure
2. Enter environment-specific URLs

**What it does**:
- Reads `backend/.env` file
- Uploads secrets to GitHub using `gh` CLI
- Sets environment-specific secrets (DATABASE_URL, REDIS_HOST, API_URL)
- Sets common secrets (AWS credentials, API keys, etc.)

**Secrets uploaded**:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `JWT_SECRET`
- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `GOOGLE_ADS_CLIENT_SECRET`
- `META_APP_SECRET`
- `LINKEDIN_CLIENT_SECRET`
- `STRIPE_SECRET_KEY`
- And more...

**Environment-specific secrets**:
- `DEV_DATABASE_URL`, `STAGING_DATABASE_URL`, `PROD_DATABASE_URL`
- `DEV_REDIS_HOST`, `STAGING_REDIS_HOST`, `PROD_REDIS_HOST`
- `DEV_API_URL`, `STAGING_API_URL`, `PROD_API_URL`

**Prerequisites**:
- GitHub CLI (`gh`) installed
- Authenticated with GitHub (`gh auth login`)
- `backend/.env` file exists

**Example**:
```bash
$ ./scripts/setup-github-secrets.sh

═══════════════════════════════════════════════════════════════
  GitHub Secrets Setup
═══════════════════════════════════════════════════════════════

Select environment:
  1) Development
  2) Staging
  3) Production
  4) All environments

Enter choice [1-4]: 4
...
✓ AWS_ACCESS_KEY_ID set
✓ JWT_SECRET set
✓ OPENAI_API_KEY set
...
```

---

## Typical Workflow

### First Time Setup

1. **Run interactive setup**:
   ```bash
   ./scripts/setup.sh
   ```
   - Select "Development"
   - Enter all required credentials
   - Let it install dependencies and start database

2. **Set up GitHub secrets** (for CI/CD):
   ```bash
   ./scripts/setup-github-secrets.sh
   ```
   - Select "All environments"
   - Enter environment-specific URLs

3. **Start development**:
   ```bash
   # Backend
   cd backend && npm run start:dev

   # Frontend (in another terminal)
   cd frontend && npm run dev
   ```

### Deploying Changes

**Development** (automatic with GitHub Actions):
```bash
git push origin dev
# GitHub Actions automatically deploys
```

**Staging** (automatic with GitHub Actions):
```bash
git push origin staging
# GitHub Actions automatically deploys
```

**Production** (manual script or GitHub Actions):
```bash
# Option 1: Manual deployment
./scripts/deploy.sh prod

# Option 2: GitHub Actions (requires confirmation)
git push origin main
# Or create a tag:
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

### Quick Re-deploy (without rebuilding)

```bash
# Use existing images, just restart services
./scripts/deploy.sh dev --skip-build --skip-migration
```

---

## Troubleshooting

### "Command not found" error

Make sure scripts are executable:
```bash
chmod +x scripts/*.sh
```

### GitHub CLI not authenticated

```bash
gh auth login
```

### AWS CLI not configured

```bash
aws configure
```

### Docker build fails

Check Docker is running:
```bash
docker ps
```

### ECR login fails

Ensure AWS credentials are correct:
```bash
aws sts get-caller-identity
```

### ECS deployment fails

Check ECS cluster and services exist:
```bash
aws ecs describe-clusters --clusters ads-manager-development-cluster
aws ecs describe-services --cluster ads-manager-development-cluster --services ads-manager-development-backend
```

---

## Script Locations

All scripts are in the `scripts/` directory:

```
scripts/
├── README.md                    # This file
├── setup.sh                     # Interactive environment setup
├── deploy.sh                    # AWS ECS deployment
└── setup-github-secrets.sh      # GitHub secrets configuration
```

---

## Environment Variables Reference

See `backend/.env.example` for a complete list of required environment variables.

**Essential variables**:
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_HOST`, `REDIS_PORT` - Redis connection
- `JWT_SECRET` - JWT signing secret
- `OPENAI_API_KEY` - OpenAI API key (required for AI features)

**Ad platform credentials** (optional for development):
- Google Ads: `GOOGLE_ADS_CLIENT_ID`, `GOOGLE_ADS_CLIENT_SECRET`, etc.
- Meta Ads: `META_APP_ID`, `META_APP_SECRET`, etc.
- LinkedIn Ads: `LINKEDIN_CLIENT_ID`, `LINKEDIN_CLIENT_SECRET`, etc.

**AWS credentials** (required for production):
- `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- `AWS_S3_BUCKET`

---

## Best Practices

1. **Never commit `.env` files** - They're in `.gitignore`
2. **Use separate credentials per environment** - Don't reuse production keys in development
3. **Rotate secrets regularly** - Especially API keys and database passwords
4. **Test in development first** - Always test changes locally before deploying
5. **Use GitHub Actions for consistency** - Manual deployments are for emergencies
6. **Monitor deployments** - Check CloudWatch logs after deploying
7. **Keep scripts updated** - If you modify deployment process, update these scripts

---

## Security Notes

- Scripts handle sensitive data (passwords, API keys)
- Secrets are never logged or displayed in plain text
- GitHub secrets are encrypted at rest
- AWS Secrets Manager is used in production
- Credentials in `.env` files are only for local development

---

## Getting Help

If you encounter issues:

1. Check script output for specific error messages
2. Review prerequisites in this README
3. Check documentation in `docs/` folder
4. Review GitHub Actions logs for CI/CD issues
5. Check AWS CloudWatch logs for runtime issues

**Documentation**:
- [Getting Started](../docs/GETTING_STARTED.md)
- [Deployment Guide](../docs/DEPLOYMENT.md)
- [Integration Guides](../docs/integrations/)

---

**Last Updated**: 2024-01-10
