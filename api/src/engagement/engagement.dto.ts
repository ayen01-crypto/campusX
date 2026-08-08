import { IsDateString, IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class CreateBookingDto {
  @IsOptional()
  @IsDateString()
  scheduledAt?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;
}

export class CreateApplicationDto {
  @IsOptional()
  @IsString()
  @MaxLength(3000)
  coverNote?: string;

  @IsOptional()
  @IsString()
  resumeUrl?: string;
}

export class BuyTicketDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(10)
  quantity = 1;
}
