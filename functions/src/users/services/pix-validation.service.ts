import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class PixValidationService {
  constructor(private readonly configService: ConfigService) {}

  /**
   * Valida chave PIX (validação de formato)
   * Validação real no DICT requer integração com instituição financeira
   */
  async validatePixKeyReal(key: string): Promise<{ valid: boolean; error?: string; accountData?: any }> {
    const formatValidation = this.validatePixKey(key);
    if (!formatValidation.valid) {
      return { valid: false, error: formatValidation.error };
    }

    return {
      valid: true,
      accountData: {
        message: 'Chave PIX com formato válido',
        validated: 'format',
      },
    };
  }

  /**
   * Valida formato de chave PIX (validação local)
   * Retorna o tipo da chave se válida, null se inválida
   */
  validatePixKey(key: string): { valid: boolean; type: 'CPF' | 'EMAIL' | 'PHONE' | 'RANDOM' | null; error?: string } {
    if (!key || key.trim().length === 0) {
      return { valid: false, type: null, error: 'Chave PIX não pode ser vazia' };
    }

    const cleanedKey = key.trim().replace(/\D/g, ''); // Remove caracteres não numéricos

    // CPF (11 dígitos)
    if (cleanedKey.length === 11 && /^\d{11}$/.test(cleanedKey)) {
      if (this.isValidCpf(cleanedKey)) {
        return { valid: true, type: 'CPF' };
      }
      return { valid: false, type: null, error: 'CPF inválido' };
    }

    // Telefone (10 ou 11 dígitos com DDD)
    if ((cleanedKey.length === 10 || cleanedKey.length === 11) && /^\d{10,11}$/.test(cleanedKey)) {
      // Verificar se começa com DDD válido (11 a 99)
      const ddd = cleanedKey.substring(0, 2);
      if (parseInt(ddd) >= 11 && parseInt(ddd) <= 99) {
        return { valid: true, type: 'PHONE' };
      }
      return { valid: false, type: null, error: 'DDD inválido' };
    }

    // Email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (emailRegex.test(key)) {
      return { valid: true, type: 'EMAIL' };
    }

    // Chave aleatória (UUID format)
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (uuidRegex.test(key)) {
      return { valid: true, type: 'RANDOM' };
    }

    return { valid: false, type: null, error: 'Formato de chave PIX inválido' };
  }

  /**
   * Valida CPF
   */
  private isValidCpf(cpf: string): boolean {
    if (cpf.length !== 11) return false;

    // Verificar se todos os dígitos são iguais
    if (/^(\d)\1{10}$/.test(cpf)) return false;

    // Validar dígitos verificadores
    let sum = 0;
    let remainder: number;

    // Validar primeiro dígito
    for (let i = 1; i <= 9; i++) {
      sum += parseInt(cpf.substring(i - 1, i)) * (11 - i);
    }
    remainder = (sum * 10) % 11;
    if (remainder === 10 || remainder === 11) remainder = 0;
    if (remainder !== parseInt(cpf.substring(9, 10))) return false;

    // Validar segundo dígito
    sum = 0;
    for (let i = 1; i <= 10; i++) {
      sum += parseInt(cpf.substring(i - 1, i)) * (12 - i);
    }
    remainder = (sum * 10) % 11;
    if (remainder === 10 || remainder === 11) remainder = 0;
    if (remainder !== parseInt(cpf.substring(10, 11))) return false;

    return true;
  }

  /**
   * Formata chave PIX para exibição
   */
  formatPixKey(key: string, type: 'CPF' | 'EMAIL' | 'PHONE' | 'RANDOM'): string {
    switch (type) {
      case 'CPF':
        return key.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
      case 'PHONE':
        if (key.length === 11) {
          return key.replace(/(\d{2})(\d{5})(\d{4})/, '($1) $2-$3');
        }
        return key.replace(/(\d{2})(\d{4})(\d{4})/, '($1) $2-$3');
      case 'EMAIL':
      case 'RANDOM':
      default:
        return key;
    }
  }
}

