# LinkedIn Ads Integration Guide

This guide walks you through setting up LinkedIn Ads API access for B2B advertising campaigns.

## Overview

To integrate LinkedIn Ads, you need:
1. LinkedIn Company Page
2. LinkedIn Campaign Manager account
3. LinkedIn Developer App
4. OAuth 2.0 access tokens
5. Ad Account with budget

**Time Required**: 30-60 minutes

## Prerequisites

- LinkedIn Company Page (create at https://linkedin.com/company/setup)
- Campaign Manager account: https://www.linkedin.com/campaignmanager
- LinkedIn account with admin access to company page
- Credit card for ad spend

---

## Step 1: Set Up LinkedIn Campaign Manager

### 1.1 Create Campaign Manager Account

1. Go to https://www.linkedin.com/campaignmanager
2. Click **Create an ad account**
3. Fill in account details:
   - **Account name**: AI Ads Manager
   - **Currency**: Select your currency
   - **Associated Company Page**: Select your company page
4. Click **Create Account**

### 1.2 Set Up Billing

1. Go to **Account Assets** → **Billing**
2. Click **Add credit card**
3. Enter payment information
4. Save

### 1.3 Note Your Account Details

Save these for later:
- **Account ID**: Found in URL (`account=123456789`)
- **Account URN**: `urn:li:sponsoredAccount:123456789`

---

## Step 2: Create LinkedIn Developer App

### 2.1 Register as Developer

1. Go to https://www.linkedin.com/developers
2. Click **Create app**
3. Fill in app information:
   - **App name**: AI Ads Manager
   - **LinkedIn Page**: Select your company page
   - **Privacy policy URL**: https://yourdomain.com/privacy
   - **App logo**: Upload your logo
4. Check agreement box
5. Click **Create app**

### 2.2 Get App Credentials

1. In your app, go to **Auth** tab
2. **Save these credentials**:
   - **Client ID**: 86xxxxxxxxxxxxxxxx
   - **Client Secret**: Click **Show** and copy

### 2.3 Configure OAuth Settings

1. Still in **Auth** tab
2. Add **Redirect URLs**:
   ```
   http://localhost:3001/api/v1/integrations/linkedin-ads/callback
   https://yourdomain.com/api/v1/integrations/linkedin-ads/callback
   ```
3. Click **Update**

---

## Step 3: Request API Products Access

### 3.1 Request Marketing Developer Platform

1. In your app, go to **Products** tab
2. Find **Marketing Developer Platform**
3. Click **Request access**
4. Fill in the application:
   - **Use case**: Automated campaign management and optimization
   - **Expected API calls per day**: Your estimate
   - **Additional details**: Describe your platform
5. Submit

**Approval time**: 1-5 business days

> **Note**: While waiting for approval, you can use the app with your own account for testing.

### 3.2 Required Products

Ensure you have access to:
- ✅ **Marketing Developer Platform** (for ads management)
- ✅ **Advertising API** (included in Marketing Developer Platform)
- ✅ **Sign In with LinkedIn** (for OAuth)

---

## Step 4: Generate Access Tokens

### 4.1 OAuth 2.0 Authorization Flow

LinkedIn uses OAuth 2.0. You need to implement the authorization flow:

#### Step 4.1.1: Generate Authorization URL

```typescript
// scripts/linkedin-auth-url.ts
const CLIENT_ID = 'your-client-id';
const REDIRECT_URI = 'http://localhost:3001/api/v1/integrations/linkedin-ads/callback';
const STATE = crypto.randomBytes(16).toString('hex'); // Random state
const SCOPE = 'r_ads,r_ads_reporting,rw_ads,w_organization_social';

const authUrl = 'https://www.linkedin.com/oauth/v2/authorization?' +
  `response_type=code&` +
  `client_id=${CLIENT_ID}&` +
  `redirect_uri=${encodeURIComponent(REDIRECT_URI)}&` +
  `state=${STATE}&` +
  `scope=${encodeURIComponent(SCOPE)}`;

console.log('Visit this URL to authorize:\n');
console.log(authUrl);
```

#### Step 4.1.2: Exchange Code for Access Token

After user authorizes, LinkedIn redirects with a `code` parameter:

```typescript
// scripts/linkedin-get-token.ts
import axios from 'axios';

const CLIENT_ID = 'your-client-id';
const CLIENT_SECRET = 'your-client-secret';
const REDIRECT_URI = 'http://localhost:3001/api/v1/integrations/linkedin-ads/callback';
const AUTHORIZATION_CODE = 'code-from-redirect-url';

async function getAccessToken() {
  try {
    const response = await axios.post(
      'https://www.linkedin.com/oauth/v2/accessToken',
      null,
      {
        params: {
          grant_type: 'authorization_code',
          code: AUTHORIZATION_CODE,
          redirect_uri: REDIRECT_URI,
          client_id: CLIENT_ID,
          client_secret: CLIENT_SECRET,
        },
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      }
    );

    console.log('✅ Access Token:', response.data.access_token);
    console.log('⏰ Expires in:', response.data.expires_in, 'seconds (60 days)');
    console.log('\nSave this token in your .env file:');
    console.log(`LINKEDIN_ACCESS_TOKEN=${response.data.access_token}`);

    return response.data;
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
}

getAccessToken();
```

### 4.2 Refresh Tokens

LinkedIn access tokens expire after 60 days. Implement refresh logic:

```typescript
async function refreshAccessToken(refreshToken: string) {
  const response = await axios.post(
    'https://www.linkedin.com/oauth/v2/accessToken',
    null,
    {
      params: {
        grant_type: 'refresh_token',
        refresh_token: refreshToken,
        client_id: CLIENT_ID,
        client_secret: CLIENT_SECRET,
      },
    }
  );

  return response.data.access_token;
}
```

---

## Step 5: Configure Application

### 5.1 Update Backend Environment Variables

Edit `backend/.env`:

```bash
# LinkedIn Ads Configuration
LINKEDIN_CLIENT_ID=86xxxxxxxxxxxxxxxx
LINKEDIN_CLIENT_SECRET=your-client-secret
LINKEDIN_ACCESS_TOKEN=your-access-token
LINKEDIN_REFRESH_TOKEN=your-refresh-token

# Your Account ID
LINKEDIN_AD_ACCOUNT_ID=123456789
LINKEDIN_AD_ACCOUNT_URN=urn:li:sponsoredAccount:123456789
```

### 5.2 Store in AWS Secrets Manager (Production)

```bash
aws secretsmanager create-secret \
  --name ads-manager/prod/linkedin-ads \
  --secret-string '{
    "clientId": "your-client-id",
    "clientSecret": "your-client-secret",
    "accessToken": "your-access-token",
    "refreshToken": "your-refresh-token"
  }'
```

---

## Step 6: Implement LinkedIn Ads Service

### 6.1 Install Dependencies

```bash
cd backend
npm install axios
```

### 6.2 Update LinkedIn Ads Service

Edit `backend/src/modules/integrations/linkedin-ads/linkedin-ads.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios, { AxiosInstance } from 'axios';

@Injectable()
export class LinkedinAdsService {
  private api: AxiosInstance;
  private baseUrl = 'https://api.linkedin.com/v2';

  constructor(private configService: ConfigService) {
    this.api = axios.create({
      baseURL: this.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'X-Restli-Protocol-Version': '2.0.0',
      },
    });
  }

  private getHeaders(accessToken: string) {
    return {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
      'X-Restli-Protocol-Version': '2.0.0',
    };
  }

  async createCampaign(credentials: any, campaignData: any) {
    const { accessToken, accountId } = credentials;

    // Create Campaign Group (Campaign in LinkedIn terms)
    const campaignGroup = await this.api.post(
      '/adCampaignGroupsV2',
      {
        account: `urn:li:sponsoredAccount:${accountId}`,
        name: campaignData.name,
        status: 'PAUSED',
        runSchedule: {
          start: new Date().getTime(),
        },
        totalBudget: {
          currencyCode: 'USD',
          amount: (campaignData.budget * 1).toString(),
        },
      },
      { headers: this.getHeaders(accessToken) }
    );

    const campaignGroupId = campaignGroup.data.id;

    // Create Campaign (Ad Campaign in LinkedIn terms)
    const campaign = await this.api.post(
      '/adCampaignsV2',
      {
        account: `urn:li:sponsoredAccount:${accountId}`,
        campaignGroup: `urn:li:sponsoredCampaignGroup:${campaignGroupId}`,
        name: `${campaignData.name} - Campaign`,
        type: 'SPONSORED_UPDATES',
        costType: 'CPM',
        dailyBudget: {
          currencyCode: 'USD',
          amount: (campaignData.dailyBudget * 1).toString(),
        },
        unitCost: {
          currencyCode: 'USD',
          amount: '10',
        },
        offsiteDeliveryEnabled: true,
        status: 'PAUSED',
        targetingCriteria: this.buildTargeting(campaignData.targetAudience),
      },
      { headers: this.getHeaders(accessToken) }
    );

    return {
      platformCampaignId: campaign.data.id,
      campaignGroupId: campaignGroupId,
    };
  }

  async createAd(credentials: any, adData: any) {
    const { accessToken, accountId } = credentials;

    // Create Creative
    const creative = await this.api.post(
      '/adCreativesV2',
      {
        account: `urn:li:sponsoredAccount:${accountId}`,
        campaign: `urn:li:sponsoredCampaign:${adData.campaignId}`,
        status: 'PAUSED',
        variables: {
          data: {
            'com.linkedin.ads.SponsoredUpdateCreativeVariables': {
              activity: adData.activityUrn, // Post URN
            },
          },
        },
      },
      { headers: this.getHeaders(accessToken) }
    );

    return {
      creativeId: creative.data.id,
    };
  }

  async getCampaignMetrics(credentials: any, campaignId: string) {
    const { accessToken } = credentials;

    const response = await this.api.get('/adAnalyticsV2', {
      headers: this.getHeaders(accessToken),
      params: {
        q: 'analytics',
        pivot: 'CAMPAIGN',
        campaigns: `urn:li:sponsoredCampaign:${campaignId}`,
        dateRange: {
          start: { year: 2024, month: 1, day: 1 },
          end: { year: 2024, month: 12, day: 31 },
        },
        fields: 'impressions,clicks,costInLocalCurrency,externalWebsiteConversions,conversionValueInLocalCurrency',
        timeGranularity: 'DAILY',
      },
    });

    return response.data.elements.map((element: any) => ({
      impressions: element.impressions || 0,
      clicks: element.clicks || 0,
      spend: (element.costInLocalCurrency || 0) / 1,
      conversions: element.externalWebsiteConversions || 0,
      revenue: (element.conversionValueInLocalCurrency || 0) / 1,
    }));
  }

  async updateCampaignBudget(credentials: any, campaignId: string, newBudget: number) {
    const { accessToken } = credentials;

    await this.api.post(
      `/adCampaignsV2/${campaignId}`,
      {
        patch: {
          $set: {
            dailyBudget: {
              currencyCode: 'USD',
              amount: (newBudget * 1).toString(),
            },
          },
        },
      },
      { headers: this.getHeaders(accessToken) }
    );
  }

  async pauseCampaign(credentials: any, campaignId: string) {
    const { accessToken } = credentials;

    await this.api.post(
      `/adCampaignsV2/${campaignId}`,
      {
        patch: {
          $set: { status: 'PAUSED' },
        },
      },
      { headers: this.getHeaders(accessToken) }
    );
  }

  async resumeCampaign(credentials: any, campaignId: string) {
    const { accessToken } = credentials;

    await this.api.post(
      `/adCampaignsV2/${campaignId}`,
      {
        patch: {
          $set: { status: 'ACTIVE' },
        },
      },
      { headers: this.getHeaders(accessToken) }
    );
  }

  private buildTargeting(targetAudience: any): any {
    const targeting: any = {
      includedTargetingFacets: {},
    };

    // Geographic targeting
    if (targetAudience.locations) {
      targeting.includedTargetingFacets.locations = targetAudience.locations.map(
        (loc: string) => `urn:li:geo:${loc}`
      );
    }

    // Company size
    if (targetAudience.companySizes) {
      targeting.includedTargetingFacets.companySizes = targetAudience.companySizes;
    }

    // Industries
    if (targetAudience.industries) {
      targeting.includedTargetingFacets.industries = targetAudience.industries.map(
        (ind: string) => `urn:li:industry:${ind}`
      );
    }

    // Job functions
    if (targetAudience.jobFunctions) {
      targeting.includedTargetingFacets.jobFunctions = targetAudience.jobFunctions.map(
        (func: string) => `urn:li:function:${func}`
      );
    }

    // Seniority
    if (targetAudience.seniorities) {
      targeting.includedTargetingFacets.seniorities = targetAudience.seniorities.map(
        (sen: string) => `urn:li:seniority:${sen}`
      );
    }

    return targeting;
  }

  async getAvailableTargetingOptions(credentials: any) {
    const { accessToken } = credentials;

    // Get available geo locations
    const geos = await this.api.get('/adTargetingFacets', {
      headers: this.getHeaders(accessToken),
      params: {
        q: 'facets',
        type: 'LOCATION',
      },
    });

    // Get available industries
    const industries = await this.api.get('/adTargetingFacets', {
      headers: this.getHeaders(accessToken),
      params: {
        q: 'facets',
        type: 'INDUSTRY',
      },
    });

    return {
      geos: geos.data.elements,
      industries: industries.data.elements,
    };
  }
}
```

---

## Step 7: Set Up LinkedIn Insight Tag (For Conversion Tracking)

### 7.1 Create Insight Tag

1. Go to Campaign Manager → **Account Assets** → **Insight Tag**
2. Click **Generate Insight Tag**
3. Copy the tag code

### 7.2 Install on Website

Add to all pages (before `</head>`):

```html
<!-- LinkedIn Insight Tag -->
<script type="text/javascript">
_linkedin_partner_id = "123456";
window._linkedin_data_partner_ids = window._linkedin_data_partner_ids || [];
window._linkedin_data_partner_ids.push(_linkedin_partner_id);
</script>
<script type="text/javascript">
(function(l) {
if (!l){window.lintrk = function(a,b){window.lintrk.q.push([a,b])};
window.lintrk.q=[]}
var s = document.getElementsByTagName("script")[0];
var b = document.createElement("script");
b.type = "text/javascript";b.async = true;
b.src = "https://snap.licdn.com/li.lms-analytics/insight.min.js";
s.parentNode.insertBefore(b, s);})(window.lintrk);
</script>
<noscript>
<img height="1" width="1" style="display:none;" alt="" src="https://px.ads.linkedin.com/collect/?pid=123456&fmt=gif" />
</noscript>
<!-- End LinkedIn Insight Tag -->
```

### 7.3 Create Conversion Events

1. In Campaign Manager → **Account Assets** → **Conversions**
2. Click **Create conversion**
3. Configure:
   - **Name**: Purchase / Lead / Sign Up
   - **Conversion window**: 30 days
   - **Value**: Optional
4. Save

### 7.4 Track Conversions in Code

```html
<script>
// Track specific conversion
lintrk('track', { conversion_id: 123456 });
</script>
```

---

## Step 8: Test the Integration

### 8.1 Test Connection Script

```typescript
// scripts/test-linkedin-ads.ts
import axios from 'axios';

async function testConnection() {
  const accessToken = process.env.LINKEDIN_ACCESS_TOKEN;
  const accountId = process.env.LINKEDIN_AD_ACCOUNT_ID;

  try {
    // Test 1: Get account info
    const accountResponse = await axios.get(
      `https://api.linkedin.com/v2/adAccountsV2/${accountId}`,
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'X-Restli-Protocol-Version': '2.0.0',
        },
      }
    );

    console.log('✅ Connection successful!');
    console.log('📊 Ad Account:', accountResponse.data);

    // Test 2: Get campaign groups
    const campaignsResponse = await axios.get(
      'https://api.linkedin.com/v2/adCampaignGroupsV2',
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'X-Restli-Protocol-Version': '2.0.0',
        },
        params: {
          q: 'search',
          search: {
            account: {
              values: [`urn:li:sponsoredAccount:${accountId}`],
            },
          },
        },
      }
    );

    console.log('\n📈 Your campaign groups:');
    campaignsResponse.data.elements.forEach((campaign: any) => {
      console.log(`  - ${campaign.name} (${campaign.status})`);
    });
  } catch (error: any) {
    console.error('❌ Connection failed:', error.response?.data || error.message);
  }
}

testConnection();
```

Run it:
```bash
npx ts-node scripts/test-linkedin-ads.ts
```

### 8.2 Test via API

```bash
# Connect LinkedIn Ads account
curl -X POST http://localhost:3001/api/v1/integrations \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "companyId": "your-company-id",
    "platform": "LINKEDIN_ADS",
    "credentials": {
      "accountId": "123456789",
      "accessToken": "your-access-token"
    }
  }'
```

---

## Troubleshooting

### Error: "Invalid access token"

**Solution**:
- Check token hasn't expired (60 days)
- Regenerate token using OAuth flow
- Ensure Marketing Developer Platform access approved

### Error: "Insufficient privileges"

**Solution**:
- Verify your LinkedIn account is admin of the company page
- Check app has required products enabled
- Ensure Marketing Developer Platform access granted

### Error: "Account not found"

**Solution**:
- Verify Account ID is correct (no `urn:li:` prefix in ID)
- Check account exists in Campaign Manager
- Ensure you have access to the account

### Error: "Resource not found - campaign"

**Solution**:
- Use full URN format: `urn:li:sponsoredCampaign:123456`
- Verify campaign exists
- Check permissions

### Rate Limiting

LinkedIn Ads API has rate limits:
- **Community apps**: Lower limits
- **Partner apps**: Higher limits (requires partnership)

**Solution**: Implement exponential backoff and request queuing

---

## Best Practices

### 1. Token Management

Implement automatic token refresh:

```typescript
async function ensureValidToken(credentials: any) {
  const expiresAt = credentials.tokenExpiresAt;

  if (Date.now() > expiresAt - 86400000) { // Refresh 1 day before expiry
    const newToken = await refreshAccessToken(credentials.refreshToken);
    await updateStoredCredentials(credentials.id, newToken);
    return newToken;
  }

  return credentials.accessToken;
}
```

### 2. Campaign Structure

LinkedIn has a hierarchy:
- **Campaign Group** (overall budget, dates)
  - **Campaign** (targeting, bidding)
    - **Creative** (ad content)

Always create all three for a complete campaign.

### 3. Targeting Best Practices

For B2B campaigns, use:
- **Company size**: Target specific company sizes
- **Job function**: Target decision makers
- **Seniority**: Focus on leadership levels
- **Industries**: Be specific to reduce waste

### 4. Budget Recommendations

LinkedIn minimum budgets:
- **Daily budget**: $10
- **Lifetime budget**: At least $100

### 5. Ad Formats

LinkedIn supports:
- **Sponsored Content**: Native ads in feed
- **Message Ads**: Direct messages
- **Dynamic Ads**: Personalized ads
- **Text Ads**: Simple text-based ads

Choose based on campaign objective.

---

## Security Checklist

- [ ] Access tokens stored securely in Secrets Manager
- [ ] Client secret never exposed in frontend
- [ ] Token refresh implemented
- [ ] HTTPS only for API calls
- [ ] Rate limiting configured
- [ ] Error logging (without exposing tokens)
- [ ] Token expiration monitoring
- [ ] Regular security audits

---

## LinkedIn Ads API Limits

### Rate Limits
- **Community apps**: 100 requests per day per user
- **Partner apps**: Custom limits

### Campaign Limits
- **Campaign Groups per account**: 100,000
- **Campaigns per Campaign Group**: 1,000
- **Creatives per Campaign**: No official limit

### Budget Limits
- **Minimum daily budget**: $10
- **Minimum bid**: Varies by objective

---

## Additional Resources

- **Official Documentation**: https://learn.microsoft.com/en-us/linkedin/marketing/
- **API Reference**: https://learn.microsoft.com/en-us/linkedin/marketing/integrations/ads/advertising-targeting
- **Best Practices**: https://business.linkedin.com/marketing-solutions/best-practices
- **Developer Portal**: https://www.linkedin.com/developers
- **Support**: https://www.linkedin.com/help/lms

---

## Next Steps

Once LinkedIn Ads is connected:

1. Set up automated metric syncing
2. Implement Insight Tag on landing pages
3. Create conversion tracking
4. Test campaign creation and optimization
5. Review integration summary (see `INTEGRATION_SUMMARY.md`)

**Congratulations!** Your LinkedIn Ads integration is complete. The AI can now create and manage B2B campaigns on LinkedIn automatically.
