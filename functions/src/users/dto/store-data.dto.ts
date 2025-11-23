import { IsString, IsNotEmpty, MinLength, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class StoreDataDto {
  @ApiProperty({ example: 'Minha Loja LTDA' })
  @IsNotEmpty({ message: 'Nome da loja é obrigatório' })
  @IsString()
  @MinLength(3, { message: 'Nome da loja deve ter pelo menos 3 caracteres' })
  @MaxLength(255, { message: 'Nome da loja deve ter no máximo 255 caracteres' })
  store_name: string;

  @ApiProperty({ example: 'Alimentação' })
  @IsNotEmpty({ message: 'Ramo de atividade é obrigatório' })
  @IsString()
  @MinLength(2, { message: 'Ramo de atividade deve ter pelo menos 2 caracteres' })
  @MaxLength(100, { message: 'Ramo de atividade deve ter no máximo 100 caracteres' })
  business_type: string;
}

