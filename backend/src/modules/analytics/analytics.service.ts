import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class AnalyticsService {
  constructor(private prisma: PrismaService) {}

  async getCompanyDashboard(companyId: string) {
    const campaigns = await this.prisma.campaign.findMany({
      where: { companyId },
      include: {
        metrics: {
          orderBy: { date: 'desc' },
          take: 30,
        },
      },
    });

    // Aggregate metrics
    const totalSpend = campaigns.reduce((sum, c) =>
      sum + c.metrics.reduce((s, m) => s + m.spend, 0), 0
    );
    const totalRevenue = campaigns.reduce((sum, c) =>
      sum + c.metrics.reduce((s, m) => s + m.revenue, 0), 0
    );
    const totalConversions = campaigns.reduce((sum, c) =>
      sum + c.metrics.reduce((s, m) => s + m.conversions, 0), 0
    );

    return {
      totalSpend,
      totalRevenue,
      totalConversions,
      roas: totalSpend > 0 ? totalRevenue / totalSpend : 0,
      activeCampaigns: campaigns.filter(c => c.status === 'ACTIVE').length,
      campaigns,
    };
  }
}
