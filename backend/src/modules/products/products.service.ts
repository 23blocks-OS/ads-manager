import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class ProductsService {
  constructor(private prisma: PrismaService) {}

  async create(companyId: string, data: any) {
    return this.prisma.product.create({
      data: {
        companyId,
        ...data,
      },
    });
  }

  async findAll(companyId: string) {
    return this.prisma.product.findMany({
      where: { companyId },
      include: {
        campaigns: {
          include: {
            metrics: {
              orderBy: { date: 'desc' },
              take: 7,
            },
          },
        },
      },
    });
  }

  async findOne(id: string) {
    return this.prisma.product.findUnique({
      where: { id },
      include: {
        campaigns: true,
        adCreatives: true,
      },
    });
  }

  async update(id: string, data: any) {
    return this.prisma.product.update({
      where: { id },
      data,
    });
  }

  async delete(id: string) {
    return this.prisma.product.delete({
      where: { id },
    });
  }
}
