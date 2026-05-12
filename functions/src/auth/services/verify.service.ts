import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const Twilio = require('twilio');

export interface VerifyResult {
  success: boolean;
  message: string;
  status?: string;
}

@Injectable()
export class VerifyService {
  private readonly logger = new Logger(VerifyService.name);
  private client: any;
  private verifyServiceSid: string;

  constructor(private readonly configService: ConfigService) {
    const accountSid = this.configService.get<string>('TWILIO_ACCOUNT_SID', '');
    const authToken = this.configService.get<string>('TWILIO_AUTH_TOKEN', '');
    this.verifyServiceSid = this.configService.get<string>(
      'TWILIO_VERIFY_SERVICE_SID',
      '',
    );

    this.client = Twilio(accountSid, authToken);
    this.logger.log(
      `Verify service initialized (Twilio, verifyServiceSid: ${this.verifyServiceSid ? this.verifyServiceSid.substring(0, 6) + '...' : 'NOT_SET'})`,
    );
  }

  private formatPhone(phone: string): string {
    const clean = phone.replace(/\D/g, '');
    return `+${clean}`;
  }

  /**
   * Envia verificação via Twilio Verify API v2.
   * @param phoneNumber Telefone com DDI (ex: 5511999999999)
   * @param channel Canal de envio: 'sms' ou 'whatsapp'
   */
  async sendVerification(
    phoneNumber: string,
    channel: 'sms' | 'whatsapp' = 'sms',
  ): Promise<VerifyResult> {
    try {
      const cleanPhone = phoneNumber.replace(/\D/g, '');

      if (cleanPhone.length < 12) {
        this.logger.error(
          `Telefone invalido para Verify: ${cleanPhone.substring(0, 4)}***`,
        );
        return {
          success: false,
          message: 'Numero de telefone invalido',
        };
      }

      if (!this.verifyServiceSid) {
        this.logger.error(
          'TWILIO_VERIFY_SERVICE_SID nao configurado — Verify nao pode ser usado',
        );
        return {
          success: false,
          message: 'Servico de verificacao nao configurado',
        };
      }

      this.logger.log(
        `Enviando verificacao via ${channel} para: ${cleanPhone.substring(0, 4)}***`,
      );

      const verification = await this.client.verify.v2
        .services(this.verifyServiceSid)
        .verifications.create({
          to: this.formatPhone(cleanPhone),
          channel,
        });

      this.logger.log(
        `Verificacao enviada com sucesso (SID: ${verification.sid}, status: ${verification.status}, channel: ${channel})`,
      );

      return {
        success: true,
        message: `Codigo de verificacao enviado via ${channel === 'whatsapp' ? 'WhatsApp' : 'SMS'}`,
        status: verification.status,
      };
    } catch (error: any) {
      return this.handleTwilioError(error, 'sendVerification');
    }
  }

  /**
   * Verifica o código OTP via Twilio Verify API v2.
   * @param phoneNumber Telefone com DDI (ex: 5511999999999)
   * @param code Código OTP digitado pelo usuário
   */
  async checkVerification(
    phoneNumber: string,
    code: string,
  ): Promise<VerifyResult> {
    try {
      const cleanPhone = phoneNumber.replace(/\D/g, '');

      if (cleanPhone.length < 12) {
        this.logger.error(
          `Telefone invalido para Verify check: ${cleanPhone.substring(0, 4)}***`,
        );
        return {
          success: false,
          message: 'Numero de telefone invalido',
        };
      }

      if (!this.verifyServiceSid) {
        this.logger.error(
          'TWILIO_VERIFY_SERVICE_SID nao configurado — Verify nao pode ser usado',
        );
        return {
          success: false,
          message: 'Servico de verificacao nao configurado',
        };
      }

      this.logger.log(
        `Verificando codigo para: ${cleanPhone.substring(0, 4)}***`,
      );

      const verificationCheck = await this.client.verify.v2
        .services(this.verifyServiceSid)
        .verificationChecks.create({
          to: this.formatPhone(cleanPhone),
          code,
        });

      if (verificationCheck.status === 'approved') {
        this.logger.log(
          `Codigo verificado com sucesso para: ${cleanPhone.substring(0, 4)}***`,
        );
        return {
          success: true,
          message: 'Codigo verificado com sucesso',
          status: verificationCheck.status,
        };
      }

      this.logger.warn(
        `Codigo invalido ou expirado para: ${cleanPhone.substring(0, 4)}*** (status: ${verificationCheck.status})`,
      );
      return {
        success: false,
        message: 'Codigo invalido ou expirado',
        status: verificationCheck.status,
      };
    } catch (error: any) {
      return this.handleTwilioError(error, 'checkVerification');
    }
  }

  private handleTwilioError(error: any, method: string): VerifyResult {
    const code = error.code as number | undefined;
    const status = error.status as number | undefined;

    if (code === 60200) {
      this.logger.warn(`[${method}] Numero invalido (Twilio 60200): ${error.message}`);
      return {
        success: false,
        message: 'Numero de telefone invalido ou nao pode receber verificacao',
      };
    }

    if (code === 60203) {
      this.logger.warn(`[${method}] Maximo de tentativas atingido (Twilio 60203)`);
      return {
        success: false,
        message: 'Maximo de tentativas de verificacao atingido. Aguarde antes de tentar novamente.',
      };
    }

    if (code === 60202) {
      this.logger.warn(`[${method}] Codigo expirado ou ja verificado (Twilio 60202)`);
      return {
        success: false,
        message: 'Codigo expirado ou ja utilizado. Solicite um novo codigo.',
      };
    }

    if (status === 429 || code === 20429) {
      this.logger.warn(`[${method}] Rate limit atingido (Twilio 429)`);
      return {
        success: false,
        message: 'Muitas tentativas. Aguarde alguns minutos antes de tentar novamente.',
      };
    }

    this.logger.error(
      `[${method}] Erro Twilio Verify: ${error.message} (code: ${code}, status: ${status})`,
      error.stack,
    );

    return {
      success: false,
      message: 'Erro ao processar verificacao. Tente novamente.',
    };
  }
}
