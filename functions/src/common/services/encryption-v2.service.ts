import { Injectable } from '@nestjs/common';
import * as crypto from 'crypto';
import * as bcrypt from 'bcrypt';

/**
 * Serviço de Criptografia V2
 * 
 * Implementa MASVS-CRYPTO standards:
 * - MASVS-CRYPTO-1: Usa algoritmos aprovados (AES-256-GCM, SHA-256)
 * - MASVS-CRYPTO-2: Chaves gerenciadas adequadamente
 * - Substitui CryptoJS por crypto nativo do Node.js
 * - Usa AES-256-GCM com IV aleatório
 * - Hash determinístico para busca em banco
 */
@Injectable()
export class EncryptionV2Service {
  private readonly encryptionKey: Buffer;
  private readonly saltRounds = 12; // MASVS-CRYPTO-1: bcrypt com rounds adequados

  constructor() {
    const key = process.env.ENCRYPTION_KEY || 'your-32-character-secret-key!';
    // Deriva uma chave de 32 bytes usando SHA-256
    this.encryptionKey = crypto.createHash('sha256').update(key).digest();
  }

  /**
   * Criptografar dados sensíveis com AES-256-GCM
   * MASVS-CRYPTO-1: Algoritmo aprovado + autenticação
   */
  encrypt(text: string): string | null {
    if (!text) return null;
    
    try {
      // Gerar IV aleatório de 16 bytes
      const iv = crypto.randomBytes(16);
      
      // Criar cipher com AES-256-GCM
      const cipher = crypto.createCipheriv('aes-256-gcm', this.encryptionKey, iv);
      
      // Criptografar
      let encrypted = cipher.update(text, 'utf8', 'hex');
      encrypted += cipher.final('hex');
      
      // Obter auth tag
      const authTag = cipher.getAuthTag();
      
      // Retornar: iv + authTag + encrypted (tudo em hex)
      return iv.toString('hex') + ':' + authTag.toString('hex') + ':' + encrypted;
    } catch (error) {
      console.error('Erro ao criptografar:', error);
      throw new Error('Falha na criptografia');
    }
  }

  /**
   * Descriptografar dados sensíveis
   * MASVS-CRYPTO-1: Verifica autenticidade
   */
  decrypt(encryptedText: string): string | null {
    if (!encryptedText) return null;
    
    try {
      // Separar iv, authTag e encrypted
      const parts = encryptedText.split(':');
      if (parts.length !== 3) {
        throw new Error('Formato de dados criptografados inválido');
      }
      
      const iv = Buffer.from(parts[0], 'hex');
      const authTag = Buffer.from(parts[1], 'hex');
      const encrypted = parts[2];
      
      // Criar decipher
      const decipher = crypto.createDecipheriv('aes-256-gcm', this.encryptionKey, iv);
      decipher.setAuthTag(authTag);
      
      // Descriptografar
      let decrypted = decipher.update(encrypted, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
      
      return decrypted;
    } catch (error) {
      console.error('Erro ao descriptografar:', error);
      throw new Error('Falha na descriptografia');
    }
  }

  /**
   * Criar hash determinístico para busca em banco
   * MASVS-CRYPTO-2: Permite busca sem descriptografar todos os registros
   * Usa HMAC-SHA256 para criar hash determinístico
   */
  createSearchableHash(text: string): string {
    if (!text) return '';
    
    try {
      const hmac = crypto.createHmac('sha256', this.encryptionKey);
      hmac.update(text);
      return hmac.digest('hex');
    } catch (error) {
      console.error('Erro ao criar hash pesquisável:', error);
      throw new Error('Falha ao criar hash');
    }
  }

  /**
   * Hash de senha com bcrypt
   * MASVS-CRYPTO-1: Usa algoritmo apropriado para senhas
   */
  async hashPassword(password: string): Promise<string> {
    try {
      return await bcrypt.hash(password, this.saltRounds);
    } catch (error) {
      console.error('Erro ao gerar hash:', error);
      throw new Error('Falha ao processar senha');
    }
  }

  /**
   * Verificar senha com bcrypt
   */
  async verifyPassword(password: string, hash: string): Promise<boolean> {
    try {
      return await bcrypt.compare(password, hash);
    } catch (error) {
      console.error('Erro ao verificar senha:', error);
      return false;
    }
  }

  /**
   * Gerar token aleatório seguro
   * MASVS-CRYPTO-2: Geração de tokens criptograficamente segura
   */
  generateSecureToken(length: number = 32): string {
    return crypto.randomBytes(length).toString('hex');
  }

  /**
   * Gerar salt aleatório
   * MASVS-CRYPTO-2: Salt único por registro
   */
  generateSalt(length: number = 16): string {
    return crypto.randomBytes(length).toString('hex');
  }
}

