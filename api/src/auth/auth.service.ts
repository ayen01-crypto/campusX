import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';

import { PrismaService } from '../prisma/prisma.service.js';
import { LoginDto, RegisterDto } from './auth.dto.js';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const email = dto.email.trim().toLowerCase();
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) throw new ConflictException('An account with this email already exists');

    const passwordHash = await bcrypt.hash(dto.password, 12);
    const user = await this.prisma.user.create({
      data: {
        name: dto.name.trim(),
        email,
        passwordHash,
        universityId: dto.universityId,
      },
      include: { university: true },
    });

    return this.session(user);
  }

  async login(dto: LoginDto) {
    const email = dto.email.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({
      where: { email },
      include: { university: true },
    });

    if (!user || !(await bcrypt.compare(dto.password, user.passwordHash))) {
      throw new UnauthorizedException('Invalid email or password');
    }

    return this.session(user);
  }

  async me(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { university: true },
    });
    if (!user) throw new UnauthorizedException();
    return this.publicUser(user);
  }

  private async session(user: {
    id: string;
    email: string;
    name: string;
    phone: string | null;
    avatarUrl: string | null;
    bio: string | null;
    verified: boolean;
    capabilities: string[];
    universityId: string | null;
    university: { id: string; name: string; city: string; country: string } | null;
    passwordHash: string;
  }) {
    const accessToken = await this.jwt.signAsync({
      sub: user.id,
      email: user.email,
      capabilities: user.capabilities,
    });

    return {
      accessToken,
      user: this.publicUser(user),
    };
  }

  private publicUser(user: {
    id: string;
    email: string;
    name: string;
    phone: string | null;
    avatarUrl: string | null;
    bio: string | null;
    verified: boolean;
    capabilities: string[];
    universityId: string | null;
    university: { id: string; name: string; city: string; country: string } | null;
  }) {
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      bio: user.bio,
      verified: user.verified,
      capabilities: user.capabilities,
      universityId: user.universityId,
      university: user.university,
    };
  }
}
