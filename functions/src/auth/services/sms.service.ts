import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as twilio from 'twilio';

@Injectable()
export class SmsService {
  private twilioClient: twilio.Twilio | null = null;
  private readonly fromPhoneNumber: string;
  private readonly whatsappEnabled: boolean;

  constructor(private readonly configService: ConfigService) {
    const accountSid = this.configService.get<string>('TWILIO_ACCOUNT_SID');
    const authToken = this.configService.get<string>('TWILIO_AUTH_TOKEN');
    this.fromPhoneNumber = this.configService.get<string>('TWILIO_PHONE_NUMBER', '');
    this.whatsappEnabled = this.configService.get<boolean>('TWILIO_WHATSAPP_ENABLED', true);

    if (accountSid && authToken) {
      this.twilioClient = twilio(accountSid, authToken);
      console.log('✅ Twilio inicializado com sucesso');
    } else {
      console.warn('⚠️ Twilio não configurado. Variáveis TWILIO_ACCOUNT_SID e TWILIO_AUTH_TOKEN necessárias.');
    }
  }

  /**
   * Formata telefone para formato E.164 (ex: +5511999999999)
   */
  private formatPhoneNumber(phone: string): string {
    // Remove caracteres não numéricos
    let cleaned = phone.replace(/\D/g, '');

    // Se não começar com 55 (código do Brasil), adiciona
    if (!cleaned.startsWith('55')) {
      cleaned = '55' + cleaned;
    }

    // Adiciona o +
    return '+' + cleaned;
  }

  /**
   * Envia código OTP via WhatsApp (prioridade) ou SMS (fallback)
   */
  async sendOtp(phone: string, otpCode: string): Promise<{ success: boolean; method: 'whatsapp' | 'sms' | null; error?: string }> {
    if (!this.twilioClient) {
      return {
        success: false,
        method: null,
        error: 'Twilio não configurado',
      };
    }

    const formattedPhone = this.formatPhoneNumber(phone);
    const message = `Seu código de recuperação de senha é: ${otpCode}\n\nEste código expira em 10 minutos.\n\nNão compartilhe este código com ninguém.`;

    try {
      // Tentar WhatsApp primeiro (se habilitado e se o número estiver configurado)
      if (this.whatsappEnabled && this.fromPhoneNumber.startsWith('whatsapp:')) {
        try {
          await this.twilioClient.messages.create({
            body: message,
            from: this.fromPhoneNumber, // ex: 'whatsapp:+14155238886'
            to: `whatsapp:${formattedPhone}`,
          });

          console.log(`✅ OTP enviado via WhatsApp para ${formattedPhone}`);
          return { success: true, method: 'whatsapp' };
        } catch (whatsappError) {
          console.warn(`⚠️ Falha ao enviar via WhatsApp, tentando SMS: ${whatsappError.message}`);
          // Fallback para SMS
        }
      }

      // Fallback para SMS
      const smsFromNumber = this.fromPhoneNumber.replace('whatsapp:', '');
      await this.twilioClient.messages.create({
        body: message,
        from: smsFromNumber,
        to: formattedPhone,
      });

      console.log(`✅ OTP enviado via SMS para ${formattedPhone}`);
      return { success: true, method: 'sms' };
    } catch (error: any) {
      console.error(`❌ Erro ao enviar OTP para ${formattedPhone}:`, error.message);
      return {
        success: false,
        method: null,
        error: error.message || 'Erro ao enviar mensagem',
      };
    }
  }

  /**
   * Verifica se o serviço está configurado
   */
  isConfigured(): boolean {
    return this.twilioClient !== null;
  }
}

