import { Body, Controller, Get, Param, Patch, Req, UseGuards } from '@nestjs/common';

import { JwtAuthGuard } from '../auth/jwt.guard.js';
import type { AuthenticatedUser } from '../auth/jwt.strategy.js';
import { UpdateProfileDto } from './users.dto.js';
import { UsersService } from './users.service.js';

type UserRequest = { user: AuthenticatedUser };

@Controller('users')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @UseGuards(JwtAuthGuard)
  @Patch('me')
  updateMe(@Req() request: UserRequest, @Body() dto: UpdateProfileDto) {
    return this.users.update(request.user.userId, dto);
  }

  @Get(':id')
  profile(@Param('id') id: string) {
    return this.users.getPublicProfile(id);
  }
}
