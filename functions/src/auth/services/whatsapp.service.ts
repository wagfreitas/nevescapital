import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const Twilio = require('twilio');

@Injectable()
export class WhatsAppService {
  private readonly logger = new Logger(WhatsAppService.name);
  private client: any;
  private fromNumber: string;
  private otpContentSid: string;

  constructor(private readonly configService: ConfigService) {
    const accountSid = this.configService.get<string>('TWILIO_ACCOUNT_SID', '');
    const authToken = this.configService.get<string>('TWILIO_AUTH_TOKEN', '');
    this.fromNumber = this.configService.get<string>('TWILIO_WHATSAPP_FROM', '');
    this.otpContentSid = this.configService.get<string>(
      'TWILIO_OTP_CONTENT_SID',
      'HXc63e56630589f6a10de0d304c0ee09f1',
    );

    this.client = Twilio(accountSid, authToken);
    this.logger.log(`WhatsApp service initialized (Twilio, from: ${this.fromNumber}, otpTemplate: ${this.otpContentSid})`);
  }

  /** Mensagem fixa enviada quando o usuário envia qualquer mensagem no canal (apenas OTP). */
  static readonly AUTO_REPLY_MESSAGE =
    'Esse canal é destinado apenas ao envio de codigo OTP e nao está preparado para receber qualquer mensagem.';

  /**
   * Formata o telefone para o padrão Twilio WhatsApp: whatsapp:+XXXXXXXXXXX
   */
  private formatPhone(phone: string): string {
    const clean = phone.replace(/\D/g, '');
    return `whatsapp:+${clean}`;
  }

  /**
   * Envia uma mensagem de texto genérica para um número.
   * @param phone Telefone no formato 55XXXXXXXXXXX (apenas dígitos, com código do país)
   * @param text Texto da mensagem
   * @returns true se enviou com sucesso
   */
  async sendTextMessage(phone: string, text: string): Promise<boolean> {
    try {
      const cleanPhone = phone.replace(/\D/g, '');
      if (cleanPhone.length < 12) {
        this.logger.error(`Telefone inválido para WhatsApp: ${cleanPhone.substring(0, 4)}***`);
        return false;
      }

      const message = await this.client.messages.create({
        body: text,
        from: `whatsapp:${this.fromNumber}`,
        to: this.formatPhone(cleanPhone),
      });

      this.logger.log(`WhatsApp mensagem enviada para ${cleanPhone.substring(0, 4)}*** (SID: ${message.sid})`);
      return true;
    } catch (error: any) {
      this.logger.error(`Erro ao enviar mensagem WhatsApp: ${error.message}`, error.stack);
      return false;
    }
  }

  /**
   * Envia mensagem OTP via WhatsApp
   * @param phone Telefone no formato 55XXXXXXXXXXX (apenas dígitos, com código do país)
   * @param code Código OTP
   * @returns true se enviou com sucesso
   */
  async sendOtpMessage(phone: string, code: string): Promise<boolean> {
    try {
      const cleanPhone = phone.replace(/\D/g, '');

      if (cleanPhone.length < 12) {
        this.logger.error(`Telefone inválido para WhatsApp: ${cleanPhone.substring(0, 4)}***`);
        return false;
      }

      this.logger.log(`Enviando OTP via WhatsApp para: ${cleanPhone.substring(0, 4)}***`);

      const message = await this.client.messages.create({
        from: `whatsapp:${this.fromNumber}`,
        to: this.formatPhone(cleanPhone),
        contentSid: this.otpContentSid,
        contentVariables: JSON.stringify({ '1': code }),
      });

      this.logger.log(`WhatsApp OTP enviado com sucesso (SID: ${message.sid})`);
      return true;
    } catch (error: any) {
      this.logger.error(`Erro ao enviar OTP via WhatsApp: ${error.message}`, error.stack);
      return false;
    }
  }

  /**
   * Verifica se a conexão com o Twilio está ativa
   */
  async checkConnection(): Promise<boolean> {
    try {
      const sid = this.configService.get<string>('TWILIO_ACCOUNT_SID', '');
      const account = await this.client.api.accounts(sid).fetch();
      this.logger.log(`Twilio connection OK: ${account.friendlyName} (status: ${account.status})`);
      return account.status === 'active';
    } catch (error: any) {
      this.logger.error(`Twilio connection check failed: ${error.message}`);
      return false;
    }
  }
}
