import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import * as path from 'path';

/**
 * Carrega configuração da Efí (URLs, credenciais, certificado mTLS).
 *
 * Suporta dois modos de fornecer o certificado:
 *   - EFI_CERT_PATH: caminho para o arquivo .p12 (uso local em dev)
 *   - EFI_CERT_BASE64: conteúdo do .p12 em base64 (uso em produção/Railway)
 *
 * O .p12 da Efí é gerado SEM passphrase (string vazia).
 */
@Injectable()
export class EfiConfigService implements OnModuleInit {
  private readonly logger = new Logger(EfiConfigService.name);

  private _ambiente: 'homologacao' | 'producao';
  private _baseUrl: string;
  private _clientId: string;
  private _clientSecret: string;
  private _certBuffer: Buffer;
  private _certPassphrase: string;

  constructor(private readonly configService: ConfigService) {}

  onModuleInit() {
    this._ambiente =
      (this.configService.get<string>('EFI_AMBIENTE') as
        | 'homologacao'
        | 'producao') || 'homologacao';

    this._baseUrl =
      this._ambiente === 'producao'
        ? 'https://pix.api.efipay.com.br'
        : 'https://pix-h.api.efipay.com.br';

    this._clientId = this.configService.get<string>('EFI_CLIENT_ID', '');
    this._clientSecret = this.configService.get<string>(
      'EFI_CLIENT_SECRET',
      '',
    );
    this._certPassphrase = this.configService.get<string>(
      'EFI_CERT_PASSPHRASE',
      '',
    );

    this._certBuffer = this.loadCertBuffer();

    if (!this._clientId || !this._clientSecret) {
      this.logger.warn(
        'EFI_CLIENT_ID ou EFI_CLIENT_SECRET não configurados — chamadas falharão.',
      );
    }

    this.logger.log(
      `Efí configurada: ambiente=${this._ambiente}, baseUrl=${this._baseUrl}, certBytes=${this._certBuffer?.length ?? 0}`,
    );
  }

  private loadCertBuffer(): Buffer {
    const base64 = this.configService.get<string>('EFI_CERT_BASE64');
    if (base64) {
      this.logger.debug('Certificado Efí carregado via EFI_CERT_BASE64');
      return Buffer.from(base64, 'base64');
    }

    const certPath = this.configService.get<string>('EFI_CERT_PATH');
    if (certPath) {
      // Resolve path relativo ao cwd do processo (geralmente functions/)
      const resolved = path.isAbsolute(certPath)
        ? certPath
        : path.resolve(process.cwd(), certPath);
      if (!fs.existsSync(resolved)) {
        this.logger.error(`Certificado não encontrado em: ${resolved}`);
        return Buffer.alloc(0);
      }
      this.logger.debug(`Certificado Efí carregado de: ${resolved}`);
      return fs.readFileSync(resolved);
    }

    this.logger.warn(
      'Nenhum certificado configurado (EFI_CERT_BASE64 ou EFI_CERT_PATH).',
    );
    return Buffer.alloc(0);
  }

  get ambiente() {
    return this._ambiente;
  }

  get baseUrl() {
    return this._baseUrl;
  }

  get clientId() {
    return this._clientId;
  }

  get clientSecret() {
    return this._clientSecret;
  }

  get certBuffer() {
    return this._certBuffer;
  }

  get certPassphrase() {
    return this._certPassphrase;
  }
}
