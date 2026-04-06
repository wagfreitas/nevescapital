import { Injectable } from '@nestjs/common';
import { FirestoreRestService } from '../../firebase-rest/firestore-rest.service';
import { serverTimestamp, fieldIncrement } from '../../firebase-rest/firestore-rest.utils';

interface OtpData {
  code: string;
  phone: string;
  expiresAt: Date;
  attempts: number;
  verified: boolean;
}

@Injectable()
export class SimpleOtpService {
  private readonly otpCollection = 'otp_codes';
  private readonly otpExpirationMinutes = 10;
  private readonly maxAttempts = 5;

  constructor(private readonly firestore: FirestoreRestService) {}

  /**
   * Gera um codigo OTP de 4 digitos
   */
  private generateOtpCode(): string {
    return Math.floor(1000 + Math.random() * 9000).toString();
  }

  /**
   * Envia OTP para um telefone
   * Para testes: retorna o codigo no response (nao envia SMS real)
   */
  async sendOtp(phone: string): Promise<{ success: boolean; code?: string; message: string }> {
    try {
      // Normalizar telefone
      const normalizedPhone = phone.replace(/\D/g, '');

      if (normalizedPhone.length < 10) {
        return {
          success: false,
          message: 'Numero de telefone invalido',
        };
      }

      // Gerar codigo
      const code = this.generateOtpCode();
      const expiresAt = new Date();
      expiresAt.setMinutes(expiresAt.getMinutes() + this.otpExpirationMinutes);

      // Salvar no Firestore
      const otpDoc = {
        phone: normalizedPhone,
        code,
        expiresAt,
        attempts: 0,
        verified: false,
        createdAt: serverTimestamp(),
      };

      // Deletar OTPs antigos do mesmo telefone
      const tQuery = Date.now();
      const oldOtps = await this.firestore.query(this.otpCollection, {
        where: [{ field: 'phone', op: 'EQUAL', value: normalizedPhone }],
      });
      console.log(`[OTP-TIMING]   query OTPs antigos: ${Date.now() - tQuery}ms (found: ${oldOtps.length})`);

      // Commit dos deletes antes de criar o novo documento (evita condicao de corrida no Firestore)
      const tWrite = Date.now();
      if (oldOtps.length > 0) {
        const paths = oldOtps.map((doc) => `${this.otpCollection}/${doc.id}`);
        await this.firestore.batchDelete(paths);
      }
      await this.firestore.addDocument(this.otpCollection, otpDoc);
      console.log(`[OTP-TIMING]   delete+add: ${Date.now() - tWrite}ms`);

      // MODO TESTE: Retornar codigo no response
      // Em producao, voce pode integrar com um servico de SMS real aqui
      return {
        success: true,
        code, // APENAS PARA TESTES - remover em producao
        message: `Codigo OTP gerado. Para testes, use: ${code}`,
      };
    } catch (error: any) {
      const code = error?.code || error?.response?.status;
      const msg = error?.message ?? String(error);
      const responseData = error?.response?.data ? JSON.stringify(error.response.data) : '';
      console.error('Erro ao enviar OTP:', { code, msg, responseData });

      const fullError = `${msg} ${responseData}`;
      const permissionDenied =
        code === 403 ||
        code === 7 ||
        code === 'PERMISSION_DENIED' ||
        fullError.includes('PERMISSION_DENIED') ||
        fullError.includes('Missing or insufficient permissions');
      const unavailable =
        code === 14 ||
        code === 'UNAVAILABLE' ||
        fullError.includes('UNAVAILABLE');

      // Temporariamente: sempre retornar erro detalhado para debug
      const userMessage = `Erro OTP [${code}]: ${msg} | ${responseData}`;

      return {
        success: false,
        message: userMessage,
      };
    }
  }

  /**
   * Verifica se o codigo OTP esta correto
   */
  async verifyOtp(phone: string, code: string): Promise<{ success: boolean; message: string }> {
    try {
      const normalizedPhone = phone.replace(/\D/g, '');

      // Buscar OTP mais recente para este telefone
      const otpResults = await this.firestore.query(this.otpCollection, {
        where: [
          { field: 'phone', op: 'EQUAL', value: normalizedPhone },
          { field: 'verified', op: 'EQUAL', value: false },
        ],
        orderBy: 'createdAt',
        orderDirection: 'DESCENDING',
        limit: 1,
      });

      if (otpResults.length === 0) {
        return {
          success: false,
          message: 'Codigo OTP nao encontrado ou ja utilizado',
        };
      }

      const otpDoc = otpResults[0];
      const otpData = otpDoc.data as OtpData;

      // Verificar expiracao - expiresAt vem como Date do decodeValue
      const expiresAt = otpData.expiresAt instanceof Date
        ? otpData.expiresAt
        : new Date(otpData.expiresAt);
      if (new Date() > expiresAt) {
        await this.firestore.deleteDocument(this.otpCollection, otpDoc.id);
        return {
          success: false,
          message: 'Codigo OTP expirado. Solicite um novo codigo.',
        };
      }

      // Verificar tentativas
      if (otpData.attempts >= this.maxAttempts) {
        await this.firestore.deleteDocument(this.otpCollection, otpDoc.id);
        return {
          success: false,
          message: 'Numero maximo de tentativas excedido. Solicite um novo codigo.',
        };
      }

      // Verificar codigo
      if (otpData.code !== code) {
        // Incrementar tentativas
        await this.firestore.updateDocument(this.otpCollection, otpDoc.id, {
          attempts: fieldIncrement(1),
        });

        const remainingAttempts = this.maxAttempts - otpData.attempts - 1;
        return {
          success: false,
          message: `Codigo incorreto. Tentativas restantes: ${remainingAttempts}`,
        };
      }

      // Codigo correto - marcar como verificado
      await this.firestore.updateDocument(this.otpCollection, otpDoc.id, {
        verified: true,
      });

      return {
        success: true,
        message: 'Codigo OTP verificado com sucesso',
      };
    } catch (error) {
      console.error('Erro ao verificar OTP:', error);
      return {
        success: false,
        message: 'Erro ao verificar codigo OTP',
      };
    }
  }

  /**
   * Limpa OTPs expirados (pode ser chamado periodicamente)
   */
  async cleanupExpiredOtps(): Promise<void> {
    try {
      const now = new Date();
      const expiredOtps = await this.firestore.query(this.otpCollection, {
        where: [{ field: 'expiresAt', op: 'LESS_THAN', value: now }],
      });

      if (expiredOtps.length > 0) {
        const paths = expiredOtps.map((doc) => `${this.otpCollection}/${doc.id}`);
        await this.firestore.batchDelete(paths);
      }

      console.log(`Limpeza: ${expiredOtps.length} OTPs expirados removidos`);
    } catch (error) {
      console.error('Erro ao limpar OTPs expirados:', error);
    }
  }
}
