import {
  IsString,
  IsOptional,
  IsNotEmpty,
  MaxLength,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

/**
 * Dados bancários do destinatário (modalidade C: agência/conta).
 */
export class DadosBancariosDto {
  @IsString()
  @IsNotEmpty()
  banco: string; // ISPB ou código

  @IsString()
  @IsNotEmpty()
  agencia: string;

  @IsString()
  @IsNotEmpty()
  conta: string;

  @IsString()
  @IsNotEmpty()
  cpfCnpj: string;

  @IsString()
  @IsNotEmpty()
  nome: string;

  @IsOptional()
  @IsString()
  tipoConta?: 'cacc' | 'svgs'; // cacc=corrente, svgs=poupança (lowercase, conforme doc Efí)
}

/**
 * DTO para enviar PIX via Efí.
 * Suporta 3 modalidades (uma OU outra):
 *   - Por chave PIX
 *   - Por copia-e-cola (BR Code)
 *   - Por dados bancários (agência/conta/CPF)
 */
export class SendPixDto {
  /**
   * Valor em reais (string com 2 casas decimais).
   * Ex: "0.01" para 1 centavo, "100.50" para R$ 100,50.
   */
  @IsString()
  @IsNotEmpty()
  valor: string;

  /**
   * Chave PIX do PAGADOR (a sua chave registrada na conta Efí).
   * Se não passar, usa EFI_PAGADOR_CHAVE do .env.
   * Obrigatório pela Efí — identifica qual chave da sua conta paga.
   */
  @IsOptional()
  @IsString()
  pagadorChave?: string;

  /**
   * Descrição opcional (max 140 chars).
   */
  @IsOptional()
  @IsString()
  @MaxLength(140)
  descricao?: string;

  /**
   * Modalidade A: chave PIX do destinatário.
   * Ex: CPF, CNPJ, email, telefone, ou chave aleatória.
   */
  @ValidateIf((o) => !o.pixCopiaECola && !o.dadosBancarios)
  @IsString()
  @IsNotEmpty()
  chave?: string;

  /**
   * Modalidade B: BR Code (copia-e-cola).
   */
  @ValidateIf((o) => !o.chave && !o.dadosBancarios)
  @IsString()
  @IsNotEmpty()
  pixCopiaECola?: string;

  /**
   * Modalidade C: dados bancários do destinatário.
   */
  @ValidateIf((o) => !o.chave && !o.pixCopiaECola)
  @IsOptional()
  @ValidateNested()
  @Type(() => DadosBancariosDto)
  dadosBancarios?: DadosBancariosDto;
}
