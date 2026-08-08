import { Module } from '@nestjs/common';

import { UniversitiesController } from './universities.controller.js';
import { UniversitiesService } from './universities.service.js';

@Module({
  controllers: [UniversitiesController],
  providers: [UniversitiesService],
})
export class UniversitiesModule {}
