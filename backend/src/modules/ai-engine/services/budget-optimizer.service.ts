import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../database/prisma.service';
import { AiEngineService } from '../ai-engine.service';

interface PlatformPerformance {
  platform: string;
  spend: number;
  conversions: number;
  revenue: number;
  roas: number;
  cpa: number;
}

interface BudgetAllocation {
  platform: string;
  currentBudget: number;
  recommendedBudget: number;
  change: number;
  reasoning: string;
}

@Injectable()
export class BudgetOptimizerService {
  constructor(
    private prisma: PrismaService,
    private aiEngine: AiEngineService,
  ) {}

  async optimizeBudgetAllocation(companyId: string): Promise<BudgetAllocation[]> {
    // Get company's budget settings
    const budgetSettings = await this.prisma.budgetSettings.findUnique({
      where: { companyId },
    });

    if (!budgetSettings) {
      throw new Error('Budget settings not found');
    }

    // Get campaign performance data for last 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const campaigns = await this.prisma.campaign.findMany({
      where: {
        companyId,
        status: 'ACTIVE',
      },
      include: {
        metrics: {
          where: {
            date: { gte: thirtyDaysAgo },
          },
        },
      },
    });

    // Calculate platform performance
    const platformPerformance = this.calculatePlatformPerformance(campaigns);

    // Use AI to determine optimal budget allocation
    const allocations = await this.generateBudgetAllocations(
      platformPerformance,
      budgetSettings.totalMonthlyBudget,
    );

    return allocations;
  }

  private calculatePlatformPerformance(campaigns: any[]): PlatformPerformance[] {
    const platformMap = new Map<string, PlatformPerformance>();

    for (const campaign of campaigns) {
      const platform = campaign.platform;

      if (!platformMap.has(platform)) {
        platformMap.set(platform, {
          platform,
          spend: 0,
          conversions: 0,
          revenue: 0,
          roas: 0,
          cpa: 0,
        });
      }

      const perf = platformMap.get(platform)!;

      for (const metric of campaign.metrics) {
        perf.spend += metric.spend;
        perf.conversions += metric.conversions;
        perf.revenue += metric.revenue;
      }
    }

    // Calculate ROAS and CPA
    for (const [_, perf] of platformMap) {
      perf.roas = perf.spend > 0 ? perf.revenue / perf.spend : 0;
      perf.cpa = perf.conversions > 0 ? perf.spend / perf.conversions : 0;
    }

    return Array.from(platformMap.values());
  }

  private async generateBudgetAllocations(
    platformPerformance: PlatformPerformance[],
    totalBudget: number,
  ): Promise<BudgetAllocation[]> {
    const prompt = `You are an expert digital marketing analyst. Based on the following platform performance data, recommend how to allocate a total monthly budget of $${totalBudget}.

Platform Performance (Last 30 days):
${platformPerformance.map(p => `
- ${p.platform}:
  * Spend: $${p.spend.toFixed(2)}
  * Conversions: ${p.conversions}
  * Revenue: $${p.revenue.toFixed(2)}
  * ROAS: ${p.roas.toFixed(2)}
  * CPA: $${p.cpa.toFixed(2)}
`).join('\n')}

Consider:
1. ROAS (Return on Ad Spend) - higher is better
2. CPA (Cost Per Acquisition) - lower is better
3. Current spend vs. performance
4. Potential for scaling
5. Platform saturation

Provide budget recommendations for each platform. Platforms performing well should get more budget, while underperforming platforms should get less or be paused.

Respond with a JSON array matching this structure:
[
  {
    "platform": "GOOGLE_ADS",
    "currentBudget": 1000,
    "recommendedBudget": 1500,
    "change": 500,
    "reasoning": "Strong ROAS of 4.5x indicates room for scaling"
  }
]`;

    const response = await this.aiEngine.generateStructuredResponse<BudgetAllocation[]>(
      prompt,
      'Array<{platform: string, currentBudget: number, recommendedBudget: number, change: number, reasoning: string}>',
    );

    return response;
  }

  async applyBudgetOptimization(
    companyId: string,
    allocations: BudgetAllocation[],
  ): Promise<void> {
    for (const allocation of allocations) {
      // Update active campaigns for this platform
      await this.prisma.campaign.updateMany({
        where: {
          companyId,
          platform: allocation.platform as any,
          status: 'ACTIVE',
        },
        data: {
          budget: allocation.recommendedBudget,
        },
      });

      // Log the optimization
      const campaigns = await this.prisma.campaign.findMany({
        where: {
          companyId,
          platform: allocation.platform as any,
          status: 'ACTIVE',
        },
      });

      for (const campaign of campaigns) {
        await this.prisma.campaignOptimization.create({
          data: {
            campaignId: campaign.id,
            type: 'BUDGET_ADJUSTMENT',
            action: `Adjusted budget from $${allocation.currentBudget} to $${allocation.recommendedBudget}`,
            reasoning: allocation.reasoning,
            previousValue: { budget: allocation.currentBudget },
            newValue: { budget: allocation.recommendedBudget },
            impact: allocation.change,
          },
        });
      }
    }
  }

  async shouldPauseCampaign(campaignId: string): Promise<{
    shouldPause: boolean;
    reason: string;
  }> {
    const campaign = await this.prisma.campaign.findUnique({
      where: { id: campaignId },
      include: {
        metrics: {
          orderBy: { date: 'desc' },
          take: 7, // Last 7 days
        },
      },
    });

    if (!campaign || campaign.metrics.length === 0) {
      return { shouldPause: false, reason: 'Insufficient data' };
    }

    const totalSpend = campaign.metrics.reduce((sum, m) => sum + m.spend, 0);
    const totalConversions = campaign.metrics.reduce((sum, m) => sum + m.conversions, 0);
    const totalRevenue = campaign.metrics.reduce((sum, m) => sum + m.revenue, 0);

    const roas = totalSpend > 0 ? totalRevenue / totalSpend : 0;
    const cpa = totalConversions > 0 ? totalSpend / totalConversions : Infinity;

    // Pause if ROAS < 1 and spent more than $100
    if (roas < 1.0 && totalSpend > 100) {
      return {
        shouldPause: true,
        reason: `Low ROAS of ${roas.toFixed(2)}x after spending $${totalSpend.toFixed(2)}`,
      };
    }

    // Pause if no conversions after spending $200
    if (totalConversions === 0 && totalSpend > 200) {
      return {
        shouldPause: true,
        reason: `No conversions after spending $${totalSpend.toFixed(2)}`,
      };
    }

    return { shouldPause: false, reason: 'Campaign performing adequately' };
  }
}
