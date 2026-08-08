import { Injectable, NotFoundException } from '@nestjs/common';

import { ListingStatus, Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateListingDto, ListingQueryDto } from './listings.dto.js';

@Injectable()
export class ListingsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(query: ListingQueryDto) {
    const where: Prisma.ListingWhereInput = {
      status: ListingStatus.ACTIVE,
      kind: query.kind,
      universityId: query.universityId,
      AND: [
        query.search
          ? {
              OR: [
                { title: { contains: query.search, mode: 'insensitive' } },
                { description: { contains: query.search, mode: 'insensitive' } },
                { tags: { has: query.search.toLowerCase() } },
              ],
            }
          : {},
        query.minPrice != null || query.maxPrice != null
          ? {
              price: {
                gte: query.minPrice,
                lte: query.maxPrice,
              },
            }
          : {},
      ],
    };

    const take = query.take ?? 20;
    const items = await this.prisma.listing.findMany({
      where,
      take: take + 1,
      ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
      orderBy: [{ featuredUntil: 'desc' }, { createdAt: 'desc' }],
      include: {
        owner: {
          select: { id: true, name: true, avatarUrl: true, verified: true },
        },
        university: {
          select: { id: true, name: true, city: true },
        },
        _count: { select: { savedBy: true, reviews: true } },
      },
    });

    const hasMore = items.length > take;
    const data = hasMore ? items.slice(0, take) : items;
    return {
      data,
      nextCursor: hasMore ? data.at(-1)?.id ?? null : null,
    };
  }

  async getById(id: string, viewerId?: string) {
    const listing = await this.prisma.listing.findUnique({
      where: { id },
      include: {
        owner: {
          select: {
            id: true,
            name: true,
            avatarUrl: true,
            verified: true,
            bio: true,
          },
        },
        university: true,
        reviews: {
          take: 20,
          orderBy: { createdAt: 'desc' },
          include: { author: { select: { id: true, name: true, avatarUrl: true } } },
        },
        _count: { select: { savedBy: true, reviews: true } },
      },
    });
    if (!listing) throw new NotFoundException('Listing not found');

    const saved = viewerId
      ? Boolean(
          await this.prisma.savedListing.findUnique({
            where: { userId_listingId: { userId: viewerId, listingId: id } },
          }),
        )
      : false;

    return { ...listing, saved };
  }

  async create(ownerId: string, dto: CreateListingDto) {
    return this.prisma.listing.create({
      data: {
        ownerId,
        kind: dto.kind,
        title: dto.title.trim(),
        subtitle: dto.subtitle?.trim(),
        description: dto.description.trim(),
        price: dto.price,
        currency: dto.currency?.trim().toUpperCase() ?? 'UGX',
        location: dto.location?.trim(),
        latitude: dto.latitude,
        longitude: dto.longitude,
        images: dto.images ?? [],
        tags: (dto.tags ?? []).map((tag) => tag.trim().toLowerCase()).filter(Boolean),
        metadata: dto.metadata as Prisma.InputJsonValue | undefined,
        universityId: dto.universityId,
      },
      include: {
        owner: { select: { id: true, name: true, avatarUrl: true, verified: true } },
        university: { select: { id: true, name: true, city: true } },
      },
    });
  }

  async toggleSaved(userId: string, listingId: string) {
    const listing = await this.prisma.listing.findUnique({ where: { id: listingId }, select: { id: true } });
    if (!listing) throw new NotFoundException('Listing not found');

    const key = { userId_listingId: { userId, listingId } };
    const existing = await this.prisma.savedListing.findUnique({ where: key });
    if (existing) {
      await this.prisma.savedListing.delete({ where: key });
      return { saved: false };
    }

    await this.prisma.savedListing.create({ data: { userId, listingId } });
    return { saved: true };
  }

  async saved(userId: string) {
    const rows = await this.prisma.savedListing.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: {
        listing: {
          include: {
            owner: { select: { id: true, name: true, avatarUrl: true, verified: true } },
            university: { select: { id: true, name: true, city: true } },
          },
        },
      },
    });
    return rows.map((row) => row.listing);
  }
}
