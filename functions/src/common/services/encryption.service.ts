import { Injectable } from '@nestjs/common';
import * as CryptoJS from 'crypto-js';
import * as bcrypt from 'bcrypt';

@Injectable()
export class EncryptionService {
  private readonly encryptionKey = process.env.ENCRYPTION_KEY || 'your-32-character-secret-key!';
  private readonly saltRounds = 10;

  /**
   * Criptografar dados sensíveis com AES-256
   */
  encrypt(text: string): string | null {
    if (!text) return null;
    
    try {
      const encrypted = CryptoJS.AES.encrypt(text, this.encryptionKey);
      return encrypted.toString();
    } catch (error) {
      console.error('Erro ao criptografar:', error);
      throw new Error('Falha na criptografia');
    }
  }

  /**
   * Descriptografar dados sensíveis
   */
  decrypt(encryptedText: string): string | null {
    if (!encryptedText) return null;
    
    try {
      const decrypted = CryptoJS.AES.decrypt(encryptedText, this.encryptionKey);
      return decrypted.toString(CryptoJS.enc.Utf8);
    } catch (error) {
      console.error('Erro ao descriptografar:', error);
      throw new Error('Falha na descriptografia');
    }
  }

  /**
   * Hash de senha com bcrypt
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
}

