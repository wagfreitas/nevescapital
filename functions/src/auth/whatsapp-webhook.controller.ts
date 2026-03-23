import { Controller, Post, Body, Logger } from '@nestjs/common';
import { WhatsAppService } from './services/whatsapp.service';

/**
 * Webhook chamado pela Twilio quando alguém envia uma mensagem
 * para o número do canal. Responde com mensagem fixa informando que o canal é apenas para OTP.
 *
 * Formato Twilio: { From: 'whatsapp:+55...', Body: '...', MessageSid: '...', ... }
 */
@Controller('api/webhooks')
export class WhatsAppWebhookController {
  private readonly logger = new Logger(WhatsAppWebhookController.name);

  constructor(private readonly whatsAppService: WhatsAppService) {}

  @Post('whatsapp')
  async handleIncomingMessage(@Body() body: Record<string, any>) {
    try {
      const phone = this.extractPhone(body);
      const hasMessage = body.Body != null && String(body.Body).trim().length > 0;

      if (!phone || !hasMessage) {
        this.logger.debug(`Webhook ignorado (sem telefone ou sem mensagem): ${JSON.stringify(body).substring(0, 200)}`);
        return { received: true };
      }

      if (phone.length < 12) {
        this.logger.warn(`Webhook: telefone inválido ${phone.substring(0, 4)}***`);
        return { received: true };
      }

      this.logger.log(`Mensagem recebida de ${phone.substring(0, 4)}*** - enviando resposta automática`);

      const sent = await this.whatsAppService.sendTextMessage(
        phone,
        WhatsAppService.AUTO_REPLY_MESSAGE,
      );

      if (!sent) {
        this.logger.warn(`Falha ao enviar resposta automática para ${phone.substring(0, 4)}***`);
      }

      return { received: true };
    } catch (error: any) {
      this.logger.error(`Erro no webhook WhatsApp: ${error.message}`, error.stack);
      return { received: true };
    }
  }

  /**
   * Extrai o telefone do payload Twilio.
   * Twilio envia From como 'whatsapp:+5511999999999'
   * Também suporta formato legado (api-wa.me) para compatibilidade.
   */
  private extractPhone(body: Record<string, any>): string | null {
    // Formato Twilio: From = 'whatsapp:+5511999999999'
    if (body.From) {
      return String(body.From).replace('whatsapp:', '').replace(/\D/g, '');
    }
    // Fallback legado
    const raw = body.from ?? body.contact_id ?? body.sender ?? body.from_number ?? body.phone;
    if (raw == null) return null;
    return String(raw).replace(/\D/g, '');
  }
}
