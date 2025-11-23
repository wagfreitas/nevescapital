import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, Matches, Length } from 'class-validator';

export class CheckCpfDto {
  @ApiProperty({
    description: 'CPF do usuário (apenas números)',
    example: '12345678901',
  })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{11}$/, { message: 'CPF deve conter exatamente 11 dígitos' })
  cpf: string;
}

export class RequestRegistrationOtpDto {
  @ApiProperty({
    description: 'CPF do usuário (apenas números)',
    example: '12345678901',
  })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{11}$/, { message: 'CPF deve conter exatamente 11 dígitos' })
  cpf: string;

  @ApiProperty({
    description: 'Número de telefone celular',
    example: '11999999999',
  })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{10,11}$/, { message: 'Telefone deve conter 10 ou 11 dígitos' })
  phone: string;
}

export class VerifyRegistrationOtpDto {
  @ApiProperty({
    description: 'CPF do usuário (apenas números)',
    example: '12345678901',
  })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{11}$/, { message: 'CPF deve conter exatamente 11 dígitos' })
  cpf: string;

  @ApiProperty({
    description: 'Número de telefone celular',
    example: '11999999999',
  })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{10,11}$/, { message: 'Telefone deve conter 10 ou 11 dígitos' })
  phone: string;

  @ApiProperty({
    description: 'Código OTP de 6 dígitos',
    example: '123456',
  })
  @IsString()
  @IsNotEmpty()
  @Length(6, 6, { message: 'Código OTP deve conter exatamente 6 dígitos' })
  @Matches(/^\d{6}$/, { message: 'Código OTP deve conter apenas números' })
  otp_code: string;
}



