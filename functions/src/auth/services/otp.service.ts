import { Injectable, Inject, BadRequestException, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { Pool } from 'pg';
import { EncryptionService } from '../../common/services/encryption.service';
import * as crypto from 'crypto';

@Injectable()
export class OtpService {
  private readonly OTP_EXPIRY_MINUTES = 10; // Código válido por 10 minutos
  private readonly MAX_ATTEMPTS = 3; // Máximo de tentativas
  private readonly OTP_LENGTH = 6; // Código de 6 dígitos

  constructor(
    @Inject('DATABASE_POOL') private readonly pool: Pool,
    private readonly encryptionService: EncryptionService,
  ) {}

  /**
   * Gera código OTP aleatório de 6 dígitos
   */
  private generateOtpCode(): string {
    const min = 100000;
    const max = 999999;
    return Math.floor(Math.random() * (max - min + 1) + min).toString();
  }

  /**
   * Gera hash SHA256 do código OTP
   */
  private hashOtpCode(code: string): string {
    return crypto.createHash('sha256').update(code).digest('hex');
  }

  /**
   * Criptografa telefone para armazenamento
   */
  private encryptPhone(phone: string): string {
    const encrypted = this.encryptionService.encrypt(phone);
    if (!encrypted) {
      throw new Error('Falha ao criptografar telefone');
    }
    return encrypted;
  }

  /**
   * Descriptografa telefone
   */
  private decryptPhone(encryptedPhone: string): string {
    const decrypted = this.encryptionService.decrypt(encryptedPhone);
    if (!decrypted) {
      throw new Error('Falha ao descriptografar telefone');
    }
    return decrypted;
  }

  /**
   * Cria um novo código OTP para recuperação de senha
   */
  async createOtp(userId: string, phone: string): Promise<{ otpCode: string; expiresAt: Date }> {
    const client = await this.pool.connect();

    try {
      // Verificar se já existe um OTP ativo e não verificado para este usuário
      const existingOtp = await client.query(
        `SELECT id, attempts, expires_at 
         FROM password_reset_otps 
         WHERE user_id = $1 AND verified = FALSE AND expires_at > NOW()
         ORDER BY created_at DESC 
         LIMIT 1`,
        [userId],
      );

      if (existingOtp.rows.length > 0) {
        const otp = existingOtp.rows[0];
        const expiresAt = new Date(otp.expires_at);
        const now = new Date();
        const minutesRemaining = Math.ceil((expiresAt.getTime() - now.getTime()) / (1000 * 60));

        if (minutesRemaining > 2) {
          // Ainda há tempo suficiente no código existente (mais de 2 minutos)
          throw new BadRequestException(
            `Aguarde ${minutesRemaining} minutos antes de solicitar um novo código`,
          );
        }

        // Invalidar OTP anterior
        await client.query(
          `UPDATE password_reset_otps SET verified = TRUE WHERE id = $1`,
          [otp.id],
        );
      }

      // Gerar novo código OTP
      const otpCode = this.generateOtpCode();
      const otpHash = this.hashOtpCode(otpCode);
      const expiresAt = new Date();
      expiresAt.setMinutes(expiresAt.getMinutes() + this.OTP_EXPIRY_MINUTES);

      // Criptografar telefone
      const encryptedPhone = this.encryptPhone(phone);

      // Inserir no banco
      await client.query(
        `INSERT INTO password_reset_otps (
          user_id, phone, otp_code_hash, otp_code, expires_at, verified, attempts
        ) VALUES ($1, $2, $3, $4, $5, FALSE, 0)`,
        [userId, encryptedPhone, otpHash, otpCode, expiresAt],
      );

      console.log(`✅ OTP criado para usuário ${userId}, expira em ${expiresAt.toISOString()}`);

      return {
        otpCode,
        expiresAt,
      };
    } finally {
      client.release();
    }
  }

  /**
   * Verifica código OTP e retorna token temporário se válido
   */
  async verifyOtp(userId: string, otpCode: string): Promise<string> {
    const client = await this.pool.connect();

    try {
      // Buscar OTP não verificado e não expirado
      const result = await client.query(
        `SELECT id, otp_code_hash, otp_code, attempts, expires_at, verified
         FROM password_reset_otps
         WHERE user_id = $1 AND verified = FALSE AND expires_at > NOW()
         ORDER BY created_at DESC
         LIMIT 1`,
        [userId],
      );

      if (result.rows.length === 0) {
        throw new NotFoundException('Código OTP não encontrado ou expirado');
      }

      const otp = result.rows[0];

      // Verificar tentativas
      if (otp.attempts >= this.MAX_ATTEMPTS) {
        await client.query(
          `UPDATE password_reset_otps SET verified = TRUE WHERE id = $1`,
          [otp.id],
        );
        throw new UnauthorizedException(
          'Máximo de tentativas excedido. Solicite um novo código.',
        );
      }

      // Verificar código
      const otpHash = this.hashOtpCode(otpCode);
      const isValid = otpHash === otp.otp_code_hash;

      // Incrementar tentativas
      await client.query(
        `UPDATE password_reset_otps SET attempts = attempts + 1 WHERE id = $1`,
        [otp.id],
      );

      if (!isValid) {
        throw new UnauthorizedException('Código OTP inválido');
      }

      // Gerar token temporário
      const token = this.generateTempToken(userId);
      const tokenExpiresAt = new Date();
      tokenExpiresAt.setMinutes(tokenExpiresAt.getMinutes() + 15); // Token válido por 15 minutos

      // Marcar como verificado e armazenar token
      await client.query(
        `UPDATE password_reset_otps 
         SET verified = TRUE, verified_at = NOW(), otp_code = '', 
             reset_token = $1, token_expires_at = $2
         WHERE id = $3`,
        [token, tokenExpiresAt, otp.id],
      );

      console.log(`✅ OTP verificado com sucesso para usuário ${userId}`);

      return token;
    } finally {
      client.release();
    }
  }

  /**
   * Gera token temporário JWT simples (será usado apenas uma vez)
   * Por simplicidade, usamos um hash único. Em produção, usar JWT real.
   */
  private generateTempToken(userId: string): string {
    const payload = {
      userId,
      type: 'password_reset',
      timestamp: Date.now(),
    };
    const token = crypto.createHash('sha256').update(JSON.stringify(payload)).digest('hex');
    return token;
  }

  /**
   * Valida token temporário e retorna userId
   */
  async validateTempToken(token: string): Promise<{ userId: string; valid: boolean }> {
    const client = await this.pool.connect();
    try {
      // Buscar OTP verificado com token válido
      const result = await client.query(
        `SELECT user_id, token_expires_at
         FROM password_reset_otps
         WHERE verified = TRUE 
           AND reset_token = $1
           AND token_expires_at > NOW()`,
        [token],
      );

      if (result.rows.length === 0) {
        return { userId: '', valid: false };
      }

      const otp = result.rows[0];
      return { userId: otp.user_id, valid: true };
    } finally {
      client.release();
    }
  }

  /**
   * Invalida token após uso
   */
  async invalidateToken(token: string): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query(
        `UPDATE password_reset_otps 
         SET reset_token = NULL, token_expires_at = NULL 
         WHERE reset_token = $1`,
        [token],
      );
    } finally {
      client.release();
    }
  }

  /**
   * Limpa OTPs expirados (job de limpeza)
   */
  async cleanupExpiredOtps(): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query(
        `DELETE FROM password_reset_otps 
         WHERE expires_at < NOW() - INTERVAL '1 hour'`,
      );
      console.log('✅ OTPs expirados removidos');
    } finally {
      client.release();
    }
  }

  /**
   * Criptografa CPF para armazenamento
   */
  private encryptCpf(cpf: string): string {
    const encrypted = this.encryptionService.encrypt(cpf);
    if (!encrypted) {
      throw new Error('Falha ao criptografar CPF');
    }
    return encrypted;
  }

  /**
   * Cria um novo código OTP para cadastro (usuário ainda não existe)
   */
  async createRegistrationOtp(cpf: string, phone: string): Promise<{ otpCode: string; expiresAt: Date }> {
    const client = await this.pool.connect();

    try {
      // Criptografar CPF e telefone
      const encryptedCpf = this.encryptCpf(cpf);
      const encryptedPhone = this.encryptPhone(phone);

      // Verificar se já existe um OTP ativo e não verificado para este CPF+telefone
      const existingOtp = await client.query(
        `SELECT id, attempts, expires_at 
         FROM registration_otps 
         WHERE cpf = $1 AND phone = $2 AND verified = FALSE AND expires_at > NOW()
         ORDER BY created_at DESC 
         LIMIT 1`,
        [encryptedCpf, encryptedPhone],
      );

      if (existingOtp.rows.length > 0) {
        const otp = existingOtp.rows[0];
        const expiresAt = new Date(otp.expires_at);
        const now = new Date();
        const minutesRemaining = Math.ceil((expiresAt.getTime() - now.getTime()) / (1000 * 60));

        if (minutesRemaining > 2) {
          // Ainda há tempo suficiente no código existente (mais de 2 minutos)
          throw new BadRequestException(
            `Aguarde ${minutesRemaining} minutos antes de solicitar um novo código`,
          );
        }

        // Invalidar OTP anterior
        await client.query(
          `UPDATE registration_otps SET verified = TRUE WHERE id = $1`,
          [otp.id],
        );
      }

      // Gerar novo código OTP
      const otpCode = this.generateOtpCode();
      const otpHash = this.hashOtpCode(otpCode);
      const expiresAt = new Date();
      expiresAt.setMinutes(expiresAt.getMinutes() + this.OTP_EXPIRY_MINUTES);

      // Inserir no banco
      await client.query(
        `INSERT INTO registration_otps (
          cpf, phone, otp_code_hash, otp_code, expires_at, verified, attempts
        ) VALUES ($1, $2, $3, $4, $5, FALSE, 0)`,
        [encryptedCpf, encryptedPhone, otpHash, otpCode, expiresAt],
      );

      console.log(`✅ OTP de cadastro criado para CPF ${cpf.substring(0, 3)}***, expira em ${expiresAt.toISOString()}`);

      return {
        otpCode,
        expiresAt,
      };
    } finally {
      client.release();
    }
  }

  /**
   * Verifica código OTP de cadastro
   */
  async verifyRegistrationOtp(cpf: string, phone: string, otpCode: string): Promise<boolean> {
    const client = await this.pool.connect();

    try {
      // Criptografar CPF e telefone para busca
      const encryptedCpf = this.encryptCpf(cpf);
      const encryptedPhone = this.encryptPhone(phone);

      // Buscar OTP não verificado e não expirado
      const result = await client.query(
        `SELECT id, otp_code_hash, otp_code, attempts, expires_at, verified
         FROM registration_otps
         WHERE cpf = $1 AND phone = $2 AND verified = FALSE AND expires_at > NOW()
         ORDER BY created_at DESC
         LIMIT 1`,
        [encryptedCpf, encryptedPhone],
      );

      if (result.rows.length === 0) {
        throw new NotFoundException('Código OTP não encontrado ou expirado');
      }

      const otp = result.rows[0];

      // Verificar tentativas
      if (otp.attempts >= this.MAX_ATTEMPTS) {
        await client.query(
          `UPDATE registration_otps SET verified = TRUE WHERE id = $1`,
          [otp.id],
        );
        throw new UnauthorizedException(
          'Máximo de tentativas excedido. Solicite um novo código.',
        );
      }

      // Verificar código
      const otpHash = this.hashOtpCode(otpCode);
      const isValid = otpHash === otp.otp_code_hash;

      // Incrementar tentativas
      await client.query(
        `UPDATE registration_otps SET attempts = attempts + 1 WHERE id = $1`,
        [otp.id],
      );

      if (!isValid) {
        throw new UnauthorizedException('Código OTP inválido');
      }

      // Marcar como verificado
      await client.query(
        `UPDATE registration_otps 
         SET verified = TRUE, verified_at = NOW(), otp_code = ''
         WHERE id = $1`,
        [otp.id],
      );

      console.log(`✅ OTP de cadastro verificado com sucesso para CPF ${cpf.substring(0, 3)}***`);

      return true;
    } finally {
      client.release();
    }
  }

  /**
   * Limpa OTPs de cadastro expirados (job de limpeza)
   */
  async cleanupExpiredRegistrationOtps(): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query(
        `DELETE FROM registration_otps 
         WHERE expires_at < NOW() - INTERVAL '1 hour'`,
      );
      console.log('✅ OTPs de cadastro expirados removidos');
    } finally {
      client.release();
    }
  }
}

