# Ad Platform Integrations

Complete guides for connecting your AI Ads Manager platform to all major advertising platforms.

## 📚 Documentation Index

### Quick Start
- **[Integration Summary](./INTEGRATION_SUMMARY.md)** - Overview of all platforms, credentials needed, and quick reference

### Platform-Specific Guides
1. **[Google Ads Setup](./GOOGLE_ADS_SETUP.md)** - Step-by-step guide for Google Ads API integration
2. **[Meta Ads Setup](./META_ADS_SETUP.md)** - Complete guide for Facebook & Instagram Ads
3. **[LinkedIn Ads Setup](./LINKEDIN_ADS_SETUP.md)** - LinkedIn Marketing Developer Platform integration

### Support
- **[Troubleshooting Guide](./TROUBLESHOOTING.md)** - Common issues, solutions, and FAQ for all platforms

---

## 🚀 Getting Started

### 1. Choose Your Platform

Start with the platform most relevant to your business:

| Platform | Best For | Difficulty | Time | Budget |
|----------|----------|------------|------|--------|
| **Google Ads** | Search intent, high-converting keywords | Medium | 1-2 hours | $1/day min |
| **Meta Ads** | Visual products, broad audiences, B2C | Medium | 1-2 hours | $1/day min |
| **LinkedIn Ads** | B2B, professional services, enterprise | Easy | 30-60 min | $10/day min |

### 2. Prerequisites

Before starting any integration:

✅ Business registered with valid documentation
✅ Company website with privacy policy
✅ Payment method ready
✅ Email access for verification
✅ Admin access to advertising accounts

### 3. Integration Process

Each platform follows a similar process:

```
1. Create Developer Account
   ↓
2. Register Application
   ↓
3. Request API Access
   ↓
4. Configure OAuth
   ↓
5. Generate Credentials
   ↓
6. Test Connection
   ↓
7. Set Up Conversion Tracking
   ↓
8. Go Live
```

---

## 📖 Platform Guides

### Google Ads Integration

**Time Required**: 1-2 hours (plus 24-48 hours approval)

**What You'll Get**:
- Developer Token
- OAuth Client ID & Secret
- Refresh Token
- Customer ID

**Steps**:
1. Apply for Google Ads API access
2. Create Google Cloud Project
3. Enable Google Ads API
4. Set up OAuth 2.0
5. Generate refresh token
6. Install conversion tracking
7. Test integration

[📘 Full Google Ads Guide →](./GOOGLE_ADS_SETUP.md)

---

### Meta Ads Integration

**Time Required**: 1-2 hours (plus 1-5 days approval)

**What You'll Get**:
- App ID & Secret
- System User Access Token
- Ad Account ID
- Facebook Pixel ID

**Steps**:
1. Create Facebook Business Manager
2. Register Facebook App
3. Add Marketing API product
4. Create System User
5. Generate access token
6. Install Facebook Pixel
7. Request Advanced Access
8. Test integration

[📘 Full Meta Ads Guide →](./META_ADS_SETUP.md)

---

### LinkedIn Ads Integration

**Time Required**: 30-60 minutes (plus 1-5 days approval)

**What You'll Get**:
- Client ID & Secret
- Access Token
- Refresh Token
- Ad Account ID

**Steps**:
1. Create LinkedIn Campaign Manager account
2. Register LinkedIn App
3. Request Marketing Developer Platform access
4. Configure OAuth
5. Generate tokens
6. Install Insight Tag
7. Test integration

[📘 Full LinkedIn Ads Guide →](./LINKEDIN_ADS_SETUP.md)

---

## 🔐 Security Best Practices

### Credential Storage

**Development**:
```bash
# .env file (NEVER commit to git)
GOOGLE_ADS_CLIENT_SECRET=xxxxx
META_APP_SECRET=xxxxx
LINKEDIN_CLIENT_SECRET=xxxxx
```

**Production**:
```bash
# AWS Secrets Manager
aws secretsmanager create-secret \
  --name ads-manager/prod/credentials \
  --secret-string '{"googleAds":{...},"metaAds":{...}}'
```

### Token Management

- ✅ Encrypt tokens before database storage
- ✅ Implement automatic token refresh
- ✅ Monitor token expiration
- ✅ Rotate tokens regularly
- ✅ Use system/service accounts (not personal)
- ❌ Never log tokens in plain text
- ❌ Never expose secrets in client-side code

### API Security

```typescript
// Example: Secure credential handling
import { encrypt, decrypt } from './crypto';

// Store
const encryptedCredentials = encrypt(JSON.stringify(credentials));
await prisma.integration.create({
  data: { credentials: encryptedCredentials },
});

// Retrieve
const integration = await prisma.integration.findUnique({...});
const credentials = JSON.parse(decrypt(integration.credentials));
```

---

## 🎯 Conversion Tracking

All platforms require conversion tracking for ROI measurement. Install tracking codes on your website:

### Universal Tracking Code

```html
<!DOCTYPE html>
<html>
<head>
  <!-- Google Ads -->
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
</html>
```

### Track Conversions

```javascript
// On purchase/conversion
function trackConversion(value, currency = 'USD', orderId) {
  // Google Ads
  gtag('event', 'conversion', {
    'send_to': 'AW-123456789/xxxxx',
    'value': value,
    'currency': currency,
    'transaction_id': orderId
  });

  // Meta Pixel
  fbq('track', 'Purchase', {
    value: value,
    currency: currency,
    content_ids: [orderId]
  });

  // LinkedIn
  lintrk('track', {
    conversion_id: 123456,
    transaction_id: orderId
  });
}
```

---

## 🔧 Testing Your Integration

### 1. Connection Test

```bash
# Test each platform
npm run test:google-ads
npm run test:meta-ads
npm run test:linkedin-ads
```

### 2. API Test

```bash
# Create test campaign via API
curl -X POST http://localhost:3001/api/v1/campaigns \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "companyId": "uuid",
    "platform": "GOOGLE_ADS",
    "name": "Test Campaign",
    "budget": 10.00
  }'
```

### 3. Conversion Tracking Test

1. Install browser extensions:
   - Google Tag Assistant
   - Meta Pixel Helper
   - LinkedIn Insight Tag Helper

2. Visit your website
3. Trigger conversion event
4. Verify tags fire correctly

---

## ❓ Common Questions

### How long does setup take?

- **Google Ads**: 1-2 hours + 24-48 hours approval
- **Meta Ads**: 1-2 hours + 1-5 days approval (business verification)
- **LinkedIn Ads**: 30-60 minutes + 1-5 days approval

### Do I need separate accounts for testing?

Yes! Create test accounts to avoid:
- Accidental charges
- Affecting production campaigns
- API quota consumption

### What are the minimum budgets?

- **Google Ads**: $1/day
- **Meta Ads**: $1/day
- **LinkedIn Ads**: $10/day

### Can I manage multiple client accounts?

Yes:
- **Google Ads**: Use Manager Account (MCC)
- **Meta Ads**: Use Business Manager
- **LinkedIn Ads**: Multiple ad accounts per app

### How often do tokens expire?

- **Google Ads**: Refresh tokens don't expire (if offline access granted)
- **Meta Ads**: System user tokens never expire; user tokens expire in 60 days
- **LinkedIn Ads**: Access tokens expire in 60 days

### What if my API access is denied?

- Review application carefully
- Provide detailed use case
- Include screenshots/demo video
- Re-apply with improvements
- Contact platform support if needed

---

## 🐛 Troubleshooting

Having issues? Check the [Troubleshooting Guide](./TROUBLESHOOTING.md) for:

- Connection problems
- Authentication errors
- Permission issues
- Rate limiting
- Conversion tracking problems
- Platform-specific issues

Common issues:

| Issue | Platform | Solution |
|-------|----------|----------|
| Invalid token | All | Check expiration, refresh token |
| Permission denied | All | Re-authorize with correct scopes |
| Rate limit | All | Implement exponential backoff |
| Business verification required | Meta | Complete in Business Settings |
| Developer token invalid | Google | Use Manager Account token |
| Insufficient privileges | LinkedIn | Check page admin access |

---

## 📊 Next Steps

After completing integrations:

1. ✅ **Verify All Connections**
   - Test each platform
   - Confirm data syncing
   - Check conversion tracking

2. ✅ **Set Up Automation**
   - Configure metric syncing schedule
   - Enable budget optimization
   - Set up alerts and notifications

3. ✅ **Create First Campaign**
   - Add company and product
   - Let AI generate campaigns
   - Review and approve
   - Launch!

4. ✅ **Monitor Performance**
   - Check dashboard daily
   - Review AI optimizations
   - Analyze conversion data
   - Adjust strategy as needed

---

## 📚 Additional Resources

### Official Documentation
- [Google Ads API Docs](https://developers.google.com/google-ads/api)
- [Meta Marketing API Docs](https://developers.facebook.com/docs/marketing-api)
- [LinkedIn Marketing API Docs](https://learn.microsoft.com/en-us/linkedin/marketing/)

### Developer Communities
- [Google Ads API Forum](https://groups.google.com/g/adwords-api)
- [Meta Developers Community](https://developers.facebook.com/community)
- [LinkedIn Developer Forums](https://www.linkedin.com/help/lms)

### Internal Documentation
- [Platform Architecture](../README.md)
- [Deployment Guide](../DEPLOYMENT.md)
- [Getting Started](../GETTING_STARTED.md)

---

## 💬 Support

Need help?

1. **Check Documentation**
   - Review platform-specific guide
   - Check troubleshooting section
   - Search FAQ

2. **Test Scripts**
   - Run connection tests
   - Check logs for errors
   - Verify credentials

3. **Platform Support**
   - Google Ads Support
   - Meta Business Support
   - LinkedIn Help Center

4. **Internal Support**
   - Create GitHub issue
   - Contact development team
   - Check community discussions

---

**Ready to connect your first platform?** Choose a guide above and get started!

All integrations are designed to work seamlessly with the AI optimization engine. Once connected, the platform will automatically:
- Create campaigns based on your products
- Optimize budgets across platforms
- Generate ad copy variations
- Adjust bids in real-time
- Report on performance
- Send alerts for issues

**Happy integrating! 🚀**
