# Ad Platform Integration Summary

Quick reference guide for all advertising platform integrations in the AI Ads Manager.

## Overview

This document provides a high-level summary of all platform integrations, required credentials, and quick setup links.

---

## Supported Platforms

| Platform | Status | Difficulty | Approval Time | Documentation |
|----------|--------|-----------|---------------|---------------|
| Google Ads | ✅ Ready | Medium | 24-48 hours | [Guide](./GOOGLE_ADS_SETUP.md) |
| Meta Ads | ✅ Ready | Medium | 1-5 days | [Guide](./META_ADS_SETUP.md) |
| LinkedIn Ads | ✅ Ready | Easy | 1-5 days | [Guide](./LINKEDIN_ADS_SETUP.md) |
| TikTok Ads | 🔄 Planned | Medium | 3-7 days | Coming soon |
| Twitter Ads | 🔄 Planned | Easy | 1-3 days | Coming soon |
| Microsoft Ads | 🔄 Planned | Medium | 24-48 hours | Coming soon |

---

## Quick Setup Checklist

### Before You Start

- [ ] Business registered and verified
- [ ] Company website with privacy policy
- [ ] Payment method ready
- [ ] Access to company email
- [ ] Developer accounts created

### For Each Platform

- [ ] Developer app created
- [ ] API access requested and approved
- [ ] OAuth credentials generated
- [ ] Access tokens obtained
- [ ] Conversion tracking installed
- [ ] Test connection successful
- [ ] Credentials stored securely

---

## Credentials Overview

### Google Ads

```bash
# Required Environment Variables
GOOGLE_ADS_CLIENT_ID=xxx.apps.googleusercontent.com
GOOGLE_ADS_CLIENT_SECRET=GOCSPX-xxxxx
GOOGLE_ADS_DEVELOPER_TOKEN=xxxxx
GOOGLE_ADS_REFRESH_TOKEN=1//xxxxx
GOOGLE_ADS_CUSTOMER_ID=1234567890
```

**Where to get them:**
- Client ID/Secret: Google Cloud Console → APIs & Services → Credentials
- Developer Token: Google Ads → API Center
- Refresh Token: OAuth flow (see guide)
- Customer ID: Google Ads account ID (remove dashes)

**Key Links:**
- Developer Console: https://console.cloud.google.com
- API Center: https://ads.google.com → Tools → API Center
- Documentation: https://developers.google.com/google-ads/api

---

### Meta (Facebook/Instagram) Ads

```bash
# Required Environment Variables
META_APP_ID=123456789012345
META_APP_SECRET=xxxxx
META_ACCESS_TOKEN=EAAxxxxx (system user token)
META_AD_ACCOUNT_ID=act_123456789
META_PAGE_ID=123456789
META_PIXEL_ID=123456789
```

**Where to get them:**
- App ID/Secret: developers.facebook.com → Your App → Settings
- Access Token: Business Settings → System Users → Generate Token
- Ad Account ID: Business Manager → Ad Accounts
- Page ID: Facebook Page → About
- Pixel ID: Business Manager → Data Sources → Pixels

**Key Links:**
- Developer Portal: https://developers.facebook.com
- Business Manager: https://business.facebook.com
- Documentation: https://developers.facebook.com/docs/marketing-api

---

### LinkedIn Ads

```bash
# Required Environment Variables
LINKEDIN_CLIENT_ID=86xxxxx
LINKEDIN_CLIENT_SECRET=xxxxx
LINKEDIN_ACCESS_TOKEN=AQxxxxx
LINKEDIN_REFRESH_TOKEN=AQxxxxx
LINKEDIN_AD_ACCOUNT_ID=123456789
LINKEDIN_PARTNER_ID=123456
```

**Where to get them:**
- Client ID/Secret: developers.linkedin.com → Your App → Auth
- Access Token: OAuth flow (expires every 60 days)
- Ad Account ID: Campaign Manager URL
- Partner ID: Campaign Manager → Insight Tag

**Key Links:**
- Developer Portal: https://www.linkedin.com/developers
- Campaign Manager: https://www.linkedin.com/campaignmanager
- Documentation: https://learn.microsoft.com/en-us/linkedin/marketing/

---

## Integration Implementation

### 1. Database Schema

Each integration is stored in the `integrations` table:

```prisma
model Integration {
  id          String           @id @default(uuid())
  companyId   String
  platform    AdPlatform       // GOOGLE_ADS, META_ADS, LINKEDIN_ADS
  credentials Json             // Encrypted platform credentials
  isActive    Boolean          @default(true)
  lastSyncAt  DateTime?
  status      IntegrationStatus
  errorMessage String?
  createdAt   DateTime         @default(now())
  updatedAt   DateTime         @updatedAt
}
```

### 2. API Endpoints

#### Connect Platform

```bash
POST /api/v1/integrations
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "companyId": "uuid",
  "platform": "GOOGLE_ADS | META_ADS | LINKEDIN_ADS",
  "credentials": {
    // Platform-specific credentials
  }
}
```

#### Get Integrations

```bash
GET /api/v1/integrations?companyId={id}
Authorization: Bearer {jwt_token}
```

#### Disconnect Platform

```bash
DELETE /api/v1/integrations/{id}
Authorization: Bearer {jwt_token}
```

#### Test Connection

```bash
POST /api/v1/integrations/{id}/test
Authorization: Bearer {jwt_token}
```

### 3. OAuth Callback URLs

Each platform needs these callback URLs configured:

```
# Development
http://localhost:3001/api/v1/integrations/google-ads/callback
http://localhost:3001/api/v1/integrations/meta-ads/callback
http://localhost:3001/api/v1/integrations/linkedin-ads/callback

# Production
https://yourdomain.com/api/v1/integrations/google-ads/callback
https://yourdomain.com/api/v1/integrations/meta-ads/callback
https://yourdomain.com/api/v1/integrations/linkedin-ads/callback
```

---

## Conversion Tracking

### Tracking Code Installation

Install all tracking codes on your website:

```html
<!DOCTYPE html>
<html>
<head>
  <!-- Google Ads Conversion Tracking -->
  <script async src="https://www.googletagmanager.com/gtag/js?id=AW-123456789"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', 'AW-123456789');
  </script>

  <!-- Meta Pixel -->
  <script>
    !function(f,b,e,v,n,t,s){...}
    fbq('init', 'YOUR_PIXEL_ID');
    fbq('track', 'PageView');
  </script>

  <!-- LinkedIn Insight Tag -->
  <script>
    _linkedin_partner_id = "123456";
    window._linkedin_data_partner_ids = window._linkedin_data_partner_ids || [];
    window._linkedin_data_partner_ids.push(_linkedin_partner_id);
  </script>
  <script src="https://snap.licdn.com/li.lms-analytics/insight.min.js"></script>
</head>
<body>
  <!-- Your content -->
</body>
</html>
```

### Conversion Events

Track conversions on key actions:

```javascript
// Purchase event
function trackPurchase(value, currency = 'USD') {
  // Google Ads
  gtag('event', 'conversion', {
    'send_to': 'AW-123456789/xxxxx',
    'value': value,
    'currency': currency
  });

  // Meta Pixel
  fbq('track', 'Purchase', {
    value: value,
    currency: currency
  });

  // LinkedIn
  lintrk('track', { conversion_id: 123456 });
}

// Lead event
function trackLead() {
  gtag('event', 'conversion', {'send_to': 'AW-123456789/xxxxx'});
  fbq('track', 'Lead');
  lintrk('track', { conversion_id: 123457 });
}

// Sign up event
function trackSignUp() {
  gtag('event', 'conversion', {'send_to': 'AW-123456789/xxxxx'});
  fbq('track', 'CompleteRegistration');
  lintrk('track', { conversion_id': 123458 });
}
```

---

## Security Best Practices

### 1. Credential Storage

**Development:**
```bash
# .env file (never commit)
GOOGLE_ADS_CLIENT_SECRET=xxxxx
META_APP_SECRET=xxxxx
LINKEDIN_CLIENT_SECRET=xxxxx
```

**Production:**
```bash
# AWS Secrets Manager
aws secretsmanager create-secret \
  --name ads-manager/prod/all-platforms \
  --secret-string '{
    "googleAds": {...},
    "metaAds": {...},
    "linkedinAds": {...}
  }'
```

### 2. Encryption

Encrypt credentials before storing in database:

```typescript
import { createCipheriv, createDecipheriv } from 'crypto';

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY; // 32 bytes
const IV_LENGTH = 16;

export function encrypt(text: string): string {
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = createCipheriv('aes-256-cbc', Buffer.from(ENCRYPTION_KEY), iv);
  let encrypted = cipher.update(text);
  encrypted = Buffer.concat([encrypted, cipher.final()]);
  return iv.toString('hex') + ':' + encrypted.toString('hex');
}

export function decrypt(text: string): string {
  const parts = text.split(':');
  const iv = Buffer.from(parts.shift(), 'hex');
  const encrypted = Buffer.from(parts.join(':'), 'hex');
  const decipher = createDecipheriv('aes-256-cbc', Buffer.from(ENCRYPTION_KEY), iv);
  let decrypted = decipher.update(encrypted);
  decrypted = Buffer.concat([decrypted, decipher.final()]);
  return decrypted.toString();
}
```

### 3. Token Refresh

Implement automatic token refresh:

```typescript
@Cron('0 0 * * *') // Daily at midnight
async refreshExpiredTokens() {
  const integrations = await this.prisma.integration.findMany({
    where: {
      isActive: true,
      platform: { in: ['META_ADS', 'LINKEDIN_ADS'] },
    },
  });

  for (const integration of integrations) {
    try {
      const newToken = await this.refreshToken(integration);
      await this.updateCredentials(integration.id, newToken);
      console.log(`✅ Refreshed token for ${integration.platform}`);
    } catch (error) {
      console.error(`❌ Failed to refresh ${integration.platform}:`, error);
      await this.notifyAdmin(integration, error);
    }
  }
}
```

---

## Rate Limiting

Implement rate limiting per platform:

```typescript
import { RateLimiter } from 'limiter';

export class PlatformRateLimiter {
  private limiters: Map<string, RateLimiter> = new Map();

  constructor() {
    // Google Ads: 15,000 operations/day
    this.limiters.set('GOOGLE_ADS', new RateLimiter({
      tokensPerInterval: 15000,
      interval: 'day',
    }));

    // Meta Ads: 200 calls/hour
    this.limiters.set('META_ADS', new RateLimiter({
      tokensPerInterval: 200,
      interval: 'hour',
    }));

    // LinkedIn Ads: 100 calls/day (community apps)
    this.limiters.set('LINKEDIN_ADS', new RateLimiter({
      tokensPerInterval: 100,
      interval: 'day',
    }));
  }

  async tryRemoveTokens(platform: string, count: number = 1): Promise<boolean> {
    const limiter = this.limiters.get(platform);
    if (!limiter) return true;
    return await limiter.tryRemoveTokens(count);
  }
}
```

---

## Error Handling

Standardized error handling across platforms:

```typescript
export class AdPlatformError extends Error {
  constructor(
    public platform: string,
    public code: string,
    public message: string,
    public retryable: boolean = false,
  ) {
    super(message);
  }
}

export function handlePlatformError(platform: string, error: any): AdPlatformError {
  // Google Ads errors
  if (platform === 'GOOGLE_ADS') {
    if (error.code === 'QUOTA_EXCEEDED') {
      return new AdPlatformError('GOOGLE_ADS', 'RATE_LIMIT', 'Rate limit exceeded', true);
    }
  }

  // Meta Ads errors
  if (platform === 'META_ADS') {
    if (error.error_subcode === 1487390) {
      return new AdPlatformError('META_ADS', 'BUDGET_TOO_LOW', 'Daily budget too low', false);
    }
  }

  // LinkedIn Ads errors
  if (platform === 'LINKEDIN_ADS') {
    if (error.status === 429) {
      return new AdPlatformError('LINKEDIN_ADS', 'RATE_LIMIT', 'Rate limit exceeded', true);
    }
  }

  return new AdPlatformError(platform, 'UNKNOWN', error.message, false);
}
```

---

## Testing Integrations

### Automated Tests

```typescript
describe('Ad Platform Integrations', () => {
  describe('Google Ads', () => {
    it('should connect successfully', async () => {
      const result = await googleAdsService.testConnection(credentials);
      expect(result.success).toBe(true);
    });

    it('should create campaign', async () => {
      const campaign = await googleAdsService.createCampaign(campaignData);
      expect(campaign.platformCampaignId).toBeDefined();
    });
  });

  describe('Meta Ads', () => {
    it('should connect successfully', async () => {
      const result = await metaAdsService.testConnection(credentials);
      expect(result.success).toBe(true);
    });
  });

  describe('LinkedIn Ads', () => {
    it('should connect successfully', async () => {
      const result = await linkedinAdsService.testConnection(credentials);
      expect(result.success).toBe(true);
    });
  });
});
```

### Manual Testing

Use the provided test scripts:

```bash
# Test all integrations
npm run test:integrations

# Test specific platform
npx ts-node scripts/test-google-ads.ts
npx ts-node scripts/test-meta-ads.ts
npx ts-node scripts/test-linkedin-ads.ts
```

---

## Monitoring and Alerts

### Metrics to Monitor

```typescript
// Prometheus metrics example
const campaignCreatedCounter = new Counter({
  name: 'campaigns_created_total',
  help: 'Total number of campaigns created',
  labelNames: ['platform', 'status'],
});

const apiErrorCounter = new Counter({
  name: 'api_errors_total',
  help: 'Total number of API errors',
  labelNames: ['platform', 'error_code'],
});

const tokenRefreshGauge = new Gauge({
  name: 'token_expiry_seconds',
  help: 'Time until token expires',
  labelNames: ['platform'],
});
```

### Alert Rules

Set up alerts for:
- Token expiration (< 7 days)
- API rate limit warnings (> 80% usage)
- Integration failures (> 3 consecutive errors)
- Unusual spending patterns
- Campaign performance issues

---

## Common Issues and Solutions

### Issue: OAuth redirect not working

**Symptoms**: After authorization, redirect fails or shows error

**Solutions**:
1. Check redirect URI matches exactly (http vs https)
2. Verify URL is whitelisted in platform settings
3. Check for typos in callback endpoint
4. Ensure SSL certificate is valid (production)

### Issue: Token expired/invalid

**Symptoms**: API calls fail with authentication error

**Solutions**:
1. Check token expiration date
2. Implement automatic token refresh
3. Re-authorize if refresh token expired
4. Verify token stored correctly (no truncation)

### Issue: Rate limit exceeded

**Symptoms**: API returns 429 or quota exceeded error

**Solutions**:
1. Implement exponential backoff
2. Queue requests for retry
3. Cache frequently accessed data
4. Request higher rate limits (if eligible)

### Issue: Insufficient permissions

**Symptoms**: API returns permission denied error

**Solutions**:
1. Re-authorize with all required scopes
2. Verify account has admin access
3. Check API products are enabled
4. Ensure business verification complete

---

## Next Steps

After completing all integrations:

1. **Test end-to-end flow**:
   - Create company
   - Add product
   - Connect platforms
   - Generate campaign with AI
   - Verify campaign created on platform

2. **Set up automated syncing**:
   - Schedule metric fetching (hourly)
   - Implement budget optimization (daily)
   - Set up alerts and notifications

3. **Monitor performance**:
   - Track API usage
   - Monitor error rates
   - Review conversion tracking

4. **Optimize**:
   - Implement caching
   - Batch API requests
   - Fine-tune AI models

---

## Support and Resources

### Platform Support

- **Google Ads**: https://support.google.com/google-ads
- **Meta Ads**: https://www.facebook.com/business/help
- **LinkedIn Ads**: https://www.linkedin.com/help/lms

### Developer Communities

- **Google Ads API Forum**: https://groups.google.com/g/adwords-api
- **Meta Developers Community**: https://developers.facebook.com/community
- **LinkedIn Marketing Developer Platform**: https://www.linkedin.com/help/lms/topics/16187

### Internal Documentation

- [Google Ads Setup](./GOOGLE_ADS_SETUP.md)
- [Meta Ads Setup](./META_ADS_SETUP.md)
- [LinkedIn Ads Setup](./LINKEDIN_ADS_SETUP.md)
- [Deployment Guide](../DEPLOYMENT.md)
- [Getting Started](../GETTING_STARTED.md)

---

**Last Updated**: 2024-01-10

For questions or issues, contact the development team or create an issue in the repository.
