import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AuthModule } from './auth/auth.module.js';
import { EngagementModule } from './engagement/engagement.module.js';
import { HealthController } from './health/health.controller.js';
import { ListingsModule } from './listings/listings.module.js';
import { MessagingModule } from './messaging/messaging.module.js';
import { NotificationsModule } from './notifications/notifications.module.js';
import { PaymentsModule } from './payments/payments.module.js';
import { PrismaModule } from './prisma/prisma.module.js';
import { ReviewsModule } from './reviews/reviews.module.js';
import { UniversitiesModule } from './universities/universities.module.js';
import { UploadsModule } from './uploads/uploads.module.js';
import { UsersModule } from './users/users.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    UsersModule,
    UniversitiesModule,
    ListingsModule,
    MessagingModule,
    EngagementModule,
    NotificationsModule,
    PaymentsModule,
    UploadsModule,
    ReviewsModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
