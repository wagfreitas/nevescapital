import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as https from 'https';

@Injectable()
export class YcloudService {
  private readonly apiKey: string;
  private readonly apiUrl: string = 'https://api.ycloud.com/v1';
  private readonly whatsappNumber: string;

  constructor(private readonly configService: ConfigService) {
    this.apiKey = this.configService.get<string>('YCLOUD_API_KEY', '');
    this.whatsappNumber = this.configService.get<string>('YCLOUD_WHATSAPP_NUMBER', '');

    if (!this.apiKey) {
      console.warn('⚠️ Ycloud não configurado. Variável YCLOUD_API_KEY necessária.');
    } else {
      console.log('✅ Ycloud inicializado com sucesso');
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
   * Envia código OTP via WhatsApp usando Ycloud Verify API
   * Nota: Ycloud Verify gerencia o código automaticamente, mas podemos enviar mensagem customizada também
   */
  async sendOtp(phone: string, otpCode: string): Promise<{ success: boolean; messageId?: string; error?: string }> {
    if (!this.apiKey) {
      return {
        success: false,
        error: 'Ycloud não configurado',
      };
    }

    const formattedPhone = this.formatPhoneNumber(phone);

    try {
      // Opção 1: Usar Ycloud Verify API (gerencia OTP automaticamente)
      // const response = await this.makeRequest('POST', '/verify/send', {
      //   to: formattedPhone,
      //   channel: 'whatsapp',
      // });

      // Opção 2: Enviar mensagem customizada via WhatsApp Messages API
      const message = `Seu código de verificação é: ${otpCode}\n\nEste código expira em 10 minutos.\n\nNão compartilhe este código com ninguém.`;
      
      const response = await this.makeRequest('POST', '/messages', {
        to: formattedPhone,
        type: 'text',
        text: {
          body: message,
        },
        // Usar número WhatsApp configurado no Ycloud
        from: this.whatsappNumber || 'whatsapp',
      });

      if (response.success) {
        console.log(`✅ OTP enviado via Ycloud WhatsApp para ${formattedPhone}`);
        return {
          success: true,
          messageId: response.data?.id || response.data?.messageId,
        };
      } else {
        throw new Error(response.error || 'Erro ao enviar OTP');
      }
    } catch (error: any) {
      console.error(`❌ Erro ao enviar OTP via Ycloud para ${formattedPhone}:`, error.message);
      return {
        success: false,
        error: error.message || 'Erro ao enviar mensagem',
      };
    }
  }

  /**
   * Verifica código OTP usando Ycloud Verify API
   */
  async verifyOtp(phone: string, otpCode: string): Promise<{ success: boolean; error?: string }> {
    if (!this.apiKey) {
      return {
        success: false,
        error: 'Ycloud não configurado',
      };
    }

    const formattedPhone = this.formatPhoneNumber(phone);

    try {
      const response = await this.makeRequest('POST', '/verify/check', {
        to: formattedPhone,
        code: otpCode,
      });

      if (response.success && response.data?.valid === true) {
        console.log(`✅ OTP verificado com sucesso para ${formattedPhone}`);
        return { success: true };
      } else {
        return {
          success: false,
          error: 'Código OTP inválido',
        };
      }
    } catch (error: any) {
      console.error(`❌ Erro ao verificar OTP via Ycloud:`, error.message);
      return {
        success: false,
        error: error.message || 'Erro ao verificar código',
      };
    }
  }

  /**
   * Faz requisição HTTP para a API do Ycloud
   */
  private async makeRequest(method: string, endpoint: string, data: any): Promise<any> {
    return new Promise((resolve, reject) => {
      const url = `${this.apiUrl}${endpoint}`;
      const postData = JSON.stringify(data);

      const options = {
        method,
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': this.apiKey,
          'Content-Length': Buffer.byteLength(postData),
        },
      };

      const req = https.request(url, options, (res) => {
        let responseData = '';

        res.on('data', (chunk) => {
          responseData += chunk;
        });

        res.on('end', () => {
          try {
            const parsed = JSON.parse(responseData);
            if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
              resolve({ success: true, data: parsed });
            } else {
              resolve({
                success: false,
                error: parsed.message || parsed.error || 'Erro na requisição',
              });
            }
          } catch (e) {
            resolve({
              success: false,
              error: 'Erro ao processar resposta',
            });
          }
        });
      });

      req.on('error', (error) => {
        reject(error);
      });

      req.write(postData);
      req.end();
    });
  }

  /**
   * Verifica se o serviço está configurado
   */
  isConfigured(): boolean {
    return !!this.apiKey;
  }
}

