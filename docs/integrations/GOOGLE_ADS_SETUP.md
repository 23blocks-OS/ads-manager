# Google Ads API Integration Guide

This guide walks you through setting up Google Ads API access for the AI Ads Manager platform.

## Overview

To integrate Google Ads, you need:
1. Google Ads account with campaigns
2. Google Ads API access (requires approval)
3. Google Cloud Project with Ads API enabled
4. OAuth 2.0 credentials
5. Developer token

**Time Required**: 30-60 minutes (plus 24-48 hours for API approval)

## Prerequisites

- Google Ads account: https://ads.google.com
- Google Cloud account: https://console.cloud.google.com
- Manager Account (MCC) recommended for managing multiple clients

---

## Step 1: Apply for Google Ads API Access

### 1.1 Create or Access Manager Account

1. Go to https://ads.google.com
2. Click **Tools & Settings** → **Setup** → **Manager accounts**
3. Create a new Manager Account (MCC) if you don't have one
4. Note your **Customer ID** (format: 123-456-7890)

### 1.2 Apply for API Access

1. Log in to https://ads.google.com with your Manager Account
2. Navigate to **Tools & Settings** → **Setup** → **API Center**
3. Click **Apply for access**
4. Fill out the application form:
   - **What will you use the API for?**: "Automated campaign management and optimization platform"
   - **How many accounts will you manage?**: Your expected number
   - **Will you use the API for yourself or clients?**: Select appropriate option
   - **Have you used the API before?**: Answer honestly
5. Submit and wait for approval (typically 24-48 hours)

> **Note**: Google reviews each application. Be descriptive and professional.

---

## Step 2: Create Google Cloud Project

### 2.1 Set Up Project

1. Go to https://console.cloud.google.com
2. Click **Select a project** → **New Project**
3. Name it: `ads-manager-production`
4. Click **Create**

### 2.2 Enable Google Ads API

1. In the Cloud Console, go to **APIs & Services** → **Library**
2. Search for "Google Ads API"
3. Click **Google Ads API**
4. Click **Enable**

### 2.3 Enable OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Select **External** user type
3. Click **Create**
4. Fill in required information:
   - **App name**: AI Ads Manager
   - **User support email**: your-email@domain.com
   - **Developer contact**: your-email@domain.com
5. Click **Save and Continue**

### 2.4 Add Scopes

1. Click **Add or Remove Scopes**
2. Add the following scope:
   ```
   https://www.googleapis.com/auth/adwords
   ```
3. Click **Update** → **Save and Continue**

### 2.5 Add Test Users

1. Click **Add Users**
2. Add your Google Ads account email
3. Click **Save and Continue**

---

## Step 3: Create OAuth 2.0 Credentials

### 3.1 Create OAuth Client ID

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth client ID**
3. Application type: **Web application**
4. Name: `ads-manager-oauth-client`
5. Add Authorized redirect URIs:
   ```
   http://localhost:3001/api/v1/integrations/google-ads/callback
   https://your-domain.com/api/v1/integrations/google-ads/callback
   ```
6. Click **Create**
7. **Save the Client ID and Client Secret** - you'll need these!

### 3.2 Download Credentials

1. Click the download icon next to your OAuth client
2. Save as `google-oauth-credentials.json`
3. Keep this file secure - DO NOT commit to git

---

## Step 4: Get Developer Token

### 4.1 Request Developer Token

1. Log in to your Google Ads **Manager Account**
2. Go to **Tools & Settings** → **Setup** → **API Center**
3. Copy your **Developer Token**
4. Save it securely

> **Important**: The developer token is account-specific. Use the Manager Account's token.

---

## Step 5: Generate Refresh Token

You need to exchange the authorization code for a refresh token.

### 5.1 Run OAuth Flow

Use this script to generate the refresh token:

```javascript
// scripts/google-ads-auth.js
const { google } = require('googleapis');
const readline = require('readline');

const CLIENT_ID = 'your-client-id.apps.googleusercontent.com';
const CLIENT_SECRET = 'your-client-secret';
const REDIRECT_URI = 'http://localhost:3001/api/v1/integrations/google-ads/callback';

const oauth2Client = new google.auth.OAuth2(
  CLIENT_ID,
  CLIENT_SECRET,
  REDIRECT_URI
);

const SCOPES = ['https://www.googleapis.com/auth/adwords'];

// Generate auth URL
const authUrl = oauth2Client.generateAuthUrl({
  access_type: 'offline',
  scope: SCOPES,
  prompt: 'consent'
});

console.log('\n🔐 Authorize this app by visiting this URL:\n');
console.log(authUrl);
console.log('\n');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

rl.question('Enter the code from the redirect URL: ', async (code) => {
  try {
    const { tokens } = await oauth2Client.getToken(code);
    console.log('\n✅ Refresh Token:', tokens.refresh_token);
    console.log('\nAdd this to your .env file:');
    console.log(`GOOGLE_ADS_REFRESH_TOKEN=${tokens.refresh_token}`);
  } catch (error) {
    console.error('❌ Error getting tokens:', error);
  }
  rl.close();
});
```

### 5.2 Run the Script

```bash
cd backend
npm install googleapis
node scripts/google-ads-auth.js
```

### 5.3 Follow the Prompts

1. Visit the URL shown
2. Sign in with your Google Ads account
3. Grant permissions
4. Copy the `code` parameter from the redirect URL
5. Paste it into the terminal
6. Save the **refresh token** displayed

---

## Step 6: Configure Application

### 6.1 Update Backend Environment Variables

Edit `backend/.env`:

```bash
# Google Ads Configuration
GOOGLE_ADS_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_ADS_CLIENT_SECRET=your-client-secret
GOOGLE_ADS_DEVELOPER_TOKEN=your-developer-token
GOOGLE_ADS_REFRESH_TOKEN=your-refresh-token

# Optional: Your Customer ID (without dashes)
GOOGLE_ADS_CUSTOMER_ID=1234567890
```

### 6.2 Store in AWS Secrets Manager (Production)

For production, store these in AWS Secrets Manager:

```bash
aws secretsmanager create-secret \
  --name ads-manager/prod/google-ads \
  --secret-string '{
    "clientId": "your-client-id",
    "clientSecret": "your-client-secret",
    "developerToken": "your-developer-token",
    "refreshToken": "your-refresh-token"
  }'
```

---

## Step 7: Implement Connection in Backend

### 7.1 Update Google Ads Service

Edit `backend/src/modules/integrations/google-ads/google-ads.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleAdsApi, Customer } from 'google-ads-api';

@Injectable()
export class GoogleAdsService {
  private client: GoogleAdsApi;

  constructor(private configService: ConfigService) {
    this.client = new GoogleAdsApi({
      client_id: this.configService.get('GOOGLE_ADS_CLIENT_ID'),
      client_secret: this.configService.get('GOOGLE_ADS_CLIENT_SECRET'),
      developer_token: this.configService.get('GOOGLE_ADS_DEVELOPER_TOKEN'),
    });
  }

  async getCustomer(customerId: string, refreshToken: string): Promise<Customer> {
    return this.client.Customer({
      customer_id: customerId,
      refresh_token: refreshToken,
    });
  }

  async createCampaign(credentials: any, campaignData: any) {
    const customer = await this.getCustomer(
      credentials.customerId,
      credentials.refreshToken
    );

    // Create campaign
    const campaign = customer.campaigns.create({
      name: campaignData.name,
      status: 'PAUSED', // Start paused for review
      advertising_channel_type: this.getChannelType(campaignData.platform),
      campaign_budget: {
        amount_micros: campaignData.budget * 1000000, // Convert to micros
      },
      bidding_strategy_type: 'MAXIMIZE_CONVERSIONS',
    });

    return campaign;
  }

  async getCampaignMetrics(credentials: any, campaignId: string) {
    const customer = await this.getCustomer(
      credentials.customerId,
      credentials.refreshToken
    );

    const results = await customer.query(`
      SELECT
        campaign.id,
        campaign.name,
        metrics.impressions,
        metrics.clicks,
        metrics.cost_micros,
        metrics.conversions,
        metrics.conversions_value
      FROM campaign
      WHERE campaign.id = ${campaignId}
        AND segments.date DURING LAST_30_DAYS
    `);

    return results.map(row => ({
      impressions: row.metrics.impressions,
      clicks: row.metrics.clicks,
      cost: row.metrics.cost_micros / 1000000,
      conversions: row.metrics.conversions,
      revenue: row.metrics.conversions_value,
    }));
  }

  async updateCampaignBudget(credentials: any, campaignId: string, newBudget: number) {
    const customer = await this.getCustomer(
      credentials.customerId,
      credentials.refreshToken
    );

    await customer.campaigns.update({
      resource_name: `customers/${credentials.customerId}/campaigns/${campaignId}`,
      campaign_budget: {
        amount_micros: newBudget * 1000000,
      },
    });
  }

  private getChannelType(platform: string): string {
    const mapping: Record<string, string> = {
      search: 'SEARCH',
      display: 'DISPLAY',
      shopping: 'SHOPPING',
      video: 'VIDEO',
    };
    return mapping[platform] || 'SEARCH';
  }
}
```

---

## Step 8: Test the Integration

### 8.1 Test Connection

Create a test script `backend/scripts/test-google-ads.ts`:

```typescript
import { GoogleAdsApi } from 'google-ads-api';

async function testConnection() {
  const client = new GoogleAdsApi({
    client_id: process.env.GOOGLE_ADS_CLIENT_ID,
    client_secret: process.env.GOOGLE_ADS_CLIENT_SECRET,
    developer_token: process.env.GOOGLE_ADS_DEVELOPER_TOKEN,
  });

  try {
    const customer = client.Customer({
      customer_id: process.env.GOOGLE_ADS_CUSTOMER_ID,
      refresh_token: process.env.GOOGLE_ADS_REFRESH_TOKEN,
    });

    // Test query
    const campaigns = await customer.query(`
      SELECT campaign.id, campaign.name, campaign.status
      FROM campaign
      WHERE campaign.status != 'REMOVED'
      LIMIT 5
    `);

    console.log('✅ Connection successful!');
    console.log('📊 Your campaigns:');
    campaigns.forEach(campaign => {
      console.log(`  - ${campaign.campaign.name} (ID: ${campaign.campaign.id})`);
    });
  } catch (error) {
    console.error('❌ Connection failed:', error);
  }
}

testConnection();
```

Run it:
```bash
npx ts-node scripts/test-google-ads.ts
```

### 8.2 Test via API

```bash
# Connect Google Ads account
curl -X POST http://localhost:3001/api/v1/integrations \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "companyId": "your-company-id",
    "platform": "GOOGLE_ADS",
    "credentials": {
      "customerId": "1234567890",
      "refreshToken": "your-refresh-token"
    }
  }'
```

---

## Troubleshooting

### Error: "Developer token is invalid"

**Solution**:
- Verify you're using the Manager Account's developer token
- Ensure your API access is approved
- Check token is from API Center, not accidentally copied elsewhere

### Error: "Invalid OAuth credentials"

**Solution**:
- Regenerate OAuth credentials in Google Cloud Console
- Ensure redirect URI matches exactly (including http/https)
- Check Client ID and Secret are correct

### Error: "Customer not found"

**Solution**:
- Remove dashes from Customer ID (123-456-7890 → 1234567890)
- Ensure the account has campaigns
- Verify you have access to the customer account

### Error: "Insufficient permissions"

**Solution**:
- Re-run OAuth flow with `prompt: 'consent'` to ensure all scopes are granted
- Check that the Google Ads account has admin access
- Verify the scope `https://www.googleapis.com/auth/adwords` is included

### Rate Limiting

Google Ads API has rate limits:
- **Basic access**: 15,000 operations per day
- **Standard access**: 250,000 operations per day (requires verification)

**Solution**: Implement caching and batch requests

---

## Best Practices

### 1. Use Manager Accounts (MCC)

Always use a Manager Account to manage multiple client accounts. This simplifies:
- Token management (one developer token)
- Billing
- Reporting across accounts

### 2. Cache Data

Cache campaign and metrics data to reduce API calls:

```typescript
// Example: Cache for 5 minutes
@Cacheable({ ttl: 300 })
async getCampaignMetrics(campaignId: string) {
  // ...
}
```

### 3. Batch Operations

Batch multiple operations together:

```typescript
const operations = [
  { create: campaign1 },
  { create: campaign2 },
  { update: campaign3 },
];

await customer.campaigns.mutate(operations);
```

### 4. Error Handling

Always handle API errors gracefully:

```typescript
try {
  await createCampaign(data);
} catch (error) {
  if (error.code === 'QUOTA_EXCEEDED') {
    // Queue for retry
  } else if (error.code === 'INVALID_ARGUMENT') {
    // Log and notify user
  }
  throw error;
}
```

### 5. Webhook for Changes

Set up webhooks to receive notifications when campaigns change:

```typescript
// Backend endpoint for Google Ads webhooks
@Post('webhooks/google-ads')
async handleWebhook(@Body() payload: any) {
  // Process campaign status changes
  // Update local database
  // Trigger notifications
}
```

---

## Security Checklist

- [ ] Developer token stored in environment variables
- [ ] OAuth credentials stored securely (AWS Secrets Manager in production)
- [ ] Refresh tokens encrypted in database
- [ ] API calls use HTTPS only
- [ ] Rate limiting implemented
- [ ] Audit logging enabled
- [ ] Regular token rotation
- [ ] Principle of least privilege for API access

---

## Additional Resources

- **Official Documentation**: https://developers.google.com/google-ads/api/docs/start
- **Node.js Library**: https://github.com/Opteo/google-ads-api
- **API Reference**: https://developers.google.com/google-ads/api/reference/rpc
- **OAuth 2.0 Guide**: https://developers.google.com/identity/protocols/oauth2
- **Community Forum**: https://groups.google.com/g/adwords-api

---

## Next Steps

Once Google Ads is connected:

1. Test campaign creation via the API
2. Set up automated metric syncing (every 1 hour)
3. Implement budget optimization logic
4. Create alerts for campaign issues
5. Move on to integrating Meta Ads (see `META_ADS_SETUP.md`)

**Congratulations!** Your Google Ads integration is complete. The AI can now create and manage campaigns on Google Ads automatically.
