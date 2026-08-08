import { IsIn, IsOptional, IsString, Matches } from 'class-validator';

export class InitiatePaymentDto {
  @IsIn(['MOCK', 'MTN_MOMO', 'AIRTEL_MONEY'])
  provider!: 'MOCK' | 'MTN_MOMO' | 'AIRTEL_MONEY';

  @IsOptional()
  @IsString()
  @Matches(/^\+?[0-9]{9,15}$/)
  phone?: string;
}
