import { Injectable, NotFoundException } from '@nestjs/common';

import { ListingStatus, UserCapability } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { UpdateProfileDto } from './users.dto.js';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getPublicProfile(id: string) {
    const [user, reputation] = await Promise.all([
      this.prisma.user.findUnique({
        where: { id },
        select: {
          id: true,
          name: true,
          avatarUrl: true,
          bio: true,
          verified: true,
          capabilities: true,
          createdAt: true,
          university: { select: { id: true, name: true, city: true, country: true } },
          listings: {
            where: { status: ListingStatus.ACTIVE },
            take: 12,
            orderBy: { createdAt: 'desc' },
            select: {
              id: true,
              kind: true,
              title: true,
              price: true,
              currency: true,
              location: true,
              images: true,
              createdAt: true,
            },
          },
        },
      }),
      this.prisma.review.aggregate({
        where: { subjectId: id },
        _avg: { rating: true },
        _count: { rating: true },
      }),
    ]);

    if (!user) throw new NotFoundException('User not found');
    return {
      ...user,
      reputation: {
        rating: reputation._avg.rating ?? 0,
        reviews: reputation._count.rating,
      },
    };
  }

  async update(userId: string, dto: UpdateProfileDto) {
    const current = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { capabilities: true },
    });
    if (!current) throw new NotFoundException('User not found');

    let capabilities = dto.capabilities;
    if (capabilities) {
      capabilities = capabilities.filter((capability) => capability !== UserCapability.ADMIN);
      if (current.capabilities.includes(UserCapability.ADMIN)) {
        capabilities = [...new Set([...capabilities, UserCapability.ADMIN])];
      }
    }

    return this.prisma.user.update({
      where: { id: userId },
      data: {
        name: dto.name?.trim(),
        bio: dto.bio?.trim(),
        avatarUrl: dto.avatarUrl,
        universityId: dto.universityId,
        capabilities,
      },
      select: {
        id: true,
        email: true,
        phone: true,
        name: true,
        avatarUrl: true,
        bio: true,
        verified: true,
        capabilities: true,
        universityId: true,
        university: { select: { id: true, name: true, city: true, country: true } },
      },
    });
  }
}
