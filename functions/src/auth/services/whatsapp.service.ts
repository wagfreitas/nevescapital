import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { WhatsApp, TypeMessage } from '@raphaelvserafim/client-api-whatsapp';

@Injectable()
export class WhatsAppService {
  private readonly logger = new Logger(WhatsAppService.name);
  private whatsapp: WhatsApp;

  constructor(private readonly configService: ConfigService) {
    const server = this.configService.get<string>('WHATSAPP_API_SERVER', 'https://us.api-wa.me');
    const key = this.configService.get<string>('WHATSAPP_API_KEY', '');

    this.whatsapp = new WhatsApp({ server, key });
    this.logger.log(`WhatsApp service initialized (server: ${server})`);
  }

  /**
   * Envia mensagem OTP via WhatsApp
   * @param phone Telefone no formato 55XXXXXXXXXXX (apenas dígitos, com código do país)
   * @param code Código OTP
   * @returns true se enviou com sucesso
   */
  async sendOtpMessage(phone: string, code: string): Promise<boolean> {
    try {
      // Garantir que o phone está no formato correto (apenas dígitos)
      const cleanPhone = phone.replace(/\D/g, '');

      if (cleanPhone.length < 12) {
        this.logger.error(`Telefone inválido para WhatsApp: ${cleanPhone.substring(0, 4)}***`);
        return false;
      }

      this.logger.log(`Enviando OTP via WhatsApp para: ${cleanPhone.substring(0, 4)}***`);

      const response = await this.whatsapp.sendMessage({
        type: TypeMessage.TEXT,
        body: {
          to: cleanPhone,
          text: `${code} é o seu código de verificação PagPag.`,
        },
      });

      this.logger.log(`WhatsApp OTP enviado com sucesso: ${JSON.stringify(response)}`);
      return true;
    } catch (error) {
      this.logger.error(`Erro ao enviar OTP via WhatsApp: ${error.message}`, error.stack);
      return false;
    }
  }

  /**
   * Verifica se a conexão com o WhatsApp está ativa
   */
  async checkConnection(): Promise<boolean> {
    try {
      const info = await this.whatsapp.info();
      this.logger.log(`WhatsApp connection info: ${JSON.stringify(info)}`);
      return true;
    } catch (error) {
      this.logger.error(`WhatsApp connection check failed: ${error.message}`);
      return false;
    }
  }
}
