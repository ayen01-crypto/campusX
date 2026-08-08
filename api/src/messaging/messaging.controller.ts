import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';

import { JwtAuthGuard } from '../auth/jwt.guard.js';
import type { AuthenticatedUser } from '../auth/jwt.strategy.js';
import { MessagingService } from './messaging.service.js';
import { SendMessageDto, StartConversationDto } from './messaging.dto.js';

type UserRequest = { user: AuthenticatedUser };

@UseGuards(JwtAuthGuard)
@Controller('conversations')
export class MessagingController {
  constructor(private readonly messaging: MessagingService) {}

  @Get()
  list(@Req() request: UserRequest) {
    return this.messaging.listConversations(request.user.userId);
  }

  @Post()
  start(@Req() request: UserRequest, @Body() dto: StartConversationDto) {
    return this.messaging.start(request.user.userId, dto);
  }

  @Get(':id/messages')
  messages(
    @Req() request: UserRequest,
    @Param('id') id: string,
    @Query('cursor') cursor?: string,
    @Query('take') rawTake?: string,
  ) {
    const take = rawTake ? Number(rawTake) : 50;
    return this.messaging.messages(request.user.userId, id, cursor, Number.isFinite(take) ? take : 50);
  }

  @Post(':id/messages')
  send(
    @Req() request: UserRequest,
    @Param('id') id: string,
    @Body() dto: SendMessageDto,
  ) {
    return this.messaging.send(request.user.userId, id, dto);
  }

  @Post(':id/read')
  markRead(@Req() request: UserRequest, @Param('id') id: string) {
    return this.messaging.markRead(request.user.userId, id);
  }
}
