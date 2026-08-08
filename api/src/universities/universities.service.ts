import { Injectable } from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service.js';

@Injectable()
export class UniversitiesService {
  constructor(private readonly prisma: PrismaService) {}

  list(search?: string) {
    return this.prisma.university.findMany({
      where: search
        ? {
            OR: [
              { name: { contains: search, mode: 'insensitive' } },
              { city: { contains: search, mode: 'insensitive' } },
            ],
          }
        : undefined,
      orderBy: [{ country: 'asc' }, { city: 'asc' }, { name: 'asc' }],
      select: {
        id: true,
        name: true,
        domain: true,
        city: true,
        country: true,
        latitude: true,
        longitude: true,
        _count: { select: { users: true, listings: true } },
      },
    });
  }
}
