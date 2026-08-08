import { randomUUID } from 'node:crypto';
import { Readable } from 'node:stream';

import {
  CreateBucketCommand,
  GetObjectCommand,
  HeadBucketCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class UploadsService implements OnModuleInit {
  private readonly client: S3Client;
  private readonly bucket: string;

  constructor(private readonly config: ConfigService) {
    this.bucket = config.get<string>('STORAGE_BUCKET') ?? 'campusx';
    this.client = new S3Client({
      region: config.get<string>('STORAGE_REGION') ?? 'us-east-1',
      endpoint: config.get<string>('STORAGE_ENDPOINT'),
      forcePathStyle: true,
      credentials: {
        accessKeyId: config.get<string>('STORAGE_ACCESS_KEY') ?? 'campusx',
        secretAccessKey: config.get<string>('STORAGE_SECRET_KEY') ?? 'campusx-secret',
      },
    });
  }

  async onModuleInit(): Promise<void> {
    await this.ensureBucket();
  }

  async upload(userId: string, file: Express.Multer.File) {
    const extension = this.safeExtension(file.originalname);
    const key = `users/${userId}/${Date.now()}-${randomUUID()}${extension}`;

    await this.client.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: file.buffer,
        ContentType: file.mimetype,
        CacheControl: 'public, max-age=31536000, immutable',
      }),
    );

    return {
      key,
      url: `/uploads/${encodeURIComponent(key)}`,
      contentType: file.mimetype,
      size: file.size,
    };
  }

  async get(key: string) {
    try {
      const object = await this.client.send(
        new GetObjectCommand({ Bucket: this.bucket, Key: key }),
      );
      if (!object.Body) throw new NotFoundException('Upload not found');

      return {
        body: object.Body as Readable,
        contentType: object.ContentType ?? 'application/octet-stream',
        contentLength: object.ContentLength,
        cacheControl: object.CacheControl ?? 'public, max-age=3600',
      };
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      throw new NotFoundException('Upload not found');
    }
  }

  private async ensureBucket(): Promise<void> {
    try {
      await this.client.send(new HeadBucketCommand({ Bucket: this.bucket }));
    } catch {
      await this.client.send(new CreateBucketCommand({ Bucket: this.bucket }));
    }
  }

  private safeExtension(name: string): string {
    const match = name.toLowerCase().match(/\.(jpg|jpeg|png|webp|gif|pdf)$/);
    return match?.[0] ?? '';
  }
}
