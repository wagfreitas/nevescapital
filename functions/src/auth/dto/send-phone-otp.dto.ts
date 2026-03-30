import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, Matches } from 'class-validator';

/** Telefone só com dígitos (ex.: 5511999999999 com código do país). */
export class SendPhoneOtpDto {
  @ApiProperty({
    description: 'Telefone apenas dígitos (código do país + DDD + número)',
    example: '5511999999999',
  })
  @IsString()
  @IsNotEmpty({ message: 'Telefone é obrigatório' })
  @Matches(/^\d{10,15}$/, { message: 'Número de telefone inválido' })
  phone: string;
}

export class VerifyPhoneOtpDto {
  @ApiProperty({ example: '5511999999999' })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{10,15}$/, { message: 'Número de telefone inválido' })
  phone: string;

  @ApiProperty({ description: 'Código OTP (4 dígitos no fluxo WhatsApp)', example: '1234' })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{4,6}$/, { message: 'Código OTP inválido' })
  code: string;
}

export class CheckUserStatusDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty({ message: 'Token é obrigatório' })
  token: string;
}
