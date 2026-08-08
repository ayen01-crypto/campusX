import { Controller, Get, Query } from '@nestjs/common';

import { UniversitiesService } from './universities.service.js';

@Controller('universities')
export class UniversitiesController {
  constructor(private readonly universities: UniversitiesService) {}

  @Get()
  list(@Query('search') search?: string) {
    return this.universities.list(search?.trim());
  }
}
