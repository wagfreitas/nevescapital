import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNotEmpty, Matches, IsOptional, IsIn } from 'class-validator';

export class SendVerifyOtpDto {
  @ApiProperty({
    description: 'Telefone apenas digitos (codigo do pais + DDD + numero)',
    example: '5511999999999',
  })
  @IsString()
  @IsNotEmpty({ message: 'Telefone e obrigatorio' })
  @Matches(/^\d{10,15}$/, { message: 'Numero de telefone invalido' })
  phone: string;

  @ApiPropertyOptional({
    description: 'Canal de envio do OTP (sms ou whatsapp). Padrao: sms',
    example: 'sms',
    enum: ['sms', 'whatsapp'],
  })
  @IsOptional()
  @IsString()
  @IsIn(['sms', 'whatsapp'], { message: 'Canal deve ser sms ou whatsapp' })
  channel?: 'sms' | 'whatsapp';
}

export class CheckVerifyOtpDto {
  @ApiProperty({
    description: 'Telefone apenas digitos (codigo do pais + DDD + numero)',
    example: '5511999999999',
  })
  @IsString()
  @IsNotEmpty({ message: 'Telefone e obrigatorio' })
  @Matches(/^\d{10,15}$/, { message: 'Numero de telefone invalido' })
  phone: string;

  @ApiProperty({
    description: 'Codigo OTP recebido (4 a 6 digitos)',
    example: '123456',
  })
  @IsString()
  @IsNotEmpty({ message: 'Codigo e obrigatorio' })
  @Matches(/^\d{4,6}$/, { message: 'Codigo OTP invalido' })
  code: string;
}
