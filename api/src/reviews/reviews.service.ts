import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import {
  BookingStatus,
  NotificationType,
  TicketStatus,
} from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateReviewDto } from './reviews.dto.js';

@Injectable()
export class ReviewsService {
  constructor(private readonly prisma: PrismaService) {}

  async listForListing(listingId: string) {
    return this.prisma.review.findMany({
      where: { listingId },
      orderBy: { createdAt: 'desc' },
      include: {
        author: {
          select: { id: true, name: true, avatarUrl: true, verified: true },
        },
      },
    });
  }

  async create(userId: string, listingId: string, dto: CreateReviewDto) {
    const listing = await this.prisma.listing.findUnique({
      where: { id: listingId },
      select: { id: true, title: true, ownerId: true },
    });
    if (!listing) throw new NotFoundException('Listing not found');
    if (listing.ownerId === userId) {
      throw new BadRequestException('You cannot review your own listing');
    }

    const existing = await this.prisma.review.findFirst({
      where: { listingId, authorId: userId },
      select: { id: true },
    });
    if (existing) throw new ConflictException('You have already reviewed this listing');

    const [completedBooking, usedTicket, redeemedDeal] = await Promise.all([
      this.prisma.booking.findFirst({
        where: {
          listingId,
          requesterId: userId,
          status: BookingStatus.COMPLETED,
        },
        select: { id: true },
      }),
      this.prisma.eventTicket.findFirst({
        where: {
          listingId,
          userId,
          status: TicketStatus.USED,
        },
        select: { id: true },
      }),
      this.prisma.dealClaim.findFirst({
        where: {
          listingId,
          userId,
          redeemedAt: { not: null },
        },
        select: { id: true },
      }),
    ]);

    if (!completedBooking && !usedTicket && !redeemedDeal) {
      throw new ForbiddenException(
        'Reviews require a completed booking, used ticket, or redeemed deal.',
      );
    }

    return this.prisma.$transaction(async (tx) => {
      const review = await tx.review.create({
        data: {
          listingId,
          authorId: userId,
          subjectId: listing.ownerId,
          rating: dto.rating,
          comment: dto.comment?.trim(),
        },
        include: {
          author: {
            select: { id: true, name: true, avatarUrl: true, verified: true },
          },
        },
      });

      await tx.notification.create({
        data: {
          userId: listing.ownerId,
          type: NotificationType.LISTING,
          title: 'You received a new review',
          body: `${listing.title} received a ${dto.rating}-star review.`,
          data: { reviewId: review.id, listingId },
        },
      });

      return review;
    });
  }
}
