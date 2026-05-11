import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const Twilio = require('twilio');

@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);
  private client: any;
  private fromSenderId: string;

  constructor(private readonly configService: ConfigService) {
    const accountSid = this.configService.get<string>('TWILIO_ACCOUNT_SID', '');
    const authToken = this.configService.get<string>('TWILIO_AUTH_TOKEN', '');
    this.fromSenderId = this.configService.get<string>('TWILIO_SMS_FROM', 'PAGPAG');

    this.client = Twilio(accountSid, authToken);
    this.logger.log(`SMS service initialized (Twilio, sender: ${this.fromSenderId})`);
  }

  /**
   * Formata o telefone para o padrao E.164 (sem prefixo whatsapp:).
   * @param phone Telefone com DDI (ex: 5511999999999)
   */
  private formatPhone(phone: string): string {
    const clean = phone.replace(/\D/g, '');
    return `+${clean}`;
  }

  /**
   * Envia codigo OTP via SMS.
   * Texto sem acentos para garantir encoding GSM-7 (1 segmento = 1 cobranca).
   *
   * @param phone Telefone no formato 55XXXXXXXXXXX (apenas digitos, com codigo do pais)
   * @param code Codigo OTP
   * @returns true se enviou com sucesso
   */
  async sendOtpMessage(phone: string, code: string): Promise<boolean> {
    try {
      const cleanPhone = phone.replace(/\D/g, '');

      if (cleanPhone.length < 12) {
        this.logger.error(`Telefone invalido para SMS: ${cleanPhone.substring(0, 4)}***`);
        return false;
      }

      this.logger.log(`Enviando OTP via SMS para: ${cleanPhone.substring(0, 4)}***`);

      const body = `Pag Pag: seu codigo de verificacao e ${code}. Nao compartilhe.`;

      const message = await this.client.messages.create({
        from: this.fromSenderId,
        to: this.formatPhone(cleanPhone),
        body,
      });

      this.logger.log(`SMS OTP enviado com sucesso (SID: ${message.sid})`);
      return true;
    } catch (error: any) {
      this.logger.error(`Erro ao enviar OTP via SMS: ${error.message}`, error.stack);
      return false;
    }
  }
}
