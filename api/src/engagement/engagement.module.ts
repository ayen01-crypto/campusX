import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module.js';
import { EngagementController } from './engagement.controller.js';
import { EngagementService } from './engagement.service.js';

@Module({
  imports: [AuthModule],
  controllers: [EngagementController],
  providers: [EngagementService],
})
export class EngagementModule {}
