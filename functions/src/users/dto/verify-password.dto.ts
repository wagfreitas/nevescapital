import { IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class VerifyPasswordDto {
  @ApiProperty({ example: '12345678901' })
  @IsString()
  cpf: string;

  @ApiProperty({ example: 'SecurePass123!' })
  @IsString()
  password: string;
}

