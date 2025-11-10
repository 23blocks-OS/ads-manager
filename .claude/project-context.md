# AI Ads Manager - Project Context for AI Agents

## Project Overview

This is an **AI-powered advertising automation platform** (SaaS) that manages advertising campaigns across multiple platforms (Google Ads, Facebook/Instagram, LinkedIn) using artificial intelligence for optimization and decision-making.

**Core Value Proposition**: Business owners without marketing expertise can set up their companies, products, budget, and credit card - then AI handles everything: platform selection, campaign creation, budget allocation, ad copy generation, targeting, and daily optimization.

## Architecture

### Tech Stack

**Backend**:
- NestJS (TypeScript) - API framework
- PostgreSQL - Primary database
- Redis - Caching & queue management
- Prisma - ORM
- OpenAI GPT-4 / Anthropic Claude - AI decision engine

**Frontend**:
- Next.js 14 (React, TypeScript)
- Tailwind CSS - Styling
- React Query - State management

**Infrastructure**:
- AWS ECS Fargate - Container orchestration
- AWS RDS PostgreSQL - Database
- AWS ElastiCache Redis - Caching
- AWS S3 - Asset storage
- AWS CloudFront - CDN
- Terraform - Infrastructure as Code

**Ad Platforms**:
- Google Ads API
- Meta (Facebook/Instagram) Ads API
- LinkedIn Ads API

### Project Structure

```
ads-manager/
├── backend/                 # NestJS API
│   ├── src/
│   │   ├── modules/        # Feature modules
│   │   │   ├── auth/       # Authentication & JWT
│   │   │   ├── companies/  # Company management
│   │   │   ├── products/   # Product catalog
│   │   │   ├── campaigns/  # Campaign management
│   │   │   ├── ai-engine/  # AI optimization services
│   │   │   ├── integrations/ # Ad platform connectors
│   │   │   ├── analytics/  # Reporting & metrics
│   │   │   ├── notifications/ # Alerts & notifications
│   │   │   └── billing/    # Stripe integration
│   │   ├── database/       # Prisma service
│   │   └── common/         # Shared utilities
│   ├── prisma/schema.prisma # Database schema (15+ models)
│   └── Dockerfile
│
├── frontend/               # Next.js application
│   ├── src/
│   │   ├── app/           # App router pages
│   │   ├── components/    # React components
│   │   ├── lib/           # Utilities
│   │   └── hooks/         # Custom hooks
│   └── Dockerfile
│
├── terraform/             # Infrastructure as Code
│   ├── modules/           # Reusable modules
│   │   ├── networking/    # VPC, subnets, security groups
│   │   ├── compute/       # ECS, ALB, ECR
│   │   └── database/      # RDS, ElastiCache
│   └── environments/      # Dev, staging, prod configs
│
├── .github/workflows/     # CI/CD pipelines
│   ├── deploy-development.yml
│   ├── deploy-staging.yml
│   └── deploy-production.yml
│
├── .aws/                  # ECS task definitions
├── scripts/               # Automation scripts
│   └── setup.sh          # Interactive installer
│
└── docs/                  # Documentation
    ├── GETTING_STARTED.md
    ├── DEPLOYMENT.md
    └── integrations/      # Platform setup guides
        ├── GOOGLE_ADS_SETUP.md
        ├── META_ADS_SETUP.md
        ├── LINKEDIN_ADS_SETUP.md
        ├── INTEGRATION_SUMMARY.md
        └── TROUBLESHOOTING.md
```

## Core Features

### 1. AI Campaign Engine
**Location**: `backend/src/modules/ai-engine/`

**Services**:
- **BudgetOptimizerService** - Analyzes performance, reallocates budget across platforms
- **CampaignGeneratorService** - Creates campaigns based on product data
- **AdCopyGeneratorService** - Generates ad copy variations using GPT-4/Claude
- **TargetingOptimizerService** - Refines audience targeting
- **PerformancePredictorService** - Predicts campaign performance

**How it works**:
1. User adds product with description, features, benefits
2. AI analyzes product and brand guidelines
3. Generates campaign strategy (which platforms, budgets, targeting)
4. Creates ad copy variations for each platform
5. Monitors performance daily
6. Reallocates budget to top performers
7. Adjusts bids, targeting, and creative

### 2. Multi-Platform Integration
**Location**: `backend/src/modules/integrations/`

**Platforms**:
- **Google Ads** - Search, Display, Shopping campaigns
- **Meta Ads** - Facebook & Instagram feed, stories, reels
- **LinkedIn Ads** - Sponsored Content, Message Ads (B2B focus)

**Integration Pattern**:
```typescript
// Each platform has:
- Service class with API methods
- OAuth credential management
- Campaign creation/update/pause
- Metrics fetching
- Conversion tracking setup
```

### 3. Database Schema
**Location**: `backend/prisma/schema.prisma`

**Key Models**:
- `User` - Authentication, roles
- `Company` - Multi-tenant companies
- `Product` - Product catalog with features/benefits
- `BrandGuidelines` - Brand voice, colors, keywords
- `Campaign` - Ad campaigns across platforms
- `AdCreative` - Ad copy and creative assets
- `CampaignMetrics` - Daily performance metrics
- `Integration` - Platform credentials (encrypted)
- `BillingInfo` - Stripe subscriptions

### 4. CI/CD Pipeline
**Location**: `.github/workflows/`

**Environments**:
1. **Development** (`dev`, `develop`, `development` branches)
   - Auto-deploys on push
   - Development ECR repos
   - Dev ECS cluster

2. **Staging** (`staging` branch)
   - Auto-deploys on push
   - Comments on PRs with deployment link
   - Staging ECR repos
   - Staging ECS cluster

3. **Production** (`main`, `master` branches, or tags)
   - Requires manual confirmation
   - Vulnerability scanning
   - Health checks
   - Rollback on failure
   - GitHub release creation

**Pipeline Steps**:
1. Build Docker images (backend + frontend)
2. Push to ECR with multiple tags
3. Update ECS task definitions
4. Deploy to ECS Fargate
5. Run database migrations
6. Health check
7. Create deployment summary

## Developer Setup

### Quick Start

```bash
# Interactive setup (asks for all credentials)
./scripts/setup.sh

# Or manual setup
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env.local

# Edit .env files with your credentials

# Start with Docker
docker-compose up -d

# Or run services separately
cd backend && npm install && npm run start:dev
cd frontend && npm install && npm run dev
```

### Required Credentials

**AI Services**:
- OpenAI API key (required)
- Anthropic API key (optional)

**Ad Platforms** (optional for development):
- Google Ads: Client ID, Client Secret, Developer Token, Refresh Token
- Meta Ads: App ID, App Secret, Access Token, Ad Account ID
- LinkedIn Ads: Client ID, Client Secret, Access Token

**Payment**:
- Stripe: Secret Key, Publishable Key, Webhook Secret

**AWS** (production only):
- Access Key ID, Secret Access Key
- RDS database URL
- ElastiCache Redis host

## Common Tasks for AI Agents

### Adding a New Ad Platform

1. **Create service**: `backend/src/modules/integrations/[platform]-ads/[platform]-ads.service.ts`
2. **Implement methods**:
   - `createCampaign(credentials, campaignData)`
   - `getCampaignMetrics(credentials, campaignId)`
   - `updateCampaignBudget(credentials, campaignId, newBudget)`
   - `pauseCampaign(campaignId)` / `resumeCampaign(campaignId)`
3. **Add to enum**: Update `AdPlatform` in `prisma/schema.prisma`
4. **Create integration guide**: `docs/integrations/[PLATFORM]_SETUP.md`
5. **Update summary**: Add to `docs/integrations/INTEGRATION_SUMMARY.md`

### Adding a New AI Feature

1. **Create service**: `backend/src/modules/ai-engine/services/[feature].service.ts`
2. **Add to module**: Export from `ai-engine.module.ts`
3. **Use in campaigns**: Import in `campaigns.service.ts` or worker
4. **Add prompt engineering**: Craft effective prompts in service methods
5. **Test with real data**: Ensure AI responses are parsed correctly

### Modifying Database Schema

```bash
# Edit schema
vim backend/prisma/schema.prisma

# Generate migration
cd backend
npx prisma migrate dev --name describe_changes

# Apply to database
npx prisma migrate deploy

# Regenerate client
npx prisma generate
```

### Deploying Changes

```bash
# Development - push to dev branch
git push origin dev

# Staging - push to staging branch
git push origin staging

# Production - push to main or create tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
# Or: git push origin main (with manual confirmation in Actions)
```

## Integration Documentation

Each ad platform has comprehensive setup documentation:

### Google Ads (`docs/integrations/GOOGLE_ADS_SETUP.md`)
- OAuth 2.0 flow implementation
- Developer token application
- Manager Account (MCC) setup
- Conversion tracking with gtag.js
- ~40 pages of detailed setup

### Meta Ads (`docs/integrations/META_ADS_SETUP.md`)
- Business Manager setup
- System User creation
- Facebook Pixel installation
- Advanced Access request
- ~40 pages of detailed setup

### LinkedIn Ads (`docs/integrations/LINKEDIN_ADS_SETUP.md`)
- Campaign Manager setup
- Marketing Developer Platform access
- OAuth token generation
- Insight Tag installation
- ~35 pages of detailed setup

### Integration Summary (`docs/integrations/INTEGRATION_SUMMARY.md`)
- Quick reference for all platforms
- Credentials overview
- Security best practices
- Common troubleshooting

## Security Considerations

### Credential Storage

**Development**:
```bash
# .env files (git-ignored)
GOOGLE_ADS_CLIENT_SECRET=xxxxx
META_APP_SECRET=xxxxx
```

**Production**:
```bash
# AWS Secrets Manager
aws secretsmanager create-secret \
  --name ads-manager/prod/credentials \
  --secret-string '{"googleAds":{...}}'
```

**Database**:
```typescript
// Encrypt before storing
const encrypted = encrypt(JSON.stringify(credentials));
await prisma.integration.create({
  data: { credentials: encrypted }
});

// Decrypt when using
const decrypted = decrypt(integration.credentials);
```

### Rate Limiting

- Google Ads: 15,000 ops/day (basic), 250,000 (standard)
- Meta Ads: 200 calls/hour (standard)
- LinkedIn Ads: 100 calls/day (community apps)

**Implementation**: Use Bull queues with rate limiters

## Current State

### ✅ Completed
- Full backend API with NestJS
- Database schema with 15+ models
- AI services for campaign generation and optimization
- Frontend landing page
- Ad platform integration stubs
- Comprehensive integration documentation
- Terraform infrastructure for AWS
- Docker configuration
- Interactive installer script
- GitHub Actions CI/CD for all environments
- ECS task definitions

### 🚧 In Progress / Next Steps
1. Complete staging/prod ECS task definitions (templates created)
2. Frontend dashboard pages (authentication, companies, products, campaigns)
3. Real ad platform API integration (currently stubs)
4. Automated metric syncing workers
5. Notification system implementation
6. Stripe billing integration
7. Production deployment and testing

### 🔮 Future Enhancements
- TikTok Ads integration
- Twitter Ads integration
- Microsoft Ads integration
- A/B testing automation
- Multi-language support
- White-label options
- Mobile app

## Important Files to Reference

### Configuration
- `backend/.env.example` - All required environment variables
- `frontend/.env.example` - Frontend configuration
- `docker-compose.yml` - Local development setup
- `terraform/variables.tf` - Infrastructure variables

### Documentation
- `README.md` - Project overview
- `docs/GETTING_STARTED.md` - Quick start guide
- `docs/DEPLOYMENT.md` - Production deployment
- `docs/integrations/` - Ad platform setup guides

### Core Services
- `backend/src/modules/ai-engine/ai-engine.service.ts` - AI wrapper
- `backend/src/modules/ai-engine/services/budget-optimizer.service.ts` - Budget logic
- `backend/src/modules/ai-engine/services/campaign-generator.service.ts` - Campaign creation
- `backend/src/modules/auth/auth.service.ts` - Authentication

### Database
- `backend/prisma/schema.prisma` - Complete schema
- Schema has: User, Company, Product, Campaign, AdCreative, CampaignMetrics, Integration, BillingInfo, Notification

## Tips for AI Agents Continuing This Work

1. **Review integration docs first** - The ad platform setup guides contain crucial API details

2. **Test locally with Docker Compose** - Much faster than deploying to AWS
   ```bash
   docker-compose up -d
   ```

3. **Use the setup script** - It handles all credential collection
   ```bash
   ./scripts/setup.sh
   ```

4. **Check GitHub Actions logs** - If deployment fails, logs show exactly what went wrong

5. **Prisma is your friend**:
   ```bash
   npx prisma studio    # Visual database browser
   npx prisma generate  # After schema changes
   npx prisma migrate dev # Create migration
   ```

6. **AI prompts are in services** - Modify prompts in `ai-engine/services/*.service.ts` to improve AI behavior

7. **Each platform is different** - Review official API docs:
   - Google: https://developers.google.com/google-ads/api
   - Meta: https://developers.facebook.com/docs/marketing-api
   - LinkedIn: https://learn.microsoft.com/en-us/linkedin/marketing/

8. **Security first** - Never commit secrets, always encrypt credentials in DB

9. **Test incrementally** - Don't try to build everything at once. Test each component.

10. **Use the troubleshooting guide** - `docs/integrations/TROUBLESHOOTING.md` has solutions for common issues

## Contact & Resources

- **Repository**: https://github.com/23blocks-OS/ads-manager
- **Branch**: `claude/automation-tool-creation-011CUyCeRNvijrvLaDW2RkB6`
- **Documentation**: All in `docs/` folder
- **Integration Guides**: `docs/integrations/`

## Success Criteria

The platform is successful when:
1. ✅ User can register and create company
2. ✅ User can add products with descriptions
3. ✅ User can connect Google/Meta/LinkedIn ad accounts
4. ⏳ AI generates campaigns automatically
5. ⏳ Campaigns are created on actual ad platforms
6. ⏳ Metrics are synced daily
7. ⏳ Budget is optimized automatically
8. ⏳ User receives performance reports
9. ⏳ Platform scales to handle 100+ companies
10. ⏳ All security best practices implemented

**Current Status**: Items 1-3 are architected and ready. Items 4-10 need implementation with real API integration.

---

**Last Updated**: 2024-01-10 by Claude (Sonnet 4.5)
**Session ID**: `011CUyCeRNvijrvLaDW2RkB6`

Good luck! The foundation is solid. Focus on connecting real APIs and implementing the AI optimization loop. The documentation will guide you through each platform's quirks. 🚀
