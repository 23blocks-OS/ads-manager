import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class CompaniesService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, data: any) {
    const company = await this.prisma.company.create({
      data: {
        name: data.name,
        description: data.description,
        website: data.website,
        industry: data.industry,
        users: {
          create: {
            userId,
            role: 'OWNER',
          },
        },
      },
    });

    return company;
  }

  async findAll(userId: string) {
    return this.prisma.company.findMany({
      where: {
        users: {
          some: { userId },
        },
      },
      include: {
        products: true,
        campaigns: true,
        budgetSettings: true,
      },
    });
  }

  async findOne(id: string) {
    return this.prisma.company.findUnique({
      where: { id },
      include: {
        brandGuidelines: true,
        budgetSettings: true,
        integrations: true,
        products: true,
        campaigns: {
          include: {
            metrics: {
              orderBy: { date: 'desc' },
              take: 30,
            },
          },
        },
      },
    });
  }

  async update(id: string, data: any) {
    return this.prisma.company.update({
      where: { id },
      data,
    });
  }

  async updateBrandGuidelines(companyId: string, guidelines: any) {
    return this.prisma.brandGuidelines.upsert({
      where: { companyId },
      create: {
        companyId,
        ...guidelines,
      },
      update: guidelines,
    });
  }

  async updateBudgetSettings(companyId: string, settings: any) {
    return this.prisma.budgetSettings.upsert({
      where: { companyId },
      create: {
        companyId,
        ...settings,
      },
      update: settings,
    });
  }
}
