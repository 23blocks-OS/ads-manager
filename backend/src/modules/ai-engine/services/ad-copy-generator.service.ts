import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../database/prisma.service';
import { AiEngineService } from '../ai-engine.service';

interface AdCopyVariation {
  headline: string;
  description: string;
  body?: string;
  callToAction: string;
}

@Injectable()
export class AdCopyGeneratorService {
  constructor(
    private prisma: PrismaService,
    private aiEngine: AiEngineService,
  ) {}

  async generateAdCopy(
    productId: string,
    platform: string,
    objective: string,
    variations: number = 5,
  ): Promise<AdCopyVariation[]> {
    // Get product and brand info
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
      include: {
        company: {
          include: {
            brandGuidelines: true,
          },
        },
      },
    });

    if (!product) {
      throw new Error('Product not found');
    }

    const brandGuidelines = product.company.brandGuidelines;

    const prompt = `You are an expert copywriter specializing in ${platform} ads. Create ${variations} compelling ad copy variations for:

Product: ${product.name}
Description: ${product.description}
Key Features: ${product.features.join(', ')}
Benefits: ${product.benefits.join(', ')}
Price: $${product.price || 'Contact for pricing'}

Brand Voice: ${brandGuidelines?.brandVoice || 'Professional'}
Target Audience: ${brandGuidelines?.targetAudience || product.targetAudience}
Value Proposition: ${brandGuidelines?.valueProposition || ''}
Unique Selling Points: ${brandGuidelines?.uniqueSellingPoints?.join(', ') || ''}

Words/Phrases to Avoid: ${brandGuidelines?.doNotUse?.join(', ') || 'None'}

Campaign Objective: ${objective}
Platform: ${platform}

Platform-Specific Requirements:
${this.getPlatformRequirements(platform)}

Create ${variations} different ad copy variations that:
1. Match the brand voice and guidelines
2. Highlight different features/benefits
3. Use different emotional appeals
4. Optimize for the campaign objective
5. Follow platform best practices

Respond with a JSON array:
[
  {
    "headline": "Eye-catching headline (max 30 chars)",
    "description": "Compelling description (max 90 chars)",
    "body": "Extended body copy if applicable",
    "callToAction": "Strong CTA"
  }
]`;

    const variations = await this.aiEngine.generateStructuredResponse<AdCopyVariation[]>(
      prompt,
      '',
    );

    return variations;
  }

  private getPlatformRequirements(platform: string): string {
    const requirements: Record<string, string> = {
      GOOGLE_ADS: `
- Headline: Max 30 characters
- Description: Max 90 characters
- Focus on keywords and search intent
- Include price/offer if possible
      `,
      META_ADS: `
- Headline: Max 40 characters
- Primary text: Max 125 characters (but use 40-80 for best results)
- Be visual-first, copy should complement imagery
- Create curiosity and emotion
      `,
      LINKEDIN_ADS: `
- Headline: Max 200 characters
- Intro text: Max 600 characters
- Professional, B2B-focused tone
- Highlight business value and ROI
      `,
      TIKTOK_ADS: `
- Keep it short, snappy, and authentic
- Use trending language and memes (when appropriate)
- Mobile-first, vertical video mindset
- Hook in first 3 seconds
      `,
    };

    return requirements[platform] || 'Follow general best practices for digital advertising';
  }

  async createAdCreatives(
    campaignId: string,
    variations: AdCopyVariation[],
  ): Promise<string[]> {
    const campaign = await this.prisma.campaign.findUnique({
      where: { id: campaignId },
      include: { product: true },
    });

    if (!campaign) {
      throw new Error('Campaign not found');
    }

    const creativeIds: string[] = [];

    for (const variation of variations) {
      const creative = await this.prisma.adCreative.create({
        data: {
          campaignId,
          productId: campaign.productId,
          type: 'TEXT',
          headline: variation.headline,
          description: variation.description,
          body: variation.body,
          callToAction: variation.callToAction,
          landingUrl: campaign.product?.website || '',
          aiGenerated: true,
          isActive: true,
        },
      });

      creativeIds.push(creative.id);
    }

    return creativeIds;
  }

  async generateImageAd(
    productId: string,
    adCopy: AdCopyVariation,
  ): Promise<string> {
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
      include: {
        company: {
          include: {
            brandGuidelines: true,
          },
        },
      },
    });

    if (!product) {
      throw new Error('Product not found');
    }

    const brandGuidelines = product.company.brandGuidelines;

    // Generate image prompt
    const imagePrompt = `Create a professional advertising image for ${product.name}.

Product: ${product.name}
Category: ${product.category}
Ad Headline: ${adCopy.headline}

Style: Modern, clean, professional
Brand Colors: ${brandGuidelines?.colors ? JSON.stringify(brandGuidelines.colors) : 'Professional color palette'}
Mood: Engaging, trustworthy, high-quality

The image should:
- Showcase the product's key benefits
- Match the ad copy message
- Be suitable for digital advertising
- Have clear focal point
- Use high contrast and readable text (if any)

DO NOT include any text in the image - text will be added separately.`;

    try {
      const imageUrl = await this.aiEngine.generateImage(imagePrompt, '1024x1024');
      return imageUrl;
    } catch (error) {
      console.error('Error generating image:', error);
      throw new Error('Failed to generate ad image');
    }
  }

  async testAdCopyPerformance(
    campaignId: string,
  ): Promise<{ topPerformer: any; recommendations: string }> {
    const adCreatives = await this.prisma.adCreative.findMany({
      where: { campaignId },
    });

    if (adCreatives.length < 2) {
      throw new Error('Need at least 2 ad variations to test');
    }

    // In a real implementation, you would pull actual performance metrics
    // For now, we'll simulate analyzing the creatives

    const prompt = `Analyze these ad copy variations and determine which is likely to perform best:

${adCreatives.map((ad, i) => `
Variation ${i + 1}:
- Headline: ${ad.headline}
- Description: ${ad.description}
- Body: ${ad.body || 'N/A'}
- CTA: ${ad.callToAction}
`).join('\n')}

Based on copywriting best practices, which variation is likely to:
1. Get the highest CTR?
2. Drive the most conversions?
3. Best match user intent?

Respond with:
{
  "topPerformerIndex": <number>,
  "reasoning": "string",
  "recommendations": "string with specific suggestions for improvement"
}`;

    const analysis = await this.aiEngine.generateStructuredResponse<{
      topPerformerIndex: number;
      reasoning: string;
      recommendations: string;
    }>(prompt, '');

    return {
      topPerformer: adCreatives[analysis.topPerformerIndex],
      recommendations: analysis.recommendations,
    };
  }
}
