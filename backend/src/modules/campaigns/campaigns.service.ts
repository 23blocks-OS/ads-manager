import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class CampaignsService {
  constructor(private prisma: PrismaService) {}

  async create(data: any) {
    return this.prisma.campaign.create({
      data,
      include: {
        product: true,
        integration: true,
      },
    });
  }

  async findAll(companyId: string) {
    return this.prisma.campaign.findMany({
      where: { companyId },
      include: {
        product: true,
        metrics: {
          orderBy: { date: 'desc' },
          take: 30,
        },
        adCreatives: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: string) {
    return this.prisma.campaign.findUnique({
      where: { id },
      include: {
        product: true,
        integration: true,
        metrics: {
          orderBy: { date: 'desc' },
        },
        adCreatives: true,
        optimizations: {
          orderBy: { appliedAt: 'desc' },
        },
      },
    });
  }

  async update(id: string, data: any) {
    return this.prisma.campaign.update({
      where: { id },
      data,
    });
  }

  async pause(id: string) {
    return this.prisma.campaign.update({
      where: { id },
      data: { status: 'PAUSED' },
    });
  }

  async resume(id: string) {
    return this.prisma.campaign.update({
      where: { id },
      data: { status: 'ACTIVE' },
    });
  }

  async delete(id: string) {
    return this.prisma.campaign.delete({
      where: { id },
    });
  }
}
