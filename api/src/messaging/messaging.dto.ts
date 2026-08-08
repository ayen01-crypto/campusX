import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class StartConversationDto {
  @IsString()
  participantId!: string;

  @IsOptional()
  @IsString()
  listingId?: string;
}

export class SendMessageDto {
  @IsString()
  clientId!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(5000)
  body!: string;

  @IsOptional()
  @IsString()
  attachmentUrl?: string;

  @IsOptional()
  @IsString()
  attachmentType?: string;
}
