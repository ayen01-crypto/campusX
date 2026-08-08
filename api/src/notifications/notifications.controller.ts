import { Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';

import { JwtAuthGuard } from '../auth/jwt.guard.js';
import type { AuthenticatedUser } from '../auth/jwt.strategy.js';
import { NotificationsService } from './notifications.service.js';

type UserRequest = { user: AuthenticatedUser };

@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Get()
  list(@Req() request: UserRequest, @Query('unreadOnly') unreadOnly?: string) {
    return this.notifications.list(request.user.userId, unreadOnly === 'true');
  }

  @Post('read-all')
  markAllRead(@Req() request: UserRequest) {
    return this.notifications.markAllRead(request.user.userId);
  }

  @Post(':id/read')
  markRead(@Req() request: UserRequest, @Param('id') id: string) {
    return this.notifications.markRead(request.user.userId, id);
  }
}
