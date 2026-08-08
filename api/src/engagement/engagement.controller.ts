import { Body, Controller, Get, Param, Post, Req, UseGuards } from '@nestjs/common';

import { JwtAuthGuard } from '../auth/jwt.guard.js';
import type { AuthenticatedUser } from '../auth/jwt.strategy.js';
import { BuyTicketDto, CreateApplicationDto, CreateBookingDto } from './engagement.dto.js';
import { EngagementService } from './engagement.service.js';

type UserRequest = { user: AuthenticatedUser };

@UseGuards(JwtAuthGuard)
@Controller('engagement')
export class EngagementController {
  constructor(private readonly engagement: EngagementService) {}

  @Get('me')
  mine(@Req() request: UserRequest) {
    return this.engagement.myActivity(request.user.userId);
  }

  @Post('listings/:id/book')
  book(
    @Req() request: UserRequest,
    @Param('id') id: string,
    @Body() dto: CreateBookingDto,
  ) {
    return this.engagement.book(request.user.userId, id, dto);
  }

  @Post('listings/:id/apply')
  apply(
    @Req() request: UserRequest,
    @Param('id') id: string,
    @Body() dto: CreateApplicationDto,
  ) {
    return this.engagement.apply(request.user.userId, id, dto);
  }

  @Post('listings/:id/tickets')
  ticket(
    @Req() request: UserRequest,
    @Param('id') id: string,
    @Body() dto: BuyTicketDto,
  ) {
    return this.engagement.buyTicket(request.user.userId, id, dto);
  }

  @Post('listings/:id/claim')
  claim(@Req() request: UserRequest, @Param('id') id: string) {
    return this.engagement.claimDeal(request.user.userId, id);
  }
}
