import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

export type AuthenticatedUser = {
  userId: string;
  email: string;
  capabilities: string[];
};

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(config: ConfigService) {
    const secretOrKey = config.get<string>('JWT_SECRET');
    if (!secretOrKey) throw new Error('JWT_SECRET is not configured');

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey,
    });
  }

  validate(payload: { sub: string; email: string; capabilities?: string[] }): AuthenticatedUser {
    return {
      userId: payload.sub,
      email: payload.email,
      capabilities: payload.capabilities ?? [],
    };
  }
}
