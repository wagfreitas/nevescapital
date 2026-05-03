import {
  Injectable,
  Logger,
  InternalServerErrorException,
  ServiceUnavailableException,
} from '@nestjs/common';
import axios, { AxiosInstance } from 'axios';
import * as https from 'https';
import { EfiConfigService } from './efi-config.service';

@Injectable()
export class EfiAuthService {
  private readonly logger = new Logger(EfiAuthService.name);

  private cachedToken: string | null = null;
  private cachedExpiresAt = 0;

  constructor(private readonly config: EfiConfigService) {}

  async getAccessToken(): Promise<string> {
    if (!this.config.isConfigValid) {
      throw new ServiceUnavailableException(
        'Efí não configurada. Verifique EFI_CLIENT_ID, EFI_CLIENT_SECRET, certificado e EFI_PAGADOR_CHAVE.',
      );
    }

    const now = Date.now();
    const buffer = 10_000;

    if (this.cachedToken && this.cachedExpiresAt - buffer > now) {
      return this.cachedToken;
    }

    return this.fetchNewToken();
  }

  buildHttpClient(): AxiosInstance {
    const httpsAgent = new https.Agent({
      pfx: this.config.certBuffer,
      passphrase: this.config.certPassphrase || '',
    });

    return axios.create({
      baseURL: this.config.baseUrl,
      httpsAgent,
      timeout: 15_000,
      validateStatus: () => true,
    });
  }

  private async fetchNewToken(): Promise<string> {
    const client = this.buildHttpClient();
    const basicAuth = Buffer.from(
      `${this.config.clientId}:${this.config.clientSecret}`,
    ).toString('base64');

    this.logger.debug(
      `Solicitando novo token Efí (ambiente=${this.config.ambiente}, ` +
        `baseUrl=${this.config.baseUrl}, certBytes=${this.config.certBuffer.length})`,
    );

    try {
      const response = await client.post(
        '/oauth/token',
        { grant_type: 'client_credentials' },
        {
          headers: {
            Authorization: `Basic ${basicAuth}`,
            'Content-Type': 'application/json',
          },
        },
      );

      if (response.status !== 200) {
        const body = response.data;
        const errorDesc =
          body?.error_description || body?.error || JSON.stringify(body);
        this.logger.error(
          `Falha ao obter token Efí: status=${response.status} error="${errorDesc}"`,
        );

        if (response.status === 401) {
          throw new InternalServerErrorException(
            `Efí auth 401: ${errorDesc}. ` +
              'Verifique: 1) EFI_CLIENT_ID/SECRET corretos para o ambiente ' +
              `(${this.config.ambiente}), 2) certificado .p12 pertence à mesma aplicação, ` +
              '3) aplicação está ativa no painel Efí.',
          );
        }

        throw new InternalServerErrorException(
          `Efí auth falhou: ${response.status} — ${errorDesc}`,
        );
      }

      const { access_token, expires_in } = response.data as {
        access_token: string;
        expires_in: number;
        token_type: string;
      };

      this.cachedToken = access_token;
      this.cachedExpiresAt = Date.now() + expires_in * 1000;

      this.logger.log(`Token Efí obtido. Expira em ${expires_in}s.`);

      return access_token;
    } catch (e) {
      if (
        e instanceof InternalServerErrorException ||
        e instanceof ServiceUnavailableException
      ) {
        throw e;
      }

      const message =
        e instanceof Error ? e.message : 'Erro desconhecido na autenticação';
      this.logger.error(`Erro de conexão com Efí: ${message}`);
      throw new InternalServerErrorException(
        `Erro de conexão com Efí: ${message}. ` +
          'Verifique se o certificado .p12 é válido e não está expirado.',
      );
    }
  }
}
