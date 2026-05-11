import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const Twilio = require('twilio');

@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);
  private client: any;
  private messagingServiceSid: string;

  constructor(private readonly configService: ConfigService) {
    const accountSid = this.configService.get<string>('TWILIO_ACCOUNT_SID', '');
    const authToken = this.configService.get<string>('TWILIO_AUTH_TOKEN', '');
    this.messagingServiceSid = this.configService.get<string>(
      'TWILIO_MESSAGING_SERVICE_SID',
      '',
    );

    this.client = Twilio(accountSid, authToken);
    this.logger.log(
      `SMS service initialized (Twilio, messagingServiceSid: ${this.messagingServiceSid || 'NOT_SET'})`,
    );
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
   * Envia codigo OTP via SMS usando Messaging Service.
   * O Messaging Service contem o Alpha Sender ID (ex: PAGPAG) cadastrado
   * para Brasil. Texto sem acentos garante encoding GSM-7 (1 segmento = 1 cobranca).
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

      if (!this.messagingServiceSid) {
        this.logger.error(
          'TWILIO_MESSAGING_SERVICE_SID nao configurado — SMS nao pode ser enviado',
        );
        return false;
      }

      this.logger.log(`Enviando OTP via SMS para: ${cleanPhone.substring(0, 4)}***`);

      const body = `Pag Pag: seu codigo de verificacao e ${code}. Nao compartilhe.`;

      const message = await this.client.messages.create({
        messagingServiceSid: this.messagingServiceSid,
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
