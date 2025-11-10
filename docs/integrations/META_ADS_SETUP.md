# Meta (Facebook/Instagram) Ads Integration Guide

This guide walks you through setting up Meta Ads API access for Facebook and Instagram advertising.

## Overview

To integrate Meta Ads, you need:
1. Facebook Business Account
2. Meta Business Manager
3. Facebook App with Marketing API access
4. Ad Account with proper permissions
5. System User Token (recommended) or User Access Token

**Time Required**: 45-90 minutes

## Prerequisites

- Facebook Business Account: https://business.facebook.com
- Ad Account with active campaigns (or create new one)
- Admin access to Business Manager
- Credit card for ad spend verification

---

## Step 1: Set Up Facebook Business Manager

### 1.1 Create Business Manager

1. Go to https://business.facebook.com
2. Click **Create Account**
3. Fill in business details:
   - **Business Name**: Your Company Name
   - **Your Name**: Your full name
   - **Business Email**: your-email@company.com
4. Click **Submit**

### 1.2 Verify Business

1. Go to **Business Settings** → **Business Info**
2. Click **Verify Business**
3. Complete verification (required for Marketing API):
   - Upload business documents
   - Provide business details
   - Wait for approval (1-3 business days)

> **Important**: Marketing API requires verified business

### 1.3 Add Ad Account

1. Go to **Business Settings** → **Accounts** → **Ad Accounts**
2. Click **Add** → **Create a New Ad Account**
3. Name: `AI Ads Manager - Production`
4. Time Zone: Select your timezone
5. Currency: Select your currency
6. Click **Create**
7. **Save your Ad Account ID** (format: act_123456789)

---

## Step 2: Create Facebook App

### 2.1 Register as Developer

1. Go to https://developers.facebook.com
2. Click **My Apps** → **Create App**
3. Select **Business** as app type
4. Click **Continue**

### 2.2 Configure App

Fill in app details:
- **App Name**: AI Ads Manager
- **App Contact Email**: your-email@company.com
- **Business Account**: Select your business
- Click **Create App**

### 2.3 Add Marketing API

1. In your app dashboard, find **Add Products**
2. Find **Marketing API**
3. Click **Set Up**
4. Accept terms and click **Get Started**

### 2.4 Configure App Settings

1. Go to **Settings** → **Basic**
2. Fill in required fields:
   - **App Domains**: `yourdomain.com`
   - **Privacy Policy URL**: `https://yourdomain.com/privacy`
   - **Terms of Service URL**: `https://yourdomain.com/terms`
3. Save changes

### 2.5 Get App Credentials

1. In **Settings** → **Basic**
2. **Save these credentials**:
   - **App ID**: 123456789012345
   - **App Secret**: Click **Show** and copy

---

## Step 3: Set Up System User (Recommended)

System Users provide non-expiring tokens, better for server-to-server applications.

### 3.1 Create System User

1. Go to **Business Settings** → **Users** → **System Users**
2. Click **Add**
3. Name: `AI Ads Manager System User`
4. Role: **Admin**
5. Click **Create System User**

### 3.2 Assign Assets

1. Click on the system user you created
2. Click **Add Assets**
3. Select **Ad Accounts**
4. Choose your ad account
5. Grant **Full control** permissions
6. Click **Save Changes**

### 3.3 Assign App

1. In the same system user settings
2. Click **Add Assets** → **Apps**
3. Select your app
4. Toggle **Manage App** ON
5. Click **Save Changes**

### 3.4 Generate System User Token

1. Click **Generate New Token**
2. Select your app
3. Select required permissions:
   - `ads_management`
   - `ads_read`
   - `business_management`
   - `pages_read_engagement`
   - `pages_manage_ads`
   - `instagram_basic`
   - `instagram_manage_insights`
4. Set expiration: **Never** (recommended for system users)
5. Click **Generate Token**
6. **SAVE THIS TOKEN IMMEDIATELY** - you won't see it again!

---

## Step 4: Configure OAuth Flow (Alternative to System User)

If you prefer user access tokens:

### 4.1 Set Up Facebook Login

1. Go to your app → **Products** → **Facebook Login** → **Settings**
2. Add **Valid OAuth Redirect URIs**:
   ```
   http://localhost:3001/api/v1/integrations/meta-ads/callback
   https://yourdomain.com/api/v1/integrations/meta-ads/callback
   ```
3. Save changes

### 4.2 Generate User Access Token

Use this code to get a long-lived token:

```javascript
// scripts/meta-ads-auth.js
const axios = require('axios');

const APP_ID = 'your-app-id';
const APP_SECRET = 'your-app-secret';
const SHORT_LIVED_TOKEN = 'user-short-lived-token'; // Get from Graph API Explorer

async function getLongLivedToken() {
  try {
    const response = await axios.get('https://graph.facebook.com/v18.0/oauth/access_token', {
      params: {
        grant_type: 'fb_exchange_token',
        client_id: APP_ID,
        client_secret: APP_SECRET,
        fb_exchange_token: SHORT_LIVED_TOKEN,
      },
    });

    console.log('✅ Long-lived token:', response.data.access_token);
    console.log('⏰ Expires in:', response.data.expires_in, 'seconds');

    return response.data.access_token;
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
}

getLongLivedToken();
```

To get a short-lived token:
1. Go to https://developers.facebook.com/tools/explorer/
2. Select your app
3. Click **Get User Access Token**
4. Select required permissions
5. Generate token and use in script above

---

## Step 5: Configure Application

### 5.1 Update Backend Environment Variables

Edit `backend/.env`:

```bash
# Meta Ads Configuration
META_APP_ID=123456789012345
META_APP_SECRET=your-app-secret
META_ACCESS_TOKEN=your-system-user-token-or-long-lived-token

# Your Ad Account ID (with act_ prefix)
META_AD_ACCOUNT_ID=act_123456789
```

### 5.2 Store in AWS Secrets Manager (Production)

```bash
aws secretsmanager create-secret \
  --name ads-manager/prod/meta-ads \
  --secret-string '{
    "appId": "your-app-id",
    "appSecret": "your-app-secret",
    "accessToken": "your-system-user-token"
  }'
```

---

## Step 6: Implement Meta Ads Service

### 6.1 Install Facebook Business SDK

```bash
cd backend
npm install facebook-nodejs-business-sdk
```

### 6.2 Update Meta Ads Service

Edit `backend/src/modules/integrations/meta-ads/meta-ads.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import bizSdk from 'facebook-nodejs-business-sdk';

const { AdAccount, Campaign, AdSet, Ad } = bizSdk;

@Injectable()
export class MetaAdsService {
  private api: any;

  constructor(private configService: ConfigService) {
    bizSdk.FacebookAdsApi.init(
      this.configService.get('META_ACCESS_TOKEN')
    );
    this.api = bizSdk.FacebookAdsApi.get();
  }

  async createCampaign(credentials: any, campaignData: any) {
    const adAccountId = credentials.adAccountId;
    const adAccount = new AdAccount(adAccountId);

    // Create Campaign
    const campaign = await adAccount.createCampaign([], {
      name: campaignData.name,
      objective: this.mapObjective(campaignData.objective),
      status: Campaign.Status.paused, // Start paused
      special_ad_categories: [],
    });

    // Create Ad Set
    const adSet = await adAccount.createAdSet([], {
      name: `${campaignData.name} - AdSet`,
      campaign_id: campaign.id,
      billing_event: AdSet.BillingEvent.impressions,
      optimization_goal: AdSet.OptimizationGoal.reach,
      bid_amount: campaignData.budget * 100, // Convert to cents
      daily_budget: (campaignData.dailyBudget * 100).toString(),
      targeting: this.buildTargeting(campaignData.targetAudience),
      status: AdSet.Status.paused,
    });

    return {
      platformCampaignId: campaign.id,
      adSetId: adSet.id,
    };
  }

  async createAd(credentials: any, adData: any) {
    const adAccountId = credentials.adAccountId;
    const adAccount = new AdAccount(adAccountId);

    // Create Ad Creative
    const creative = await adAccount.createAdCreative([], {
      name: adData.headline,
      object_story_spec: {
        page_id: credentials.pageId,
        link_data: {
          link: adData.landingUrl,
          message: adData.body,
          name: adData.headline,
          description: adData.description,
          call_to_action: {
            type: this.mapCallToAction(adData.callToAction),
            value: { link: adData.landingUrl },
          },
        },
      },
    });

    // Create Ad
    const ad = await adAccount.createAd([], {
      name: adData.headline,
      adset_id: adData.adSetId,
      creative: { creative_id: creative.id },
      status: Ad.Status.paused,
    });

    return {
      adId: ad.id,
      creativeId: creative.id,
    };
  }

  async getCampaignMetrics(credentials: any, campaignId: string) {
    const campaign = new Campaign(campaignId);

    const insights = await campaign.getInsights([
      'impressions',
      'clicks',
      'spend',
      'actions',
      'action_values',
      'ctr',
      'cpc',
      'cpm',
    ], {
      time_range: { since: '2024-01-01', until: '2024-12-31' },
      level: 'campaign',
    });

    return insights.map(insight => ({
      impressions: parseInt(insight.impressions || '0'),
      clicks: parseInt(insight.clicks || '0'),
      spend: parseFloat(insight.spend || '0'),
      conversions: this.getConversions(insight.actions),
      revenue: this.getRevenue(insight.action_values),
      ctr: parseFloat(insight.ctr || '0'),
      cpc: parseFloat(insight.cpc || '0'),
      cpm: parseFloat(insight.cpm || '0'),
    }));
  }

  async updateCampaignBudget(credentials: any, campaignId: string, newBudget: number) {
    const campaign = new Campaign(campaignId);

    await campaign.update([], {
      daily_budget: (newBudget * 100).toString(),
    });
  }

  async pauseCampaign(campaignId: string) {
    const campaign = new Campaign(campaignId);
    await campaign.update([], { status: Campaign.Status.paused });
  }

  async resumeCampaign(campaignId: string) {
    const campaign = new Campaign(campaignId);
    await campaign.update([], { status: Campaign.Status.active });
  }

  private mapObjective(objective: string): string {
    const mapping: Record<string, string> = {
      AWARENESS: Campaign.Objective.brand_awareness,
      TRAFFIC: Campaign.Objective.link_clicks,
      ENGAGEMENT: Campaign.Objective.post_engagement,
      LEADS: Campaign.Objective.lead_generation,
      CONVERSIONS: Campaign.Objective.conversions,
      SALES: Campaign.Objective.product_catalog_sales,
    };
    return mapping[objective] || Campaign.Objective.link_clicks;
  }

  private buildTargeting(targetAudience: any): any {
    return {
      geo_locations: {
        countries: targetAudience.countries || ['US'],
      },
      age_min: targetAudience.ageMin || 18,
      age_max: targetAudience.ageMax || 65,
      genders: targetAudience.genders || [1, 2], // All genders
      interests: targetAudience.interests?.map((interest: string) => ({
        id: interest,
        name: interest,
      })) || [],
    };
  }

  private mapCallToAction(cta: string): string {
    const mapping: Record<string, string> = {
      'Learn More': 'LEARN_MORE',
      'Shop Now': 'SHOP_NOW',
      'Sign Up': 'SIGN_UP',
      'Download': 'DOWNLOAD',
      'Book Now': 'BOOK_TRAVEL',
      'Contact Us': 'CONTACT_US',
    };
    return mapping[cta] || 'LEARN_MORE';
  }

  private getConversions(actions: any[]): number {
    if (!actions) return 0;
    const conversion = actions.find(a =>
      a.action_type === 'offsite_conversion.fb_pixel_purchase' ||
      a.action_type === 'purchase'
    );
    return conversion ? parseInt(conversion.value) : 0;
  }

  private getRevenue(actionValues: any[]): number {
    if (!actionValues) return 0;
    const revenue = actionValues.find(a =>
      a.action_type === 'offsite_conversion.fb_pixel_purchase' ||
      a.action_type === 'purchase'
    );
    return revenue ? parseFloat(revenue.value) : 0;
  }
}
```

---

## Step 7: Set Up Facebook Pixel (For Conversion Tracking)

### 7.1 Create Pixel

1. Go to **Business Settings** → **Data Sources** → **Pixels**
2. Click **Add**
3. Name: `AI Ads Manager Pixel`
4. Click **Create**
5. **Save your Pixel ID**

### 7.2 Install Pixel Code

Add to your landing pages:

```html
<!-- Meta Pixel Code -->
<script>
!function(f,b,e,v,n,t,s)
{if(f.fbq)return;n=f.fbq=function(){n.callMethod?
n.callMethod.apply(n,arguments):n.queue.push(arguments)};
if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
n.queue=[];t=b.createElement(e);t.async=!0;
t.src=v;s=b.getElementsByTagName(e)[0];
s.parentNode.insertBefore(t,s)}(window, document,'script',
'https://connect.facebook.net/en_US/fbevents.js');
fbq('init', 'YOUR_PIXEL_ID');
fbq('track', 'PageView');
</script>
<noscript>
  <img height="1" width="1" style="display:none"
       src="https://www.facebook.com/tr?id=YOUR_PIXEL_ID&ev=PageView&noscript=1"/>
</noscript>
<!-- End Meta Pixel Code -->
```

### 7.3 Track Conversions

Add conversion events:

```javascript
// On purchase
fbq('track', 'Purchase', {
  value: 99.99,
  currency: 'USD'
});

// On lead
fbq('track', 'Lead');

// On sign up
fbq('track', 'CompleteRegistration');
```

### 7.4 Verify Pixel

1. Install Meta Pixel Helper Chrome extension
2. Visit your website
3. Check that pixel fires correctly

---

## Step 8: Request Advanced Access (For Production)

### 8.1 App Review

For production use, request Advanced Access for:

1. Go to **App Review** → **Permissions and Features**
2. Request these permissions:
   - `ads_management` (Standard Access → Advanced Access)
   - `ads_read`
   - `business_management`
   - `pages_manage_ads`
3. For each permission:
   - Explain use case: "Automated campaign management platform"
   - Provide screencast showing the feature
   - Submit for review

**Review time**: 1-5 business days

### 8.2 Complete Verification

1. **Business Verification**: Upload documents
2. **App Verification**: Provide privacy policy, terms
3. **Developer Verification**: Complete individual verification

---

## Step 9: Test the Integration

### 9.1 Test Connection Script

```typescript
// scripts/test-meta-ads.ts
import bizSdk from 'facebook-nodejs-business-sdk';

const AdAccount = bizSdk.AdAccount;

async function testConnection() {
  const accessToken = process.env.META_ACCESS_TOKEN;
  const adAccountId = process.env.META_AD_ACCOUNT_ID;

  bizSdk.FacebookAdsApi.init(accessToken);

  try {
    const account = new AdAccount(adAccountId);
    const accountInfo = await account.read([
      AdAccount.Fields.name,
      AdAccount.Fields.account_status,
      AdAccount.Fields.balance,
      AdAccount.Fields.currency,
    ]);

    console.log('✅ Connection successful!');
    console.log('📊 Ad Account:', accountInfo._data);

    // Test getting campaigns
    const campaigns = await account.getCampaigns([
      'name',
      'status',
      'objective',
    ], {
      limit: 5,
    });

    console.log('\n📈 Your campaigns:');
    campaigns.forEach((campaign: any) => {
      console.log(`  - ${campaign.name} (${campaign.status})`);
    });
  } catch (error) {
    console.error('❌ Connection failed:', error);
  }
}

testConnection();
```

Run it:
```bash
npx ts-node scripts/test-meta-ads.ts
```

### 9.2 Test via API

```bash
# Connect Meta Ads account
curl -X POST http://localhost:3001/api/v1/integrations \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "companyId": "your-company-id",
    "platform": "META_ADS",
    "credentials": {
      "adAccountId": "act_123456789",
      "accessToken": "your-access-token",
      "pageId": "123456789"
    }
  }'
```

---

## Troubleshooting

### Error: "Invalid OAuth access token"

**Solution**:
- Verify token hasn't expired (check expiration time)
- Regenerate system user token
- Ensure app has Marketing API enabled

### Error: "Insufficient permissions"

**Solution**:
- Check system user has full control of ad account
- Verify all required permissions granted
- Request Advanced Access if in production

### Error: "Ad account not found"

**Solution**:
- Ensure Ad Account ID has `act_` prefix
- Verify account exists in Business Manager
- Check system user has access to the account

### Error: "Business verification required"

**Solution**:
- Complete business verification in Business Manager
- Wait for approval (1-3 business days)
- Cannot use Marketing API without verification

### Error: "Rate limit exceeded"

Meta Ads API rate limits:
- **Standard Access**: 200 calls per hour per user
- **Advanced Access**: Custom limits (usually higher)

**Solution**: Implement rate limiting and request queuing

---

## Best Practices

### 1. Use System Users

Always use System Users instead of personal access tokens:
- Non-expiring tokens
- Better security
- No personal data exposure

### 2. Batch Operations

Batch API calls for better performance:

```typescript
const batch = new bizSdk.Batch(api);
batch.add('GET', '/me/adaccounts');
batch.add('GET', '/act_123/campaigns');
const results = await batch.execute();
```

### 3. Async Ad Creation

Use async requests for better performance:

```typescript
const params = {
  name: 'My Campaign',
  objective: 'LINK_CLICKS',
};

const asyncRequest = await adAccount.createCampaignAsync(params);
// Check status later
```

### 4. Webhook for Real-time Updates

Set up webhooks for instant notifications:

```typescript
@Post('webhooks/meta-ads')
async handleWebhook(
  @Body() payload: any,
  @Headers('x-hub-signature-256') signature: string
) {
  // Verify signature
  // Process updates
  // Update database
}
```

### 5. Error Handling

Handle specific Meta errors:

```typescript
try {
  await createCampaign(data);
} catch (error) {
  if (error.error_subcode === 1487390) {
    // Daily budget too low
  } else if (error.error_subcode === 1487124) {
    // Invalid targeting
  }
}
```

---

## Security Checklist

- [ ] System user token stored securely
- [ ] App secret never exposed in client-side code
- [ ] Access tokens encrypted in database
- [ ] Webhook signature verification implemented
- [ ] Rate limiting configured
- [ ] IP whitelisting enabled (if applicable)
- [ ] Regular token rotation policy
- [ ] Audit logging for all API calls

---

## Meta Ads API Limits

### Rate Limits
- **Standard Access**: 200 calls/hour
- **Advanced Access**: Custom limits
- **Ads Insights**: Separate limits

### Ad Account Limits
- **Campaigns**: 5,000 per account
- **Ad Sets**: 10,000 per account
- **Ads**: 10,000 per account

### Budget Limits
- **Minimum daily budget**: $1.00
- **Minimum lifetime budget**: $1.00

---

## Additional Resources

- **Official Documentation**: https://developers.facebook.com/docs/marketing-api
- **Node.js SDK**: https://github.com/facebook/facebook-nodejs-business-sdk
- **API Reference**: https://developers.facebook.com/docs/marketing-api/reference
- **Best Practices**: https://developers.facebook.com/docs/marketing-api/best-practices
- **Support**: https://developers.facebook.com/support

---

## Next Steps

Once Meta Ads is connected:

1. Set up automated metric syncing
2. Implement Pixel tracking on landing pages
3. Create custom audiences
4. Test campaign creation and optimization
5. Move on to LinkedIn Ads (see `LINKEDIN_ADS_SETUP.md`)

**Congratulations!** Your Meta Ads integration is complete. The AI can now create and manage campaigns on Facebook and Instagram automatically.
