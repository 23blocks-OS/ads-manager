import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../database/prisma.service';
import { AiEngineService } from '../ai-engine.service';

interface CampaignRecommendation {
  platform: string;
  objective: string;
  budget: number;
  targeting: any;
  reasoning: string;
}

@Injectable()
export class CampaignGeneratorService {
  constructor(
    private prisma: PrismaService,
    private aiEngine: AiEngineService,
  ) {}

  async generateCampaignsForProduct(
    productId: string,
    totalBudget: number,
  ): Promise<CampaignRecommendation[]> {
    // Get product details
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
      include: {
        company: {
          include: {
            brandGuidelines: true,
            integrations: {
              where: { isActive: true },
            },
          },
        },
      },
    });

    if (!product) {
      throw new Error('Product not found');
    }

    // Get available platforms
    const availablePlatforms = product.company.integrations.map(i => i.platform);

    if (availablePlatforms.length === 0) {
      throw new Error('No ad platforms connected');
    }

    // Generate campaign strategy using AI
    const recommendations = await this.generateCampaignStrategy(
      product,
      availablePlatforms,
      totalBudget,
    );

    return recommendations;
  }

  private async generateCampaignStrategy(
    product: any,
    availablePlatforms: string[],
    totalBudget: number,
  ): Promise<CampaignRecommendation[]> {
    const brandGuidelines = product.company.brandGuidelines;

    const prompt = `You are an expert digital marketing strategist. Create a comprehensive multi-platform advertising campaign for the following product:

Product Details:
- Name: ${product.name}
- Description: ${product.description}
- Category: ${product.category || 'General'}
- Price: $${product.price || 'N/A'}
- Target Audience: ${product.targetAudience || 'General audience'}
- Key Features: ${product.features.join(', ')}
- Benefits: ${product.benefits.join(', ')}
- Keywords: ${product.keywords.join(', ')}

Brand Guidelines:
- Brand Voice: ${brandGuidelines?.brandVoice || 'Professional'}
- Target Audience: ${brandGuidelines?.targetAudience || 'General'}
- Value Proposition: ${brandGuidelines?.valueProposition || 'N/A'}
- Unique Selling Points: ${brandGuidelines?.uniqueSellingPoints?.join(', ') || 'N/A'}

Available Platforms: ${availablePlatforms.join(', ')}
Total Budget: $${totalBudget}

Create a campaign strategy that:
1. Allocates budget across platforms based on product characteristics
2. Defines objectives for each platform (AWARENESS, TRAFFIC, CONVERSIONS, etc.)
3. Specifies targeting parameters
4. Provides reasoning for each decision

Respond with a JSON array of campaign recommendations:
[
  {
    "platform": "GOOGLE_ADS",
    "objective": "CONVERSIONS",
    "budget": 1500,
    "targeting": {
      "age": "25-54",
      "interests": ["technology", "productivity"],
      "keywords": ["project management software"],
      "locations": ["United States", "Canada"]
    },
    "reasoning": "Google Ads is ideal for capturing high-intent search traffic..."
  }
]`;

    const recommendations = await this.aiEngine.generateStructuredResponse<CampaignRecommendation[]>(
      prompt,
      '',
    );

    return recommendations;
  }

  async createCampaignsFromRecommendations(
    companyId: string,
    productId: string,
    recommendations: CampaignRecommendation[],
  ): Promise<string[]> {
    const campaignIds: string[] = [];

    for (const rec of recommendations) {
      // Find the integration for this platform
      const integration = await this.prisma.integration.findFirst({
        where: {
          companyId,
          platform: rec.platform as any,
          isActive: true,
        },
      });

      if (!integration) {
        console.warn(`Integration not found for platform: ${rec.platform}`);
        continue;
      }

      // Create the campaign
      const campaign = await this.prisma.campaign.create({
        data: {
          companyId,
          productId,
          integrationId: integration.id,
          platform: rec.platform as any,
          name: `AI Generated - ${rec.platform} ${rec.objective}`,
          objective: rec.objective as any,
          status: 'PENDING',
          budget: rec.budget,
          dailyBudget: rec.budget / 30, // Monthly budget divided by 30 days
          startDate: new Date(),
          targetAudience: rec.targeting,
          aiGenerated: true,
        },
      });

      campaignIds.push(campaign.id);

      // Log the creation
      console.log(`Created campaign: ${campaign.name} with budget $${rec.budget}`);
    }

    return campaignIds;
  }

  async optimizeCampaignTargeting(campaignId: string): Promise<any> {
    const campaign = await this.prisma.campaign.findUnique({
      where: { id: campaignId },
      include: {
        metrics: {
          orderBy: { date: 'desc' },
          take: 30, // Last 30 days
        },
        product: true,
      },
    });

    if (!campaign) {
      throw new Error('Campaign not found');
    }

    // Calculate performance by segment (if available)
    const performanceData = this.analyzePerformance(campaign.metrics);

    const prompt = `You are an expert in ad targeting optimization. Analyze this campaign's performance and recommend targeting improvements:

Campaign: ${campaign.name}
Platform: ${campaign.platform}
Current Targeting: ${JSON.stringify(campaign.targetAudience, null, 2)}

Performance Data (Last 30 days):
- Total Impressions: ${performanceData.totalImpressions}
- Total Clicks: ${performanceData.totalClicks}
- Total Conversions: ${performanceData.totalConversions}
- CTR: ${performanceData.ctr.toFixed(2)}%
- Conversion Rate: ${performanceData.conversionRate.toFixed(2)}%
- Average CPA: $${performanceData.avgCpa.toFixed(2)}
- ROAS: ${performanceData.roas.toFixed(2)}x

Based on this performance, recommend targeting adjustments:
1. What targeting parameters should be expanded?
2. What should be narrowed?
3. What new audiences should be tested?

Respond with a JSON object:
{
  "currentPerformanceAssessment": "string",
  "recommendedTargeting": {
    // updated targeting parameters
  },
  "reasoning": "string",
  "expectedImpact": "string"
}`;

    const recommendation = await this.aiEngine.generateStructuredResponse(prompt, '');

    return recommendation;
  }

  private analyzePerformance(metrics: any[]) {
    const totals = metrics.reduce(
      (acc, m) => ({
        impressions: acc.impressions + m.impressions,
        clicks: acc.clicks + m.clicks,
        conversions: acc.conversions + m.conversions,
        spend: acc.spend + m.spend,
        revenue: acc.revenue + m.revenue,
      }),
      { impressions: 0, clicks: 0, conversions: 0, spend: 0, revenue: 0 },
    );

    return {
      totalImpressions: totals.impressions,
      totalClicks: totals.clicks,
      totalConversions: totals.conversions,
      ctr: totals.impressions > 0 ? (totals.clicks / totals.impressions) * 100 : 0,
      conversionRate: totals.clicks > 0 ? (totals.conversions / totals.clicks) * 100 : 0,
      avgCpa: totals.conversions > 0 ? totals.spend / totals.conversions : 0,
      roas: totals.spend > 0 ? totals.revenue / totals.spend : 0,
    };
  }
}
