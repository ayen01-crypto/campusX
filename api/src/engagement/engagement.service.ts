import { randomUUID } from 'node:crypto';

import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';

import { ListingKind, ListingStatus, NotificationType } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { BuyTicketDto, CreateApplicationDto, CreateBookingDto } from './engagement.dto.js';

@Injectable()
export class EngagementService {
  constructor(private readonly prisma: PrismaService) {}

  async book(userId: string, listingId: string, dto: CreateBookingDto) {
    const listing = await this.activeListing(listingId);
    if (
      listing.kind !== ListingKind.TUTOR &&
      listing.kind !== ListingKind.SERVICE &&
      listing.kind !== ListingKind.RENTAL
    ) {
      throw new BadRequestException('This listing does not support bookings');
    }
    if (listing.ownerId === userId) throw new BadRequestException('You cannot book your own listing');

    return this.prisma.$transaction(async (tx) => {
      const booking = await tx.booking.create({
        data: {
          listingId,
          requesterId: userId,
          providerId: listing.ownerId,
          scheduledAt: dto.scheduledAt ? new Date(dto.scheduledAt) : undefined,
          note: dto.note?.trim(),
          amount: listing.price,
          currency: listing.currency,
        },
        include: {
          listing: { select: { id: true, title: true, kind: true, images: true } },
          provider: { select: { id: true, name: true, avatarUrl: true, verified: true } },
        },
      });

      await tx.notification.create({
        data: {
          userId: listing.ownerId,
          type: NotificationType.BOOKING,
          title: 'New booking request',
          body: `A CampusX member requested ${listing.title}.`,
          data: { bookingId: booking.id, listingId },
        },
      });
      return booking;
    });
  }

  async apply(userId: string, listingId: string, dto: CreateApplicationDto) {
    const listing = await this.activeListing(listingId);
    if (listing.kind !== ListingKind.INTERNSHIP) {
      throw new BadRequestException('This listing is not an internship');
    }
    if (listing.ownerId === userId) throw new BadRequestException('You cannot apply to your own listing');

    const existing = await this.prisma.internshipApplication.findUnique({
      where: { listingId_userId: { listingId, userId } },
    });
    if (existing) throw new ConflictException('You have already applied to this internship');

    return this.prisma.$transaction(async (tx) => {
      const application = await tx.internshipApplication.create({
        data: {
          listingId,
          userId,
          coverNote: dto.coverNote?.trim(),
          resumeUrl: dto.resumeUrl,
        },
        include: { listing: { select: { id: true, title: true, ownerId: true } } },
      });
      await tx.notification.create({
        data: {
          userId: listing.ownerId,
          type: NotificationType.APPLICATION,
          title: 'New internship application',
          body: `A student applied for ${listing.title}.`,
          data: { applicationId: application.id, listingId },
        },
      });
      return application;
    });
  }

  async buyTicket(userId: string, listingId: string, dto: BuyTicketDto) {
    const listing = await this.activeListing(listingId);
    if (listing.kind !== ListingKind.EVENT) throw new BadRequestException('This listing is not an event');

    const quantity = dto.quantity ?? 1;
    const amount = (listing.price ?? 0) * quantity;

    if (amount === 0) {
      return this.prisma.$transaction(async (tx) => {
        const ticket = await tx.eventTicket.create({
          data: {
            listingId,
            userId,
            quantity,
            amount: 0,
            currency: listing.currency,
            reference: this.reference('TKT'),
            qrToken: randomUUID(),
          },
        });
        await tx.notification.create({
          data: {
            userId,
            type: NotificationType.TICKET,
            title: 'Your CampusX ticket is ready',
            body: `Ticket confirmed for ${listing.title}.`,
            data: { ticketId: ticket.id, listingId },
          },
        });
        return { paymentRequired: false, ticket };
      });
    }

    return this.prisma.$transaction(async (tx) => {
      const payment = await tx.payment.create({
        data: {
          userId,
          provider: 'UNCONFIGURED',
          amount,
          currency: listing.currency,
          metadata: {
            purpose: 'EVENT_TICKET',
            listingId,
            quantity,
          },
        },
      });
      await tx.notification.create({
        data: {
          userId,
          type: NotificationType.PAYMENT,
          title: 'Payment required for your ticket',
          body: `Complete payment to issue your ticket for ${listing.title}.`,
          data: { paymentId: payment.id, listingId },
        },
      });
      return {
        paymentRequired: true,
        payment,
        message: 'Choose a configured payment provider to complete this ticket purchase.',
      };
    });
  }

  async claimDeal(userId: string, listingId: string) {
    const listing = await this.activeListing(listingId);
    if (listing.kind !== ListingKind.DEAL) throw new BadRequestException('This listing is not a deal');

    const existing = await this.prisma.dealClaim.findUnique({
      where: { listingId_userId: { listingId, userId } },
    });
    if (existing) return existing;

    const expiry = listing.metadata && typeof listing.metadata === 'object' && !Array.isArray(listing.metadata)
      ? (listing.metadata as Record<string, unknown>).expiresAt
      : null;

    return this.prisma.$transaction(async (tx) => {
      const claim = await tx.dealClaim.create({
        data: {
          listingId,
          userId,
          code: this.reference('DEAL'),
          expiresAt: typeof expiry === 'string' ? new Date(expiry) : undefined,
        },
      });
      await tx.notification.create({
        data: {
          userId,
          type: NotificationType.DEAL,
          title: 'Student deal claimed',
          body: `${listing.title} is now saved to your CampusX claims.`,
          data: { claimId: claim.id, listingId },
        },
      });
      return claim;
    });
  }

  async myActivity(userId: string) {
    const [bookings, tickets, applications, dealClaims] = await Promise.all([
      this.prisma.booking.findMany({
        where: { requesterId: userId },
        orderBy: { createdAt: 'desc' },
        include: { listing: { select: { id: true, title: true, kind: true, images: true } } },
      }),
      this.prisma.eventTicket.findMany({
        where: { userId },
        orderBy: { purchasedAt: 'desc' },
        include: { listing: { select: { id: true, title: true, kind: true, images: true } } },
      }),
      this.prisma.internshipApplication.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        include: { listing: { select: { id: true, title: true, kind: true } } },
      }),
      this.prisma.dealClaim.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        include: { listing: { select: { id: true, title: true, kind: true } } },
      }),
    ]);

    return { bookings, tickets, applications, dealClaims };
  }

  private async activeListing(id: string) {
    const listing = await this.prisma.listing.findFirst({
      where: { id, status: ListingStatus.ACTIVE },
    });
    if (!listing) throw new NotFoundException('Active listing not found');
    return listing;
  }

  private reference(prefix: string): string {
    return `CX-${prefix}-${Date.now().toString(36).toUpperCase()}-${randomUUID().slice(0, 6).toUpperCase()}`;
  }
}
