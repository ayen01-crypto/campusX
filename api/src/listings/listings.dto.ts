import { Type } from 'class-transformer';
import {
  IsArray,
  IsEnum,
  IsInt,
  IsLatitude,
  IsLongitude,
  IsObject,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

import { ListingKind } from '../generated/prisma/enums.js';

export class ListingQueryDto {
  @IsOptional()
  @IsEnum(ListingKind)
  kind?: ListingKind;

  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsString()
  universityId?: string;

  @IsOptional()
  @IsString()
  cursor?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  take = 20;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  minPrice?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  maxPrice?: number;
}

export class CreateListingDto {
  @IsEnum(ListingKind)
  kind!: ListingKind;

  @IsString()
  @MinLength(2)
  @MaxLength(120)
  title!: string;

  @IsOptional()
  @IsString()
  @MaxLength(180)
  subtitle?: string;

  @IsString()
  @MinLength(10)
  @MaxLength(5000)
  description!: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  price?: number;

  @IsOptional()
  @IsString()
  @MaxLength(16)
  currency?: string;

  @IsOptional()
  @IsString()
  @MaxLength(160)
  location?: string;

  @IsOptional()
  @IsLatitude()
  latitude?: number;

  @IsOptional()
  @IsLongitude()
  longitude?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  images?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  tags?: string[];

  @IsOptional()
  @IsObject()
  metadata?: Record<string, unknown>;

  @IsOptional()
  @IsString()
  universityId?: string;
}
