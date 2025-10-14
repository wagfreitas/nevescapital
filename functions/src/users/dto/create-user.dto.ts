import { IsEmail, IsString, MinLength, IsOptional, Matches } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateUserDto {
  @ApiProperty({ example: 'user@example.com' })
  @IsEmail({}, { message: 'Email inválido' })
  email: string;

  @ApiProperty({ example: 'SecurePass123!', minLength: 6 })
  @IsString()
  @MinLength(6, { message: 'Senha deve ter pelo menos 6 caracteres' })
  password: string;

  @ApiProperty({ example: 'João Silva Santos' })
  @IsString()
  @MinLength(3, { message: 'Nome completo deve ter pelo menos 3 caracteres' })
  fullName: string;

  @ApiProperty({ example: '12345678901' })
  @IsString()
  @Matches(/^\d{11}$/, { message: 'CPF deve ter 11 dígitos' })
  cpf: string;

  @ApiPropertyOptional({ example: '11999999999' })
  @IsOptional()
  @IsString()
  @Matches(/^\d{10,11}$/, { message: 'Telefone deve ter 10 ou 11 dígitos' })
  phone?: string;

  @ApiPropertyOptional({ example: '01310100' })
  @IsOptional()
  @IsString()
  @Matches(/^\d{8}$/, { message: 'CEP deve ter 8 dígitos' })
  cep?: string;

  @ApiPropertyOptional({ example: 'Avenida Paulista' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: 'Bela Vista' })
  @IsOptional()
  @IsString()
  neighborhood?: string;

  @ApiPropertyOptional({ example: 'São Paulo' })
  @IsOptional()
  @IsString()
  city?: string;

  @ApiPropertyOptional({ example: 'SP' })
  @IsOptional()
  @IsString()
  @Matches(/^[A-Z]{2}$/, { message: 'Estado deve ter 2 letras maiúsculas' })
  state?: string;

  @ApiPropertyOptional({ example: '100' })
  @IsOptional()
  @IsString()
  number?: string;

  @ApiPropertyOptional({ example: 'Apto 10' })
  @IsOptional()
  @IsString()
  complement?: string;
}

