import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module.js';
import { ListingsController } from './listings.controller.js';
import { ListingsService } from './listings.service.js';

@Module({
  imports: [AuthModule],
  controllers: [ListingsController],
  providers: [ListingsService],
  exports: [ListingsService],
})
export class ListingsModule {}
