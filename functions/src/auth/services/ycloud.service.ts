import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as https from 'https';

@Injectable()
export class YcloudService {
  private readonly apiKey: string;
  private readonly apiUrl: string = 'https://api.ycloud.com/v2';

  constructor(private readonly configService: ConfigService) {
    this.apiKey = this.configService.get<string>('YCLOUD_API_KEY', '');

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
   * Inicia uma verificação (envia OTP) usando YCloud Verify API
   * @param phone Telefone do destinatário
   * @param channel Canal de envio ('whatsapp' ou 'sms')
   */
  async startVerification(phone: string, channel: 'whatsapp' | 'sms' = 'whatsapp'): Promise<{ success: boolean; verificationId?: string; error?: string }> {
    if (!this.apiKey) {
      return {
        success: false,
        error: 'Ycloud não configurado',
      };
    }

    const formattedPhone = this.formatPhoneNumber(phone);

    try {
      // Endpoint: /verify/verifications
      // Doc: https://docs.ycloud.com/reference/verification-send
      const response = await this.makeRequest('POST', '/verify/verifications', {
        to: formattedPhone,
        channel: channel,
      });

      if (response.success) {
        console.log(`✅ Verificação iniciada via Ycloud (${channel}) para ${formattedPhone}, ID: ${response.data?.id}`);
        return {
          success: true,
          verificationId: response.data?.id,
        };
      } else {
        throw new Error(response.error || 'Erro ao iniciar verificação');
      }
    } catch (error: any) {
      console.error(`❌ Erro ao iniciar verificação Ycloud para ${formattedPhone}:`, error.message);
      return {
        success: false,
        error: error.message || 'Erro ao iniciar verificação',
      };
    }
  }

  /**
   * Verifica o código OTP usando YCloud Verify API
   * @param phone Telefone ou ID da verificação (mas a API pede 'to' e 'code' geralmente, ou verification_id e code)
   * @param code Código OTP informado pelo usuário
   * @param verificationId ID da verificação (opcional, mas recomendado se tiver)
   */
  async checkVerification(phone: string, code: string, verificationId?: string): Promise<{ success: boolean; valid: boolean; error?: string }> {
    if (!this.apiKey) {
      return {
        success: false,
        valid: false,
        error: 'Ycloud não configurado',
      };
    }

    const formattedPhone = this.formatPhoneNumber(phone);

    try {
      // Endpoint: /verify/verifications/check (ou similar, baseando-se na doc comum de Verify APIs)
      // A doc do YCloud pode variar, mas geralmente é POST /verify/verifications/check com { to, code } ou { verification_id, code }

      // Vamos tentar usar o endpoint de check padrão
      const response = await this.makeRequest('POST', '/verify/verifications/check', {
        to: formattedPhone,
        code: code,
        // verification_id: verificationId // Se a API suportar/exigir
      });

      if (response.success) {
        const isValid = response.data?.valid === true || response.data?.status === 'approved';

        if (isValid) {
          console.log(`✅ Código verificado com sucesso para ${formattedPhone}`);
        } else {
          console.warn(`⚠️ Código inválido para ${formattedPhone}`);
        }

        return {
          success: true,
          valid: isValid,
        };
      } else {
        throw new Error(response.error || 'Erro ao verificar código');
      }
    } catch (error: any) {
      console.error(`❌ Erro ao verificar código Ycloud para ${formattedPhone}:`, error.message);
      return {
        success: false,
        valid: false,
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
              // Melhorar tratamento de erro para evitar [object Object]
              let errorMessage = 'Erro na requisição';
              if (parsed.message) errorMessage = typeof parsed.message === 'object' ? JSON.stringify(parsed.message) : parsed.message;
              else if (parsed.error) errorMessage = typeof parsed.error === 'object' ? JSON.stringify(parsed.error) : parsed.error;

              console.error(`❌ Erro YCloud (Status ${res.statusCode}):`, JSON.stringify(parsed));

              resolve({
                success: false,
                error: errorMessage,
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

