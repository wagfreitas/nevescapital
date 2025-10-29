import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty } from 'class-validator';

export class ResetPasswordDto {
  @ApiProperty({
    description: 'Email do usuário',
    example: 'usuario@exemplo.com',
  })
  @IsEmail({}, { message: 'Email inválido' })
  @IsNotEmpty({ message: 'Email é obrigatório' })
  email: string;
}

export class ResetPasswordByCpfDto {
  @ApiProperty({
    description: 'CPF do usuário (apenas números)',
    example: '12345678900',
  })
  @IsNotEmpty({ message: 'CPF é obrigatório' })
  cpf: string;
}

