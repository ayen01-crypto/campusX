import { Body, Controller, Get, Param, Post, Req, UseGuards } from '@nestjs/common';

import { JwtAuthGuard } from '../auth/jwt.guard.js';
import type { AuthenticatedUser } from '../auth/jwt.strategy.js';
import { CreateReviewDto } from './reviews.dto.js';
import { ReviewsService } from './reviews.service.js';

type UserRequest = { user: AuthenticatedUser };

@Controller('reviews')
export class ReviewsController {
  constructor(private readonly reviews: ReviewsService) {}

  @Get('listings/:listingId')
  listForListing(@Param('listingId') listingId: string) {
    return this.reviews.listForListing(listingId);
  }

  @UseGuards(JwtAuthGuard)
  @Post('listings/:listingId')
  create(
    @Req() request: UserRequest,
    @Param('listingId') listingId: string,
    @Body() dto: CreateReviewDto,
  ) {
    return this.reviews.create(request.user.userId, listingId, dto);
  }
}
