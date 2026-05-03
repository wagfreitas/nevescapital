import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class EfiConfigService implements OnModuleInit {
  private readonly logger = new Logger(EfiConfigService.name);

  private _ambiente: 'homologacao' | 'producao';
  private _baseUrl: string;
  private _clientId: string;
  private _clientSecret: string;
  private _certBuffer: Buffer;
  private _certPassphrase: string;
  private _pagadorChave: string;
  private _isConfigValid = false;

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
    this._pagadorChave = this.configService.get<string>(
      'EFI_PAGADOR_CHAVE',
      '',
    );

    this._certBuffer = this.loadCertBuffer();
    this._isConfigValid = this.validate();

    this.logger.log(
      `Efí configurada: ambiente=${this._ambiente}, baseUrl=${this._baseUrl}, ` +
        `certBytes=${this._certBuffer?.length ?? 0}, valid=${this._isConfigValid}`,
    );
  }

  private validate(): boolean {
    const errors: string[] = [];

    if (!this._clientId) {
      errors.push('EFI_CLIENT_ID não configurado');
    }
    if (!this._clientSecret) {
      errors.push('EFI_CLIENT_SECRET não configurado');
    }
    if (!this._certBuffer || this._certBuffer.length === 0) {
      errors.push(
        'Certificado .p12 não carregado (configure EFI_CERT_BASE64 ou EFI_CERT_PATH)',
      );
    }
    if (!this._pagadorChave) {
      errors.push(
        'EFI_PAGADOR_CHAVE não configurada (obrigatória para PIX-out)',
      );
    }

    if (errors.length > 0) {
      this.logger.error(
        `Configuração Efí INCOMPLETA — PIX não funcionará:\n  - ${errors.join('\n  - ')}`,
      );
      return false;
    }

    return true;
  }

  private loadCertBuffer(): Buffer {
    const base64 = this.configService.get<string>('EFI_CERT_BASE64');
    if (base64) {
      const buf = Buffer.from(base64, 'base64');
      this.logger.debug(
        `Certificado Efí carregado via EFI_CERT_BASE64 (${buf.length} bytes)`,
      );
      return buf;
    }

    const certPath = this.configService.get<string>('EFI_CERT_PATH');
    if (certPath) {
      const resolved = path.isAbsolute(certPath)
        ? certPath
        : path.resolve(process.cwd(), certPath);
      if (!fs.existsSync(resolved)) {
        this.logger.error(`Certificado não encontrado em: ${resolved}`);
        return Buffer.alloc(0);
      }
      const buf = fs.readFileSync(resolved);
      this.logger.debug(
        `Certificado Efí carregado de: ${resolved} (${buf.length} bytes)`,
      );
      return buf;
    }

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

  get pagadorChave() {
    return this._pagadorChave;
  }

  get isConfigValid() {
    return this._isConfigValid;
  }
}
