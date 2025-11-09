# Deployment Guide

This guide covers deploying the AI Ads Manager platform to AWS using Terraform.

## Prerequisites

Before deploying, ensure you have:

1. **AWS Account** with appropriate permissions
2. **Terraform** 1.5+ installed
3. **Docker** installed for building images
4. **AWS CLI** configured with credentials
5. **Domain name** and SSL certificate in ACM

## Required API Keys

You'll need API credentials for:

- OpenAI or Anthropic Claude
- Google Ads
- Meta (Facebook) Ads
- LinkedIn Ads
- Stripe (for payments)
- Twilio (for SMS notifications)

## Local Development

### 1. Clone and Setup

```bash
git clone <repository-url>
cd ads-manager
```

### 2. Backend Setup

```bash
cd backend
cp .env.example .env
# Edit .env with your local configuration
npm install
npx prisma generate
npx prisma migrate dev
```

### 3. Frontend Setup

```bash
cd frontend
cp .env.example .env
# Edit .env with your local configuration
npm install
```

### 4. Run with Docker Compose

```bash
# From project root
docker-compose up -d
```

The application will be available at:
- Frontend: http://localhost:3000
- Backend API: http://localhost:3001
- API Docs: http://localhost:3001/api/docs

## AWS Production Deployment

### Step 1: Prepare AWS Infrastructure

#### 1.1 Create S3 Bucket for Terraform State

```bash
aws s3 mb s3://ads-manager-terraform-state-prod --region us-east-1
aws s3api put-bucket-versioning \
  --bucket ads-manager-terraform-state-prod \
  --versioning-configuration Status=Enabled
```

#### 1.2 Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock-prod \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

#### 1.3 Request SSL Certificate in ACM

```bash
aws acm request-certificate \
  --domain-name adsmanager.yourdomain.com \
  --validation-method DNS \
  --region us-east-1
```

Validate the certificate using DNS validation.

### Step 2: Build and Push Docker Images

#### 2.1 Create ECR Repositories

```bash
cd terraform/environments/prod
terraform init
terraform apply -target=module.compute.aws_ecr_repository.backend
terraform apply -target=module.compute.aws_ecr_repository.frontend
```

#### 2.2 Build and Push Images

```bash
# Get ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Build and push backend
cd backend
docker build -t ads-manager-backend .
docker tag ads-manager-backend:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/ads-manager/production/backend:latest
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/ads-manager/production/backend:latest

# Build and push frontend
cd ../frontend
docker build -t ads-manager-frontend .
docker tag ads-manager-frontend:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/ads-manager/production/frontend:latest
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/ads-manager/production/frontend:latest
```

### Step 3: Configure Terraform Variables

```bash
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_region = "us-east-1"
project_name = "ads-manager"

# Database
database_password = "SECURE_PASSWORD_HERE"
redis_auth_token = "SECURE_TOKEN_HERE"

# Domain
domain_name = "adsmanager.yourdomain.com"
certificate_arn = "arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/CERT_ID"

# Docker Images
backend_image = "ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/ads-manager/production/backend:latest"
frontend_image = "ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/ads-manager/production/frontend:latest"
```

### Step 4: Deploy Infrastructure

```bash
cd terraform/environments/prod

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply infrastructure
terraform apply
```

This will create:
- VPC with public/private subnets across 3 AZs
- RDS PostgreSQL database
- ElastiCache Redis cluster
- ECS Fargate cluster
- Application Load Balancer
- CloudFront CDN
- S3 buckets for assets
- All necessary security groups and IAM roles

### Step 5: Run Database Migrations

After infrastructure is deployed, run migrations:

```bash
# Get the RDS endpoint from Terraform output
terraform output rds_endpoint

# Update DATABASE_URL in backend/.env
# Then run migrations
cd backend
npm run prisma:migrate
```

Alternatively, exec into a running ECS task:

```bash
aws ecs execute-command \
  --cluster ads-manager-production-cluster \
  --task <task-id> \
  --container backend \
  --interactive \
  --command "npx prisma migrate deploy"
```

### Step 6: Configure DNS

Point your domain to the CloudFront distribution:

```bash
# Get CloudFront domain name
terraform output cloudfront_domain_name

# Create CNAME record in Route53 or your DNS provider
# adsmanager.yourdomain.com -> d123456.cloudfront.net
```

### Step 7: Store Secrets in AWS Secrets Manager

```bash
# Create secret for API keys
aws secretsmanager create-secret \
  --name ads-manager/prod/api-keys \
  --secret-string '{
    "OPENAI_API_KEY": "sk-...",
    "GOOGLE_ADS_CLIENT_ID": "...",
    "META_APP_ID": "...",
    "STRIPE_SECRET_KEY": "sk_live_..."
  }'
```

Update ECS task definition to use secrets from Secrets Manager.

## Post-Deployment

### 1. Verify Deployment

```bash
# Check if services are running
aws ecs describe-services \
  --cluster ads-manager-production-cluster \
  --services ads-manager-production-backend ads-manager-production-frontend

# Check CloudWatch logs
aws logs tail /ecs/ads-manager-production-backend --follow
```

### 2. Create First Admin User

```bash
# Via API
curl -X POST https://adsmanager.yourdomain.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@yourdomain.com",
    "password": "SecurePassword123!",
    "firstName": "Admin",
    "lastName": "User"
  }'
```

### 3. Setup Monitoring

Enable CloudWatch alarms for:
- ECS service health
- RDS CPU/memory
- ALB 5xx errors
- Redis connection failures

```bash
# Example: Create CPU alarm
aws cloudwatch put-metric-alarm \
  --alarm-name ads-manager-backend-cpu-high \
  --alarm-description "Alert when backend CPU is high" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2
```

## Scaling

### Horizontal Scaling

Update desired count in `terraform.tfvars`:

```hcl
backend_desired_count = 4
frontend_desired_count = 4
```

Then apply:

```bash
terraform apply
```

### Vertical Scaling

Update CPU/memory in `terraform.tfvars`:

```hcl
backend_cpu = 1024
backend_memory = 2048
```

### Database Scaling

Update instance class:

```hcl
database_instance_class = "db.r6g.xlarge"
```

## Maintenance

### Update Application

1. Build new Docker images with updated code
2. Push to ECR with new tag or `:latest`
3. Force new deployment:

```bash
aws ecs update-service \
  --cluster ads-manager-production-cluster \
  --service ads-manager-production-backend \
  --force-new-deployment
```

### Database Backup

Automated backups are configured for 7 days retention. To create manual backup:

```bash
aws rds create-db-snapshot \
  --db-instance-identifier ads-manager-production-db \
  --db-snapshot-identifier ads-manager-manual-backup-$(date +%Y%m%d)
```

### Rollback

To rollback to previous task definition:

```bash
# List task definitions
aws ecs list-task-definitions --family-prefix ads-manager-production-backend

# Update service to use previous version
aws ecs update-service \
  --cluster ads-manager-production-cluster \
  --service ads-manager-production-backend \
  --task-definition ads-manager-production-backend:123
```

## Cost Optimization

1. **Use Spot Instances for Workers**: Configure workers to use Spot for non-critical tasks
2. **RDS Reserved Instances**: Purchase reserved instances for predictable workloads
3. **S3 Lifecycle Policies**: Move old assets to Glacier
4. **CloudFront Caching**: Optimize cache headers to reduce origin requests
5. **Right-size Resources**: Monitor and adjust ECS task sizes based on actual usage

## Disaster Recovery

### Backup Strategy

- **Database**: Automated daily snapshots, 7-day retention
- **Redis**: Daily backups, 5-day retention
- **S3**: Versioning enabled, lifecycle policies
- **Infrastructure**: Terraform state backed up in S3 with versioning

### Recovery Procedure

1. Restore database from snapshot
2. Redeploy infrastructure with Terraform
3. Restore S3 data from versioned backup
4. Update DNS if needed
5. Verify application functionality

## Troubleshooting

### Common Issues

**ECS Tasks Failing to Start**
```bash
# Check task logs
aws logs tail /ecs/ads-manager-production-backend --follow

# Check task definition
aws ecs describe-task-definition --task-definition ads-manager-production-backend
```

**Database Connection Issues**
```bash
# Verify security groups
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Test from ECS task
aws ecs execute-command --cluster ads-manager-production-cluster --task <task-id> --container backend --interactive --command "bash"
# Then: nc -zv <rds-endpoint> 5432
```

**High Memory Usage**
```bash
# Scale up task memory
# Update terraform.tfvars and apply

# Or add more tasks
aws ecs update-service --cluster ads-manager-production-cluster --service ads-manager-production-backend --desired-count 4
```

## Security Checklist

- [ ] All secrets stored in AWS Secrets Manager
- [ ] Database not publicly accessible
- [ ] Security groups follow least privilege
- [ ] SSL/TLS enabled on all endpoints
- [ ] WAF rules configured (optional but recommended)
- [ ] VPC Flow Logs enabled
- [ ] CloudTrail enabled for audit logging
- [ ] IAM roles follow least privilege
- [ ] Regular security updates applied
- [ ] Automated vulnerability scanning enabled

## Support

For issues or questions:
- Check CloudWatch logs
- Review Terraform state
- Contact DevOps team
- Create issue in repository
