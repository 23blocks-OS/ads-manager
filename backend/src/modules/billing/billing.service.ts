import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class BillingService {
  private stripe: Stripe;

  constructor(
    private configService: ConfigService,
    private prisma: PrismaService,
  ) {
    this.stripe = new Stripe(this.configService.get('STRIPE_SECRET_KEY') || '', {
      apiVersion: '2024-11-20.acacia',
    });
  }

  async createCustomer(companyId: string, email: string) {
    const customer = await this.stripe.customers.create({
      email,
      metadata: { companyId },
    });

    await this.prisma.billingInfo.create({
      data: {
        companyId,
        stripeCustomerId: customer.id,
        plan: 'FREE',
        status: 'ACTIVE',
      },
    });

    return customer;
  }

  async createSubscription(companyId: string, priceId: string) {
    const billing = await this.prisma.billingInfo.findUnique({
      where: { companyId },
    });

    if (!billing) {
      throw new Error('Billing info not found');
    }

    const subscription = await this.stripe.subscriptions.create({
      customer: billing.stripeCustomerId,
      items: [{ price: priceId }],
    });

    await this.prisma.billingInfo.update({
      where: { companyId },
      data: {
        subscriptionId: subscription.id,
        status: 'ACTIVE',
        currentPeriodStart: new Date(subscription.current_period_start * 1000),
        currentPeriodEnd: new Date(subscription.current_period_end * 1000),
      },
    });

    return subscription;
  }
}
