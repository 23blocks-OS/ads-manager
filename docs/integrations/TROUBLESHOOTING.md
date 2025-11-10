# Integration Troubleshooting Guide

Comprehensive troubleshooting guide for all ad platform integrations.

## Table of Contents

- [General Issues](#general-issues)
- [Google Ads Issues](#google-ads-issues)
- [Meta Ads Issues](#meta-ads-issues)
- [LinkedIn Ads Issues](#linkedin-ads-issues)
- [Conversion Tracking Issues](#conversion-tracking-issues)
- [Performance Issues](#performance-issues)
- [FAQ](#faq)

---

## General Issues

### Cannot Connect to Any Platform

**Symptoms**:
- All platform connections fail
- Network timeouts
- DNS resolution errors

**Diagnostic Steps**:
```bash
# Check internet connectivity
ping google.com

# Check DNS resolution
nslookup api.linkedin.com
nslookup graph.facebook.com
nslookup googleads.googleapis.com

# Check if ports are open
telnet api.linkedin.com 443
```

**Solutions**:
1. Verify firewall rules allow outbound HTTPS (port 443)
2. Check proxy settings if behind corporate firewall
3. Verify SSL certificates are valid
4. Check system time is synchronized (OAuth requires accurate time)

### Environment Variables Not Loading

**Symptoms**:
- "undefined" for API keys
- Connection fails with missing credentials

**Diagnostic Steps**:
```bash
# Check .env file exists
ls -la backend/.env

# Verify variables are set (don't print secrets!)
node -e "console.log(process.env.GOOGLE_ADS_CLIENT_ID ? 'Set' : 'Not set')"
```

**Solutions**:
1. Ensure `.env` file in correct directory (`backend/`)
2. Restart application after `.env` changes
3. Check for typos in variable names
4. Verify dotenv is loaded in `main.ts`:
   ```typescript
   import { config } from 'dotenv';
   config();
   ```

### Database Connection Issues

**Symptoms**:
- Cannot save integration credentials
- "Connection refused" to database

**Solutions**:
```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Test connection
psql postgresql://adsmanager:devpassword@localhost:5432/ads_manager

# Check database exists
psql -U adsmanager -c "\l"
```

---

## Google Ads Issues

### "Developer token is invalid"

**Symptoms**:
- API calls return "DEVELOPER_TOKEN_NOT_APPROVED"
- Cannot access campaigns

**Diagnostic Steps**:
1. Check token approval status:
   - Log in to Google Ads Manager Account
   - Go to Tools & Settings → API Center
   - Verify "Access level" shows "Standard" or "Test"

**Solutions**:

**If token shows "Pending":**
- Wait for approval (can take 24-48 hours)
- Check email for approval notification
- Use test account until approved

**If token shows "Test access":**
- You can only use test accounts
- Cannot access production data
- Must complete verification for full access

**If approved but still failing:**
```typescript
// Ensure using Manager Account token
const DEVELOPER_TOKEN = 'token-from-manager-account'; // NOT client account

// Check token in request
console.log('Using developer token:', DEVELOPER_TOKEN.substring(0, 5) + '...');
```

### "Customer ID not found"

**Symptoms**:
- "CUSTOMER_NOT_FOUND" error
- Cannot list campaigns

**Solutions**:
1. **Remove dashes from Customer ID:**
   ```typescript
   // Wrong
   const customerId = '123-456-7890';

   // Correct
   const customerId = '1234567890';
   ```

2. **Use correct account hierarchy:**
   - Manager Account (MCC): Creates developer token
   - Customer Account: Where campaigns live
   - Use Customer ID, not Manager ID for API calls

3. **Verify account access:**
   ```bash
   # Test with Google Ads API
   curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
     "https://googleads.googleapis.com/v14/customers/1234567890"
   ```

### "Insufficient permissions"

**Symptoms**:
- "PERMISSION_DENIED" error
- Cannot create/modify campaigns

**Solutions**:
1. **Re-run OAuth flow with correct scope:**
   ```typescript
   const SCOPES = [
     'https://www.googleapis.com/auth/adwords', // MUST include this exact scope
   ];
   ```

2. **Check account permissions:**
   - Log in to Google Ads
   - Go to Tools & Settings → Access and security
   - Ensure user has "Admin" or "Standard" access

3. **Verify Manager Account link:**
   - Customer account must be linked to Manager Account
   - Manager Account must be approved for API access

### Refresh token expires quickly

**Symptoms**:
- Need to re-authorize frequently
- Token expires after hours/days instead of staying valid

**Solutions**:
```typescript
// Ensure 'offline' access type in OAuth flow
const authUrl = oauth2Client.generateAuthUrl({
  access_type: 'offline', // This is critical!
  scope: SCOPES,
  prompt: 'consent', // Force consent to get refresh token
});
```

**Store refresh token properly:**
```typescript
const { tokens } = await oauth2Client.getToken(code);

// Save this - it won't expire
const refreshToken = tokens.refresh_token;

// Use refresh token to get new access tokens
oauth2Client.setCredentials({
  refresh_token: refreshToken,
});
```

---

## Meta Ads Issues

### "Invalid OAuth access token"

**Symptoms**:
- "Error validating access token"
- API calls return 190 error code

**Diagnostic Steps**:
```bash
# Check token validity
curl "https://graph.facebook.com/debug_token?input_token=YOUR_TOKEN&access_token=YOUR_TOKEN"
```

**Solutions**:

**If token expired:**
- User tokens expire after 60 days
- System User tokens never expire (use these!)
- Implement token refresh:
  ```typescript
  // Exchange short-lived for long-lived token
  const response = await axios.get('https://graph.facebook.com/v18.0/oauth/access_token', {
    params: {
      grant_type: 'fb_exchange_token',
      client_id: APP_ID,
      client_secret: APP_SECRET,
      fb_exchange_token: shortLivedToken,
    },
  });
  ```

**If using System User token:**
1. Go to Business Settings → System Users
2. Regenerate token if needed
3. Ensure token has no expiration set

### "Business verification required"

**Symptoms**:
- "This app must complete business verification"
- Cannot use Marketing API

**Solutions**:
1. **Complete business verification:**
   - Go to Business Settings → Business Info
   - Click "Start verification"
   - Upload required documents:
     - Business license or formation documents
     - Utility bill or bank statement
     - Government-issued ID
   - Wait 1-3 business days for review

2. **While waiting:**
   - You can still test with personal ad account
   - Limited to development/test mode
   - Cannot run production campaigns

### "Ad account not found"

**Symptoms**:
- Cannot access ad account
- "Account does not exist" error

**Solutions**:
1. **Verify Ad Account ID format:**
   ```typescript
   // Must include 'act_' prefix
   const adAccountId = 'act_123456789'; // Correct
   const adAccountId = '123456789'; // Wrong - will fail
   ```

2. **Check account permissions:**
   - Go to Business Settings → Ad Accounts
   - Ensure system user has access to account
   - Grant "Full control" permissions

3. **Verify account exists:**
   ```bash
   curl -X GET "https://graph.facebook.com/v18.0/act_123456789?fields=name,account_status" \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

### "App not set up for Marketing API"

**Symptoms**:
- Marketing API calls fail
- "This endpoint requires the 'ads_management' permission"

**Solutions**:
1. **Add Marketing API product:**
   - Go to developers.facebook.com
   - Select your app
   - Products → Add Product
   - Find "Marketing API" → Set Up

2. **Request Advanced Access:**
   - App Review → Permissions and Features
   - Find "ads_management"
   - Click "Request Advanced Access"
   - Provide use case and screencast
   - Wait for approval (1-5 days)

### Pixel not tracking

**Symptoms**:
- No events showing in Events Manager
- Conversions not tracking

**Diagnostic Steps**:
1. **Install Meta Pixel Helper:**
   - Chrome Extension: Meta Pixel Helper
   - Visit your website
   - Check if pixel fires

2. **Check Events Manager:**
   - Go to Events Manager
   - Select your pixel
   - Check "Test Events" tab
   - Visit website and verify events appear

**Solutions**:
```html
<!-- Ensure pixel installed correctly -->
<script>
  fbq('init', 'YOUR_PIXEL_ID'); // ID must be correct
  fbq('track', 'PageView');
</script>

<!-- Test event firing -->
<script>
  // Should see console message
  fbq('track', 'Purchase', {value: 1.00, currency: 'USD'});
</script>
```

---

## LinkedIn Ads Issues

### "Invalid access token"

**Symptoms**:
- 401 Unauthorized
- "The token used in the request has expired"

**Solutions**:
1. **LinkedIn tokens expire after 60 days:**
   ```typescript
   // Check token expiration
   const tokenData = {
     token: 'YOUR_TOKEN',
     expiresAt: Date.now() + (60 * 24 * 60 * 60 * 1000), // 60 days
   };

   // Refresh before expiry
   if (Date.now() > tokenData.expiresAt - 7 * 24 * 60 * 60 * 1000) {
     // Refresh if less than 7 days remaining
     await refreshToken();
   }
   ```

2. **Implement token refresh:**
   ```typescript
   async function refreshLinkedInToken(refreshToken: string) {
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

### "Marketing Developer Platform access not granted"

**Symptoms**:
- "This application does not have access"
- Cannot use Ads API endpoints

**Solutions**:
1. **Check product access:**
   - Go to developers.linkedin.com
   - Select your app
   - Products tab
   - Verify "Marketing Developer Platform" shows "Access granted"

2. **If pending:**
   - Wait for approval (1-5 business days)
   - Check email for updates
   - In meantime, test with your own account only

3. **Re-apply if rejected:**
   - Review rejection reason
   - Improve application description
   - Provide more detailed use case
   - Submit again

### "Insufficient privileges"

**Symptoms**:
- Cannot create campaigns
- "User does not have permission"

**Solutions**:
1. **Verify Campaign Manager access:**
   - Go to Campaign Manager
   - Check account list
   - Ensure you see the ad account

2. **Check LinkedIn Page admin access:**
   - LinkedIn app requires association with Company Page
   - You must be admin of that page
   - Go to Page → Admin tools → Manage admins

3. **Re-authorize with correct permissions:**
   ```typescript
   const SCOPES = [
     'r_ads',              // Read ads
     'r_ads_reporting',    // Read reporting
     'rw_ads',             // Create/update ads
     'w_organization_social', // Post content (required for Sponsored Content)
   ];
   ```

### Insight Tag not tracking

**Symptoms**:
- No conversion data
- Events not showing in Campaign Manager

**Diagnostic Steps**:
1. Install LinkedIn Insight Tag browser extension
2. Visit your website
3. Check tag fires correctly

**Solutions**:
```html
<!-- Verify Insight Tag installation -->
<script type="text/javascript">
_linkedin_partner_id = "123456"; // Must match your Partner ID
window._linkedin_data_partner_ids = window._linkedin_data_partner_ids || [];
window._linkedin_data_partner_ids.push(_linkedin_partner_id);
</script>

<!-- Test conversion tracking -->
<script>
  // After conversion action
  lintrk('track', { conversion_id: YOUR_CONVERSION_ID });
</script>
```

---

## Conversion Tracking Issues

### Google Ads conversions not tracking

**Solutions**:
1. **Verify conversion action created:**
   - Google Ads → Tools → Conversions
   - Check conversion action exists
   - Note the Conversion ID

2. **Check gtag.js installation:**
   ```html
   <!-- Must be in <head> -->
   <script async src="https://www.googletagmanager.com/gtag/js?id=AW-123456789"></script>
   <script>
     window.dataLayer = window.dataLayer || [];
     function gtag(){dataLayer.push(arguments);}
     gtag('js', new Date());
     gtag('config', 'AW-123456789'); // Your Conversion ID
   </script>
   ```

3. **Fire conversion event:**
   ```javascript
   // On purchase/lead/signup
   gtag('event', 'conversion', {
     'send_to': 'AW-123456789/xxxxx', // Conversion ID/Label
     'value': 99.99,
     'currency': 'USD',
     'transaction_id': 'unique-id-123'
   });
   ```

4. **Test in Google Tag Assistant:**
   - Install Google Tag Assistant Chrome extension
   - Visit page and trigger conversion
   - Verify tag fires

### Meta Pixel events not showing

**Solutions**:
1. **Check Events Manager:**
   - Go to Events Manager
   - Select Pixel
   - Test Events tab
   - Should see events within seconds

2. **Verify domain verification:**
   - Business Settings → Brand Safety → Domains
   - Add and verify your domain
   - Required for iOS 14.5+ tracking

3. **Test pixel firing:**
   ```javascript
   // Add to browser console
   fbq('track', 'ViewContent'); // Should log to console if fbq is loaded

   // Check if pixel loaded
   console.log(typeof fbq); // Should be 'function'
   ```

### Conversion attribution issues

**Common Problems:**
- Conversions credited to wrong campaign
- Missing conversions
- Duplicate conversions

**Solutions**:
1. **Use unique transaction IDs:**
   ```javascript
   const transactionId = 'order-' + Date.now() + '-' + Math.random();

   // All platforms
   gtag('event', 'conversion', { 'transaction_id': transactionId });
   fbq('track', 'Purchase', { transaction_id: transactionId });
   lintrk('track', { conversion_id: 123, transaction_id: transactionId });
   ```

2. **Check attribution windows:**
   - Google Ads: Default 30 days click, 1 day view
   - Meta Ads: Default 7 days click, 1 day view
   - LinkedIn: Default 30 days

3. **Review conversion settings:**
   - Ensure "Include in Conversions" is enabled
   - Check conversion action category
   - Verify value/revenue tracking

---

## Performance Issues

### API rate limits exceeded

**Symptoms**:
- 429 Too Many Requests
- "Quota exceeded" errors

**Solutions**:
1. **Implement exponential backoff:**
   ```typescript
   async function retryWithBackoff(fn: Function, maxRetries = 5) {
     for (let i = 0; i < maxRetries; i++) {
       try {
         return await fn();
       } catch (error) {
         if (error.status === 429 && i < maxRetries - 1) {
           const delay = Math.pow(2, i) * 1000; // 1s, 2s, 4s, 8s, 16s
           await new Promise(resolve => setTimeout(resolve, delay));
         } else {
           throw error;
         }
       }
     }
   }
   ```

2. **Implement request queuing:**
   ```typescript
   import Queue from 'bull';

   const apiQueue = new Queue('api-requests', {
     redis: { host: 'localhost', port: 6379 },
     limiter: {
       max: 100, // 100 requests
       duration: 3600000, // per hour
     },
   });

   apiQueue.process(async (job) => {
     return await makeApiRequest(job.data);
   });
   ```

3. **Cache frequently accessed data:**
   ```typescript
   import { Cache } from 'cache-manager';

   @Injectable()
   export class CampaignService {
     constructor(private cacheManager: Cache) {}

     async getCampaignMetrics(campaignId: string) {
       const cacheKey = `metrics:${campaignId}`;
       const cached = await this.cacheManager.get(cacheKey);

       if (cached) return cached;

       const metrics = await this.fetchFromApi(campaignId);
       await this.cacheManager.set(cacheKey, metrics, 3600); // 1 hour
       return metrics;
     }
   }
   ```

### Slow API responses

**Solutions**:
1. **Batch requests:**
   ```typescript
   // Instead of multiple single requests
   for (const campaign of campaigns) {
     await getCampaignMetrics(campaign.id); // Slow!
   }

   // Batch into single request
   const campaignIds = campaigns.map(c => c.id);
   const allMetrics = await getBatchCampaignMetrics(campaignIds); // Fast!
   ```

2. **Use async/parallel processing:**
   ```typescript
   // Sequential (slow)
   const metrics1 = await getGoogleMetrics();
   const metrics2 = await getMetaMetrics();
   const metrics3 = await getLinkedInMetrics();

   // Parallel (fast)
   const [metrics1, metrics2, metrics3] = await Promise.all([
     getGoogleMetrics(),
     getMetaMetrics(),
     getLinkedInMetrics(),
   ]);
   ```

3. **Optimize database queries:**
   ```typescript
   // Include related data in single query
   const campaigns = await prisma.campaign.findMany({
     include: {
       metrics: { take: 30 }, // Only last 30 days
       product: true,
       company: { select: { name: true } }, // Only needed fields
     },
   });
   ```

### Memory leaks

**Symptoms**:
- Application memory grows over time
- Crashes with "out of memory"

**Solutions**:
1. **Close connections properly:**
   ```typescript
   class ApiService implements OnModuleDestroy {
     async onModuleDestroy() {
       await this.closeConnections();
     }
   }
   ```

2. **Avoid storing large objects in memory:**
   ```typescript
   // Bad
   const allMetrics = []; // Can grow unbounded
   for (const campaign of campaigns) {
     allMetrics.push(await getMetrics(campaign));
   }

   // Good
   for (const campaign of campaigns) {
     const metrics = await getMetrics(campaign);
     await saveToDatabase(metrics); // Process and release
   }
   ```

3. **Monitor memory usage:**
   ```typescript
   setInterval(() => {
     const usage = process.memoryUsage();
     console.log('Memory:', {
       rss: Math.round(usage.rss / 1024 / 1024) + ' MB',
       heapUsed: Math.round(usage.heapUsed / 1024 / 1024) + ' MB',
     });
   }, 60000); // Every minute
   ```

---

## FAQ

### Q: Which ad platform should I integrate first?

**A:** Start with the platform where you have existing campaigns:
- **B2C/E-commerce**: Meta Ads (Facebook/Instagram)
- **B2B/Professional**: LinkedIn Ads
- **High intent search**: Google Ads

### Q: Do I need separate accounts for testing?

**A:** Yes, highly recommended:
- Create test/sandbox accounts
- Use small budgets ($1-5/day)
- Prevent accidental charges during development

### Q: How often should I sync metrics?

**A:**
- **Real-time critical**: Every 15 minutes
- **Standard**: Every 1 hour
- **Daily reports**: Once per day at midnight
- Balance frequency with API limits

### Q: Can I manage multiple client accounts?

**A:** Yes:
- Google Ads: Use Manager Account (MCC)
- Meta Ads: Use Business Manager
- LinkedIn Ads: Create separate ad accounts per client

### Q: What's the minimum budget required?

**A:**
- **Google Ads**: $1/day minimum
- **Meta Ads**: $1/day minimum
- **LinkedIn Ads**: $10/day minimum

### Q: How do I handle time zones?

**A:**
- Store all dates/times in UTC
- Convert to user's timezone for display
- Be aware of platform reporting timezones:
  ```typescript
  const metrics = await getCampaignMetrics(campaignId, {
    dateRange: {
      start: moment().tz('America/New_York').startOf('day').utc(),
      end: moment().tz('America/New_York').endOf('day').utc(),
    },
  });
  ```

### Q: What permissions do system users need?

**A:** Minimum required permissions:
- **Google Ads**: Admin on Manager Account
- **Meta Ads**: Full control on Ad Accounts
- **LinkedIn Ads**: Admin on Company Page + Ad Account Manager

### Q: How do I test without spending money?

**A:**
- Set campaigns to "Paused" status
- Use $0 budget for testing campaign creation
- Test with dormant/expired campaigns
- Use test/development mode where available

### Q: Should I use user tokens or service account tokens?

**A:** Use service/system accounts:
- **Pros**: Don't expire, better security, not tied to individual
- **Cons**: More setup complexity
- **Recommendation**: Always use system users in production

---

## Getting Help

If issues persist:

1. **Check platform status:**
   - Google Ads: https://ads.google.com/status
   - Meta Ads: https://developers.facebook.com/status
   - LinkedIn: https://www.linkedin-status.com

2. **Review API documentation:**
   - Often has troubleshooting sections
   - Check for recent API changes
   - Review deprecation notices

3. **Enable debug logging:**
   ```typescript
   // Temporarily enable verbose logging
   if (process.env.DEBUG_API === 'true') {
     console.log('Request:', request);
     console.log('Response:', response);
   }
   ```

4. **Contact platform support:**
   - Provide API request/response
   - Include error codes and messages
   - Share relevant account IDs

5. **Community forums:**
   - Stack Overflow
   - Platform developer forums
   - GitHub issues (for SDKs)

---

**Last Updated**: 2024-01-10

For additional help, refer to the platform-specific setup guides or contact the development team.
