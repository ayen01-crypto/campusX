import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';

import { JwtAuthGuard } from '../auth/jwt.guard.js';
import type { AuthenticatedUser } from '../auth/jwt.strategy.js';
import { CreateListingDto, ListingQueryDto } from './listings.dto.js';
import { ListingsService } from './listings.service.js';

type UserRequest = { user: AuthenticatedUser };

@Controller('listings')
export class ListingsController {
  constructor(private readonly listings: ListingsService) {}

  @Get()
  list(@Query() query: ListingQueryDto) {
    return this.listings.list(query);
  }

  @UseGuards(JwtAuthGuard)
  @Get('saved/me')
  saved(@Req() request: UserRequest) {
    return this.listings.saved(request.user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  create(@Req() request: UserRequest, @Body() dto: CreateListingDto) {
    return this.listings.create(request.user.userId, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/save')
  toggleSaved(@Req() request: UserRequest, @Param('id') id: string) {
    return this.listings.toggleSaved(request.user.userId, id);
  }

  @Get(':id')
  getById(@Param('id') id: string) {
    return this.listings.getById(id);
  }
}
