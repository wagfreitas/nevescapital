import { IsString, IsNotEmpty, IsOptional, IsBoolean, IsInt, Min, Max } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreatePixKeyDto {
  @ApiProperty({ example: '11999999999' })
  @IsNotEmpty({ message: 'Chave PIX é obrigatória' })
  @IsString()
  pix_key: string;
}

export class UpdatePixKeyDto {
  @ApiPropertyOptional({ example: false })
  @IsOptional()
  @IsBoolean()
  is_primary?: boolean;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(10)
  display_order?: number;
}

export class ReorderPixKeysDto {
  @ApiProperty({ example: ['uuid1', 'uuid2', 'uuid3'] })
  @IsNotEmpty({ message: 'Lista de IDs é obrigatória' })
  @IsString({ each: true })
  key_ids: string[];
}

