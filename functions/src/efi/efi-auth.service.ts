import { Injectable, Logger, InternalServerErrorException } from '@nestjs/common';
import axios, { AxiosInstance } from 'axios';
import * as https from 'https';
import { EfiConfigService } from './efi-config.service';

/**
 * Gerencia OAuth2 client_credentials da Efí com mTLS.
 * Cacheia o access_token até ~10s antes da expiração.
 */
@Injectable()
export class EfiAuthService {
  private readonly logger = new Logger(EfiAuthService.name);

  private cachedToken: string | null = null;
  private cachedExpiresAt = 0; // epoch ms

  constructor(private readonly config: EfiConfigService) {}

  /**
   * Retorna um access_token válido. Faz refresh se faltar < 10s ou se nunca foi obtido.
   */
  async getAccessToken(): Promise<string> {
    const now = Date.now();
    const buffer = 10_000; // renova 10s antes de expirar

    if (this.cachedToken && this.cachedExpiresAt - buffer > now) {
      return this.cachedToken;
    }

    return this.fetchNewToken();
  }

  /**
   * Cria um client axios com mTLS configurado para chamar a Efí.
   * Pode ser usado por outros services (como o PixService).
   */
  buildHttpClient(): AxiosInstance {
    const httpsAgent = new https.Agent({
      pfx: this.config.certBuffer,
      passphrase: this.config.certPassphrase || '',
    });

    return axios.create({
      baseURL: this.config.baseUrl,
      httpsAgent,
      timeout: 15_000,
      validateStatus: () => true, // tratamos status code manualmente
    });
  }

  private async fetchNewToken(): Promise<string> {
    const client = this.buildHttpClient();
    const basicAuth = Buffer.from(
      `${this.config.clientId}:${this.config.clientSecret}`,
    ).toString('base64');

    this.logger.debug(
      `Solicitando novo token Efí (ambiente=${this.config.ambiente})`,
    );

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
      this.logger.error(
        `Falha ao obter token Efí: status=${response.status} body=${JSON.stringify(response.data)}`,
      );
      throw new InternalServerErrorException(
        `Efí auth falhou: ${response.status}`,
      );
    }

    const { access_token, expires_in } = response.data as {
      access_token: string;
      expires_in: number; // segundos
      token_type: string;
    };

    this.cachedToken = access_token;
    this.cachedExpiresAt = Date.now() + expires_in * 1000;

    this.logger.log(
      `Token Efí obtido. Expira em ${expires_in}s (${new Date(this.cachedExpiresAt).toISOString()}).`,
    );

    return access_token;
  }
}
