import { Body, Controller, Param, Post, Req, UseGuards } from '@nestjs/common';

import { JwtAuthGuard } from '../auth/jwt.guard.js';
import type { AuthenticatedUser } from '../auth/jwt.strategy.js';
import { InitiatePaymentDto } from './payments.dto.js';
import { PaymentsService } from './payments.service.js';

type UserRequest = { user: AuthenticatedUser };

@UseGuards(JwtAuthGuard)
@Controller('payments')
export class PaymentsController {
  constructor(private readonly payments: PaymentsService) {}

  @Post(':id/initiate')
  initiate(
    @Req() request: UserRequest,
    @Param('id') id: string,
    @Body() dto: InitiatePaymentDto,
  ) {
    return this.payments.initiate(request.user.userId, id, dto);
  }

  @Post(':id/mock-confirm')
  confirmMock(@Req() request: UserRequest, @Param('id') id: string) {
    return this.payments.confirmMock(request.user.userId, id);
  }
}
