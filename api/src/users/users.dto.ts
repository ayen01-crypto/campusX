import { IsArray, IsEnum, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

import { UserCapability } from '../generated/prisma/enums.js';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  bio?: string;

  @IsOptional()
  @IsString()
  avatarUrl?: string;

  @IsOptional()
  @IsString()
  universityId?: string;

  @IsOptional()
  @IsArray()
  @IsEnum(UserCapability, { each: true })
  capabilities?: UserCapability[];
}
