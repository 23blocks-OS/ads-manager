import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class IntegrationsService {
  constructor(private prisma: PrismaService) {}

  async connect(companyId: string, platform: string, credentials: any) {
    return this.prisma.integration.create({
      data: {
        companyId,
        platform: platform as any,
        credentials,
        isActive: true,
        status: 'ACTIVE',
      },
    });
  }

  async disconnect(id: string) {
    return this.prisma.integration.update({
      where: { id },
      data: { isActive: false, status: 'DISCONNECTED' },
    });
  }

  async findAll(companyId: string) {
    return this.prisma.integration.findMany({
      where: { companyId },
    });
  }
}
