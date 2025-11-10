# AWS ECS Task Definitions

This directory contains ECS task definition templates for all environments.

## Files

- `task-definition-backend-dev.json` - Development backend task definition
- `task-definition-frontend-dev.json` - Development frontend task definition
- `task-definition-backend-staging.json` - Staging backend task definition
- `task-definition-frontend-staging.json` - Staging frontend task definition
- `task-definition-backend-prod.json` - Production backend task definition
- `task-definition-frontend-prod.json` - Production frontend task definition

## Setup Instructions

### 1. Replace Placeholders

Before using these files, replace the following placeholders:

- `ACCOUNT_ID` - Your AWS account ID
- Update `executionRoleArn` and `taskRoleArn` with actual ARNs
- Update secrets ARNs in `secrets` section
- Update log group names if different

### 2. Create IAM Roles

Create the required IAM roles:

```bash
# Execution Role (allows ECS to pull images and write logs)
aws iam create-role \
  --role-name ads-manager-dev-ecs-execution-role \
  --assume-role-policy-document file://trust-policy.json

aws iam attach-role-policy \
  --role-name ads-manager-dev-ecs-execution-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# Task Role (allows containers to access AWS services)
aws iam create-role \
  --role-name ads-manager-dev-ecs-task-role \
  --assume-role-policy-document file://trust-policy.json
```

### 3. Create Secrets in Secrets Manager

```bash
# Database URL
aws secretsmanager create-secret \
  --name ads-manager/dev/database-url \
  --secret-string "postgresql://user:pass@host:5432/dbname"

# Redis Host
aws secretsmanager create-secret \
  --name ads-manager/dev/redis-host \
  --secret-string "your-redis-host.cache.amazonaws.com"

# JWT Secret
aws secretsmanager create-secret \
  --name ads-manager/dev/jwt-secret \
  --secret-string "your-jwt-secret"

# OpenAI API Key
aws secretsmanager create-secret \
  --name ads-manager/dev/openai-key \
  --secret-string "sk-your-openai-key"
```

### 4. Create CloudWatch Log Groups

```bash
aws logs create-log-group --log-group-name /ecs/ads-manager-development-backend
aws logs create-log-group --log-group-name /ecs/ads-manager-development-frontend
```

### 5. Register Task Definitions

```bash
# Development
aws ecs register-task-definition --cli-input-json file://.aws/task-definition-backend-dev.json
aws ecs register-task-definition --cli-input-json file://.aws/task-definition-frontend-dev.json

# Staging
aws ecs register-task-definition --cli-input-json file://.aws/task-definition-backend-staging.json
aws ecs register-task-definition --cli-input-json file://.aws/task-definition-frontend-staging.json

# Production
aws ecs register-task-definition --cli-input-json file://.aws/task-definition-backend-prod.json
aws ecs register-task-definition --cli-input-json file://.aws/task-definition-frontend-prod.json
```

## Updating Task Definitions

Task definitions are automatically updated by GitHub Actions during deployment.

Manual update:

```bash
aws ecs update-service \
  --cluster ads-manager-development-cluster \
  --service ads-manager-development-backend \
  --force-new-deployment
```

## Environment-Specific Configuration

### Development
- CPU: 512 (backend), 256 (frontend)
- Memory: 1024MB (backend), 512MB (frontend)
- Secrets from: `ads-manager/dev/*`

### Staging
- CPU: 512 (backend), 256 (frontend)
- Memory: 1024MB (backend), 512MB (frontend)
- Secrets from: `ads-manager/staging/*`

### Production
- CPU: 1024 (backend), 512 (frontend)
- Memory: 2048MB (backend), 1024MB (frontend)
- Secrets from: `ads-manager/prod/*`
- Additional monitoring and alerting
