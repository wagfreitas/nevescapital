import { Injectable } from '@nestjs/common';
import * as admin from 'firebase-admin';

interface OtpData {
  code: string;
  phone: string;
  expiresAt: Date;
  attempts: number;
  verified: boolean;
}

@Injectable()
export class SimpleOtpService {
  private readonly db = admin.firestore();
  private readonly otpCollection = 'otp_codes';
  private readonly otpExpirationMinutes = 10;
  private readonly maxAttempts = 5;

  /**
   * Gera um código OTP de 4 dígitos
   */
  private generateOtpCode(): string {
    return Math.floor(1000 + Math.random() * 9000).toString();
  }

  /**
   * Envia OTP para um telefone
   * Para testes: retorna o código no response (não envia SMS real)
   */
  async sendOtp(phone: string): Promise<{ success: boolean; code?: string; message: string }> {
    try {
      // Normalizar telefone
      const normalizedPhone = phone.replace(/\D/g, '');
      
      if (normalizedPhone.length < 10) {
        return {
          success: false,
          message: 'Número de telefone inválido',
        };
      }

      // Gerar código
      const code = this.generateOtpCode();
      const expiresAt = new Date();
      expiresAt.setMinutes(expiresAt.getMinutes() + this.otpExpirationMinutes);

      // Salvar no Firestore
      const otpDoc = {
        phone: normalizedPhone,
        code,
        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
        attempts: 0,
        verified: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Deletar OTPs antigos do mesmo telefone
      const oldOtps = await this.db
        .collection(this.otpCollection)
        .where('phone', '==', normalizedPhone)
        .get();

      const batch = this.db.batch();
      oldOtps.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      // Executar delete e create em paralelo (operam em documentos diferentes)
      await Promise.all([
        batch.commit(),
        this.db.collection(this.otpCollection).add(otpDoc),
      ]);

      // ⚠️ MODO TESTE: Retornar código no response
      // Em produção, você pode integrar com um serviço de SMS real aqui
      return {
        success: true,
        code, // ⚠️ APENAS PARA TESTES - remover em produção
        message: `Código OTP gerado. Para testes, use: ${code}`,
      };
    } catch (error) {
      console.error('Erro ao enviar OTP:', error);
      return {
        success: false,
        message: 'Erro ao gerar código OTP',
      };
    }
  }

  /**
   * Verifica se o código OTP está correto
   */
  async verifyOtp(phone: string, code: string): Promise<{ success: boolean; message: string }> {
    try {
      const normalizedPhone = phone.replace(/\D/g, '');

      // Buscar OTP mais recente para este telefone
      const otpQuery = await this.db
        .collection(this.otpCollection)
        .where('phone', '==', normalizedPhone)
        .where('verified', '==', false)
        .orderBy('createdAt', 'desc')
        .limit(1)
        .get();

      if (otpQuery.empty) {
        return {
          success: false,
          message: 'Código OTP não encontrado ou já utilizado',
        };
      }

      const otpDoc = otpQuery.docs[0];
      const otpData = otpDoc.data();

      // Verificar expiração
      const expiresAt = otpData.expiresAt instanceof admin.firestore.Timestamp 
        ? otpData.expiresAt.toDate() 
        : new Date(otpData.expiresAt);
      if (new Date() > expiresAt) {
        await otpDoc.ref.delete();
        return {
          success: false,
          message: 'Código OTP expirado. Solicite um novo código.',
        };
      }

      // Verificar tentativas
      if (otpData.attempts >= this.maxAttempts) {
        await otpDoc.ref.delete();
        return {
          success: false,
          message: 'Número máximo de tentativas excedido. Solicite um novo código.',
        };
      }

      // Verificar código
      if (otpData.code !== code) {
        // Incrementar tentativas
        await otpDoc.ref.update({
          attempts: admin.firestore.FieldValue.increment(1),
        });

        const remainingAttempts = this.maxAttempts - otpData.attempts - 1;
        return {
          success: false,
          message: `Código incorreto. Tentativas restantes: ${remainingAttempts}`,
        };
      }

      // Código correto - marcar como verificado
      await otpDoc.ref.update({
        verified: true,
      });

      return {
        success: true,
        message: 'Código OTP verificado com sucesso',
      };
    } catch (error) {
      console.error('Erro ao verificar OTP:', error);
      return {
        success: false,
        message: 'Erro ao verificar código OTP',
      };
    }
  }

  /**
   * Limpa OTPs expirados (pode ser chamado periodicamente)
   */
  async cleanupExpiredOtps(): Promise<void> {
    try {
      const now = admin.firestore.Timestamp.now();
      const expiredOtps = await this.db
        .collection(this.otpCollection)
        .where('expiresAt', '<', now)
        .get();

      const batch = this.db.batch();
      expiredOtps.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });
      await batch.commit();

      console.log(`Limpeza: ${expiredOtps.size} OTPs expirados removidos`);
    } catch (error) {
      console.error('Erro ao limpar OTPs expirados:', error);
    }
  }
}

