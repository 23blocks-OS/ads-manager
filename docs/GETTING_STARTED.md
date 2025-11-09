# Getting Started Guide

This guide will help you get the AI Ads Manager platform up and running locally.

## Quick Start

### 1. Prerequisites

Install the following:

- **Node.js** 18+ ([Download](https://nodejs.org/))
- **Docker** & Docker Compose ([Download](https://www.docker.com/))
- **Git** ([Download](https://git-scm.com/))

### 2. Clone Repository

```bash
git clone <your-repo-url>
cd ads-manager
```

### 3. Start with Docker Compose

The easiest way to get started:

```bash
docker-compose up -d
```

This starts:
- PostgreSQL database on port 5432
- Redis on port 6379
- Backend API on port 3001
- Frontend on port 3000

Access the application:
- **Frontend**: http://localhost:3000
- **API**: http://localhost:3001
- **API Docs**: http://localhost:3001/api/docs

### 4. Create Your First User

```bash
curl -X POST http://localhost:3001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "you@example.com",
    "password": "SecurePassword123!",
    "firstName": "John",
    "lastName": "Doe"
  }'
```

## Manual Setup (Alternative)

If you prefer to run services individually:

### Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Setup environment
cp .env.example .env
# Edit .env with your configuration

# Start PostgreSQL and Redis
docker-compose up -d postgres redis

# Generate Prisma client
npx prisma generate

# Run migrations
npx prisma migrate dev

# Start development server
npm run start:dev
```

Backend will run on http://localhost:3001

### Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Setup environment
cp .env.example .env
# Edit .env with your configuration

# Start development server
npm run dev
```

Frontend will run on http://localhost:3000

## Configuration

### Environment Variables

#### Backend (.env)

```bash
# Database
DATABASE_URL=postgresql://adsmanager:devpassword@localhost:5432/ads_manager

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your-secret-key
JWT_EXPIRATION=7d

# AI Services (get keys from providers)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Ad Platforms (optional for development)
GOOGLE_ADS_CLIENT_ID=
GOOGLE_ADS_CLIENT_SECRET=
META_APP_ID=
META_APP_SECRET=

# Stripe (optional for development)
STRIPE_SECRET_KEY=sk_test_...
```

#### Frontend (.env)

```bash
NEXT_PUBLIC_API_URL=http://localhost:3001/api/v1
```

## Next Steps

Once your local environment is running:

### 1. Explore the API

Visit http://localhost:3001/api/docs to see the interactive API documentation.

### 2. Create a Company

```bash
# Login first
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "you@example.com",
    "password": "SecurePassword123!"
  }'

# Use the access token from response
export TOKEN=<your-access-token>

# Create a company
curl -X POST http://localhost:3001/api/v1/companies \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Company",
    "description": "My awesome company",
    "website": "https://example.com",
    "industry": "Technology"
  }'
```

### 3. Add a Product

```bash
curl -X POST http://localhost:3001/api/v1/products \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "companyId": "<company-id>",
    "name": "My Product",
    "description": "An amazing product that solves problems",
    "price": 99.99,
    "category": "SaaS",
    "features": ["Feature 1", "Feature 2"],
    "benefits": ["Benefit 1", "Benefit 2"],
    "keywords": ["keyword1", "keyword2"]
  }'
```

### 4. Set Brand Guidelines

```bash
curl -X PUT http://localhost:3001/api/v1/companies/<company-id>/brand-guidelines \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "brandVoice": "professional",
    "toneKeywords": ["innovative", "reliable", "cutting-edge"],
    "targetAudience": "Tech-savvy professionals aged 25-45",
    "valueProposition": "We help businesses save time and money",
    "uniqueSellingPoints": ["AI-powered", "Easy to use", "24/7 support"]
  }'
```

### 5. Configure Budget

```bash
curl -X PUT http://localhost:3001/api/v1/companies/<company-id>/budget-settings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "totalMonthlyBudget": 5000,
    "currency": "USD",
    "autoAllocate": true,
    "dailySpendLimit": 200
  }'
```

## Development Workflow

### Making Code Changes

The development servers support hot reload:

- **Backend**: Changes to `.ts` files automatically restart the server
- **Frontend**: Changes to React components automatically refresh the browser

### Database Changes

When you modify the Prisma schema:

```bash
cd backend

# Create a migration
npx prisma migrate dev --name your_migration_name

# Generate Prisma Client
npx prisma generate
```

### Running Tests

```bash
# Backend tests
cd backend
npm test

# Frontend tests
cd frontend
npm test
```

### Code Formatting

```bash
# Backend
cd backend
npm run format
npm run lint

# Frontend
cd frontend
npm run lint
```

## Troubleshooting

### Port Already in Use

If ports 3000 or 3001 are already in use:

```bash
# Find and kill the process
lsof -ti:3000 | xargs kill -9
lsof -ti:3001 | xargs kill -9
```

### Database Connection Issues

```bash
# Reset database
cd backend
docker-compose down -v
docker-compose up -d postgres redis
npx prisma migrate dev
```

### Clear All Data

```bash
# Stop and remove all containers and volumes
docker-compose down -v

# Restart
docker-compose up -d
```

## Learning Resources

- **NestJS**: https://docs.nestjs.com/
- **Next.js**: https://nextjs.org/docs
- **Prisma**: https://www.prisma.io/docs
- **Terraform**: https://developer.hashicorp.com/terraform
- **AWS ECS**: https://docs.aws.amazon.com/ecs/

## Need Help?

- Check the [API Documentation](http://localhost:3001/api/docs)
- Review [Deployment Guide](./DEPLOYMENT.md)
- Check GitHub Issues
- Contact the development team

## What's Next?

Now that you have the platform running locally:

1. **Integrate Ad Platforms**: Connect your Google Ads, Facebook Ads accounts
2. **Test AI Features**: Try the AI campaign generation and optimization
3. **Customize**: Modify the code to fit your specific needs
4. **Deploy**: Follow the [Deployment Guide](./DEPLOYMENT.md) to deploy to AWS

Happy coding!
