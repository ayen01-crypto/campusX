import { randomUUID } from 'node:crypto';

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { PaymentStatus } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { InitiatePaymentDto } from './payments.dto.js';

@Injectable()
export class PaymentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  async initiate(userId: string, paymentId: string, dto: InitiatePaymentDto) {
    const payment = await this.prisma.payment.findFirst({
      where: { id: paymentId, userId },
    });
    if (!payment) throw new NotFoundException('Payment not found');
    if (payment.status === PaymentStatus.PAID) return payment;
    if (![PaymentStatus.PENDING, PaymentStatus.FAILED].includes(payment.status)) {
      throw new BadRequestException(`Payment cannot be initiated from ${payment.status}`);
    }

    if (dto.provider === 'MOCK') {
      if (this.config.get<string>('NODE_ENV') === 'production') {
        throw new ForbiddenException('Mock payments are disabled in production');
      }

      return this.prisma.payment.update({
        where: { id: payment.id },
        data: {
          provider: 'MOCK',
          providerRef: `MOCK-${randomUUID()}`,
          status: PaymentStatus.PROCESSING,
          metadata: {
            ...(this.objectMetadata(payment.metadata)),
            phone: dto.phone,
          },
        },
      });
    }

    throw new ServiceUnavailableException(
      `${dto.provider} credentials/adapter are not configured yet. Add provider credentials before enabling production collection.`,
    );
  }

  async confirmMock(userId: string, paymentId: string) {
    if (this.config.get<string>('NODE_ENV') === 'production') {
      throw new ForbiddenException('Mock payment confirmation is disabled in production');
    }

    const payment = await this.prisma.payment.findFirst({
      where: { id: paymentId, userId },
    });
    if (!payment) throw new NotFoundException('Payment not found');
    if (payment.provider !== 'MOCK') throw new BadRequestException('This is not a mock payment');
    if (payment.status === PaymentStatus.PAID) return payment;

    return this.finalizePaid(payment.id);
  }

  private async finalizePaid(paymentId: string) {
    return this.prisma.$transaction(async (tx) => {
      const payment = await tx.payment.findUnique({ where: { id: paymentId } });
      if (!payment) throw new NotFoundException('Payment not found');
      if (payment.status === PaymentStatus.PAID) return payment;

      const metadata = this.objectMetadata(payment.metadata);
      if (metadata.purpose === 'EVENT_TICKET') {
        const listingId = typeof metadata.listingId === 'string' ? metadata.listingId : null;
        const quantity = typeof metadata.quantity === 'number' ? Math.max(1, Math.floor(metadata.quantity)) : 1;
        if (!listingId) throw new BadRequestException('Payment is missing event metadata');

        const listing = await tx.listing.findUnique({ where: { id: listingId } });
        if (!listing) throw new NotFoundException('Event listing not found');

        const ticket = await tx.eventTicket.create({
          data: {
            listingId,
            userId: payment.userId,
            reference: this.reference('TKT'),
            qrToken: randomUUID(),
            quantity,
            amount: payment.amount,
            currency: payment.currency,
          },
        });

        return tx.payment.update({
          where: { id: payment.id },
          data: {
            status: PaymentStatus.PAID,
            ticketId: ticket.id,
          },
          include: { ticket: true },
        });
      }

      return tx.payment.update({
        where: { id: payment.id },
        data: { status: PaymentStatus.PAID },
      });
    });
  }

  private objectMetadata(value: unknown): Record<string, unknown> {
    return value && typeof value === 'object' && !Array.isArray(value)
      ? (value as Record<string, unknown>)
      : {};
  }

  private reference(prefix: string): string {
    return `CX-${prefix}-${Date.now().toString(36).toUpperCase()}-${randomUUID().slice(0, 6).toUpperCase()}`;
  }
}
