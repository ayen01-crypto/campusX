import 'reflect-metadata';

import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import helmet from 'helmet';

import { AppModule } from './app.module.js';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule, { cors: false });
  const config = app.get(ConfigService);
  const production = config.get<string>('NODE_ENV') === 'production';
  const allowedOrigins = (config.get<string>('APP_ORIGIN') ?? 'http://localhost:3000')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);

  app.setGlobalPrefix('v1');
  app.use(helmet());
  app.enableCors({
    // Codespaces and local web previews use dynamic development origins.
    // Production remains restricted to the explicit APP_ORIGIN allow-list.
    origin: production ? allowedOrigins : true,
    credentials: true,
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.enableShutdownHooks();

  const port = config.get<number>('PORT') ?? 4000;
  await app.listen(port, '0.0.0.0');
}

void bootstrap();
