import {
  BadRequestException,
  Controller,
  Get,
  Param,
  Post,
  Req,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Response } from 'express';

import { JwtAuthGuard } from '../auth/jwt.guard.js';
import type { AuthenticatedUser } from '../auth/jwt.strategy.js';
import { UploadsService } from './uploads.service.js';

type UserRequest = { user: AuthenticatedUser };

@Controller('uploads')
export class UploadsController {
  constructor(private readonly uploads: UploadsService) {}

  @UseGuards(JwtAuthGuard)
  @Post()
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: 10 * 1024 * 1024 },
      fileFilter: (_request, file, callback) => {
        const allowed = /^(image\/(jpeg|png|webp|gif)|application\/pdf)$/.test(file.mimetype);
        callback(allowed ? null : new BadRequestException('Only images and PDF files are allowed'), allowed);
      },
    }),
  )
  upload(@Req() request: UserRequest, @UploadedFile() file?: Express.Multer.File) {
    if (!file) throw new BadRequestException('A file is required');
    return this.uploads.upload(request.user.userId, file);
  }

  @Get(':key')
  async get(@Param('key') encodedKey: string, @Res() response: Response): Promise<void> {
    const object = await this.uploads.get(decodeURIComponent(encodedKey));
    response.setHeader('Content-Type', object.contentType);
    response.setHeader('Cache-Control', object.cacheControl);
    if (object.contentLength != null) {
      response.setHeader('Content-Length', object.contentLength.toString());
    }
    object.body.pipe(response);
  }
}
