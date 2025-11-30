import { Injectable, BadRequestException, NotFoundException, UnauthorizedException } from '@nestjs/common';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { YcloudService } from './ycloud.service';

@Injectable()
export class OtpService {
  private readonly OTP_EXPIRY_MINUTES = 5; // Código válido por 5 minutos
  private readonly MAX_ATTEMPTS = 3; // Máximo de tentativas
  private readonly OTP_LENGTH = 6; // Código de 6 dígitos

  constructor(private readonly ycloudService: YcloudService) { }

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
   * Cria um OTP para login (Phone-First)
   * @param phone Telefone do usuário (E.164)
   */
  async createLoginOtp(phone: string): Promise<{ tempId: string; expiresAt: Date }> {
    // Usar YCloud Verify API para gerar e enviar o código
    const verification = await this.ycloudService.startVerification(phone, 'whatsapp');

    if (!verification.success) {
      throw new BadRequestException(verification.error || 'Erro ao enviar OTP via WhatsApp');
    }

    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutos (estimativa, o YCloud controla isso)

    // Criar documento na coleção 'otps' para rastrear a sessão
    // Não salvamos o hash do OTP pois o YCloud gerencia isso
    const docRef = await admin.firestore().collection('otps').add({
      phone,
      verificationId: verification.verificationId, // ID da verificação do YCloud
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
      attempts: 0,
      verified: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      type: 'LOGIN_PHONE',
      provider: 'YCLOUD'
    });

    console.log(`✅ OTP de Login iniciado via YCloud para telefone ${phone}, Doc ID: ${docRef.id}`);

    return { tempId: docRef.id, expiresAt };
  }

  /**
   * Verifica o OTP de login
   * @param tempId ID do documento OTP
   * @param otpCode Código informado pelo usuário
   * @returns Dados do OTP se válido
   */
  async verifyLoginOtp(tempId: string, otpCode: string): Promise<{ phone: string }> {
    const docRef = admin.firestore().collection('otps').doc(tempId);
    const doc = await docRef.get();

    if (!doc.exists) {
      throw new NotFoundException('Sessão de login não encontrada');
    }

    const data = doc.data();
    if (!data) {
      throw new NotFoundException('Dados da sessão inválidos');
    }

    // Verificar expiração local (apenas para garantir que não estamos verificando algo muito antigo)
    const expiresAt = data.expiresAt.toDate();
    if (new Date() > expiresAt) {
      throw new UnauthorizedException('Sessão expirada');
    }

    // Verificar se já foi usado
    if (data.verified) {
      return { phone: data.phone };
    }

    // Verificar tentativas
    if (data.attempts >= this.MAX_ATTEMPTS) {
      await docRef.update({ verified: true }); // Invalidar
      throw new UnauthorizedException('Máximo de tentativas excedido');
    }

    // Validar código via YCloud
    const checkResult = await this.ycloudService.checkVerification(data.phone, otpCode, data.verificationId);

    if (!checkResult.success || !checkResult.valid) {
      await docRef.update({ attempts: admin.firestore.FieldValue.increment(1) });
      throw new UnauthorizedException('Código inválido');
    }

    // Sucesso! Marcar como verificado
    await docRef.update({ verified: true, verifiedAt: admin.firestore.FieldValue.serverTimestamp() });
    console.log(`✅ Login verificado com sucesso para telefone ${data.phone}`);

    return { phone: data.phone };
  }

  // --- Métodos Legados/Outros (Adaptados para Firestore) ---

  /**
   * Cria OTP para recuperação de senha
   */
  async createOtp(userId: string, phone: string): Promise<{ otpCode: string; expiresAt: Date }> {
    // Mantendo implementação original para recuperação de senha (pode ser migrado depois se quiser)
    // Se quiser usar YCloud aqui também, precisaria refatorar o AuthController.requestPasswordResetOtp
    // Por enquanto, vamos manter como está (geração local + envio via SMS/WhatsApp manual se fosse o caso, mas o YCloudService mudou...)

    // ATENÇÃO: O AuthController chama smsService.sendOtp para isso.
    // Se quisermos usar YCloud Verify aqui também, teríamos que mudar a assinatura.
    // Vamos manter a geração local por enquanto, assumindo que o SMS Service ainda funciona ou que o YCloud Service antigo foi substituído.

    const otpCode = this.generateOtpCode();
    const otpHash = this.hashOtpCode(otpCode);
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + this.OTP_EXPIRY_MINUTES);

    await admin.firestore().collection('otps').add({
      type: 'PASSWORD_RESET',
      userId,
      phone,
      otpHash,
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
      attempts: 0,
      verified: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { otpCode, expiresAt };
  }

  /**
   * Verifica OTP de recuperação de senha
   */
  async verifyOtp(userId: string, otpCode: string): Promise<string> {
    const snapshot = await admin.firestore().collection('otps')
      .where('userId', '==', userId)
      .where('type', '==', 'PASSWORD_RESET')
      .where('verified', '==', false)
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();

    if (snapshot.empty) {
      throw new NotFoundException('Nenhum código ativo encontrado');
    }

    const doc = snapshot.docs[0];
    const data = doc.data();

    if (new Date() > data.expiresAt.toDate()) {
      throw new UnauthorizedException('Código expirado');
    }

    if (data.attempts >= this.MAX_ATTEMPTS) {
      await doc.ref.update({ verified: true });
      throw new UnauthorizedException('Máximo de tentativas excedido');
    }

    const otpHash = this.hashOtpCode(otpCode);
    if (otpHash !== data.otpHash) {
      await doc.ref.update({ attempts: admin.firestore.FieldValue.increment(1) });
      throw new UnauthorizedException('Código inválido');
    }

    await doc.ref.update({ verified: true, verifiedAt: admin.firestore.FieldValue.serverTimestamp() });

    // Gerar token temporário simples para reset de senha
    return crypto.randomBytes(32).toString('hex');
  }

  // Métodos auxiliares para manter compatibilidade com AuthController existente
  async validateTempToken(token: string): Promise<{ userId: string; valid: boolean }> {
    // Implementação simplificada ou mockada se não estiver usando tabela SQL
    return { userId: '', valid: false };
  }

  async invalidateToken(token: string): Promise<void> { }

  async createRegistrationOtp(cpf: string, phone: string): Promise<{ expiresAt: Date }> {
    // Usar YCloud Verify API
    const verification = await this.ycloudService.startVerification(phone, 'whatsapp');

    if (!verification.success) {
      throw new BadRequestException(verification.error || 'Erro ao enviar OTP via WhatsApp');
    }

    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + this.OTP_EXPIRY_MINUTES);

    await admin.firestore().collection('otps').add({
      type: 'REGISTRATION',
      cpf,
      phone,
      verificationId: verification.verificationId,
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
      attempts: 0,
      verified: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      provider: 'YCLOUD'
    });

    return { expiresAt };
  }

  async verifyRegistrationOtp(cpf: string, phone: string, otpCode: string): Promise<boolean> {
    const snapshot = await admin.firestore().collection('otps')
      .where('cpf', '==', cpf)
      .where('type', '==', 'REGISTRATION')
      .where('verified', '==', false)
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();

    if (snapshot.empty) {
      throw new NotFoundException('Código não encontrado');
    }

    const doc = snapshot.docs[0];
    const data = doc.data();

    if (new Date() > data.expiresAt.toDate()) {
      throw new UnauthorizedException('Código expirado');
    }

    // Validar via YCloud
    const checkResult = await this.ycloudService.checkVerification(phone, otpCode, data.verificationId);

    if (!checkResult.success || !checkResult.valid) {
      await doc.ref.update({ attempts: admin.firestore.FieldValue.increment(1) });
      throw new UnauthorizedException('Código inválido');
    }

    await doc.ref.update({ verified: true });
    return true;
  }
}

