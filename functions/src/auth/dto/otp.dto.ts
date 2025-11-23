import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, Matches, MinLength } from 'class-validator';

export class RequestPasswordResetOtpDto {
  @ApiProperty({
    description: 'CPF do usuário (apenas números)',
    example: '12345678900',
  })
  @IsNotEmpty({ message: 'CPF é obrigatório' })
  @IsString()
  @Matches(/^\d{11}$/, { message: 'CPF deve ter 11 dígitos' })
  cpf: string;
}

export class VerifyPasswordResetOtpDto {
  @ApiProperty({
    description: 'CPF do usuário (apenas números)',
    example: '12345678900',
  })
  @IsNotEmpty({ message: 'CPF é obrigatório' })
  @IsString()
  @Matches(/^\d{11}$/, { message: 'CPF deve ter 11 dígitos' })
  cpf: string;

  @ApiProperty({
    description: 'Código OTP de 6 dígitos',
    example: '123456',
  })
  @IsNotEmpty({ message: 'Código OTP é obrigatório' })
  @IsString()
  @Matches(/^\d{6}$/, { message: 'Código OTP deve ter 6 dígitos' })
  otp_code: string;
}

export class ChangePasswordWithOtpDto {
  @ApiProperty({
    description: 'Token temporário recebido após validar OTP',
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  })
  @IsNotEmpty({ message: 'Token é obrigatório' })
  @IsString()
  token: string;

  @ApiProperty({
    description: 'Senha atual do usuário',
    example: 'SenhaAtual123!',
  })
  @IsNotEmpty({ message: 'Senha atual é obrigatória' })
  @IsString()
  @MinLength(6, { message: 'Senha deve ter pelo menos 6 caracteres' })
  old_password: string;

  @ApiProperty({
    description: 'Nova senha do usuário',
    example: 'NovaSenha123!',
  })
  @IsNotEmpty({ message: 'Nova senha é obrigatória' })
  @IsString()
  @MinLength(6, { message: 'Senha deve ter pelo menos 6 caracteres' })
  new_password: string;
}

