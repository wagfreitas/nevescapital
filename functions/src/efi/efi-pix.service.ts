import {
  Injectable,
  Logger,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { EfiAuthService } from './efi-auth.service';
import { SendPixDto } from './dto/send-pix.dto';

/**
 * Serviço de PIX-out via Efí.
 *
 * Endpoint principal: PUT /v3/gn/pix/{idEnvio}
 *   - idEnvio: identificador único da transação (idempotência).
 *     Se a Pag Pag retentar com o mesmo idEnvio, a Efí retorna o resultado
 *     anterior em vez de duplicar.
 *
 * Doc: https://dev.efipay.com.br/docs/api-pix/envio-pagamento-pix/
 */
@Injectable()
export class EfiPixService {
  private readonly logger = new Logger(EfiPixService.name);

  constructor(private readonly auth: EfiAuthService) {}

  /**
   * Dispara um PIX. Suporta envio por chave, copia-e-cola ou dados bancários.
   * Retorna o e2eId quando a Efí confirma o agendamento (assíncrono — confirmação
   * final vem por webhook).
   *
   * IMPORTANTE: a `pagador.chave` precisa ter um webhook associado.
   * Sem isso, a Efí recusa com `documento_bloqueado`.
   */
  async sendPix(dto: SendPixDto, idEnvio?: string): Promise<EfiSendPixResponse> {
    const token = await this.auth.getAccessToken();
    const client = this.auth.buildHttpClient();
    const id = idEnvio ?? this.generateIdEnvio();

    const modalidade = this.detectModalidade(dto);
    const body = this.buildSendPixBody(dto);
    const url = this.buildEndpointUrl(modalidade, id);

    this.logger.log(
      `Enviando PIX idEnvio=${id} valor=${dto.valor} modalidade=${modalidade} endpoint=${url}`,
    );

    const response = await client.put(url, body, {
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    });

    if (response.status >= 200 && response.status < 300) {
      this.logger.log(
        `PIX agendado: idEnvio=${id} e2eId=${response.data?.e2eId} status=${response.data?.status}`,
      );
      return {
        idEnvio: id,
        e2eId: response.data?.e2eId,
        status: response.data?.status,
        valor: response.data?.valor,
        horario: response.data?.horario,
      };
    }

    this.logger.error(
      `Falha ao enviar PIX: status=${response.status} body=${JSON.stringify(response.data)}`,
    );
    throw new HttpException(
      {
        message: 'Falha no envio do PIX via Efí',
        efiStatus: response.status,
        efiBody: response.data,
      },
      HttpStatus.BAD_GATEWAY,
    );
  }

  /**
   * Consulta um PIX enviado pelo idEnvio.
   */
  async getPixStatus(idEnvio: string): Promise<unknown> {
    const token = await this.auth.getAccessToken();
    const client = this.auth.buildHttpClient();

    const response = await client.get(`/v3/gn/pix/enviados/${idEnvio}`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    if (response.status >= 200 && response.status < 300) {
      return response.data;
    }
    throw new HttpException(
      {
        message: 'Falha ao consultar PIX',
        efiStatus: response.status,
        efiBody: response.data,
      },
      HttpStatus.BAD_GATEWAY,
    );
  }

  /**
   * Registra um webhook na chave PIX do pagador.
   *
   * Pré-requisito CRÍTICO para PIX-out via API: sem webhook na pagador.chave,
   * a Efí recusa o envio com `documento_bloqueado`.
   *
   * Endpoint: PUT /v2/webhook/:chave
   * Doc: https://dev.efipay.com.br/docs/api-pix/webhooks/
   *
   * @param chave Chave PIX do pagador (a que está registrada na conta Efí)
   * @param webhookUrl URL HTTPS pública do nosso receiver
   */
  async registerWebhook(chave: string, webhookUrl: string): Promise<unknown> {
    const token = await this.auth.getAccessToken();
    const client = this.auth.buildHttpClient();

    this.logger.log(
      `Registrando webhook na chave ${chave.substring(0, 8)}*** → ${webhookUrl}`,
    );

    // Header x-skip-mtls-checking permite que o webhook URL não precise de mTLS
    // (necessário pra dev/ngrok). Em produção, manter mTLS no receiver.
    const response = await client.put(
      `/v2/webhook/${encodeURIComponent(chave)}`,
      { webhookUrl },
      {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
          'x-skip-mtls-checking': 'true',
        },
      },
    );

    if (response.status >= 200 && response.status < 300) {
      this.logger.log(`Webhook registrado com sucesso na chave ${chave.substring(0, 8)}***`);
      return response.data ?? { ok: true };
    }
    throw new HttpException(
      {
        message: 'Falha ao registrar webhook',
        efiStatus: response.status,
        efiBody: response.data,
      },
      HttpStatus.BAD_GATEWAY,
    );
  }

  /**
   * Consulta o webhook registrado em uma chave.
   */
  async getWebhook(chave: string): Promise<unknown> {
    const token = await this.auth.getAccessToken();
    const client = this.auth.buildHttpClient();

    const response = await client.get(
      `/v2/webhook/${encodeURIComponent(chave)}`,
      { headers: { Authorization: `Bearer ${token}` } },
    );

    if (response.status >= 200 && response.status < 300) {
      return response.data;
    }
    if (response.status === 404) {
      return { configured: false };
    }
    throw new HttpException(
      {
        message: 'Falha ao consultar webhook',
        efiStatus: response.status,
        efiBody: response.data,
      },
      HttpStatus.BAD_GATEWAY,
    );
  }

  /**
   * Consulta o saldo da conta Efí.
   */
  async getBalance(): Promise<unknown> {
    const token = await this.auth.getAccessToken();
    const client = this.auth.buildHttpClient();

    const response = await client.get('/v2/gn/saldo', {
      headers: { Authorization: `Bearer ${token}` },
    });

    if (response.status >= 200 && response.status < 300) {
      return response.data;
    }
    throw new HttpException(
      {
        message: 'Falha ao consultar saldo',
        efiStatus: response.status,
        efiBody: response.data,
      },
      HttpStatus.BAD_GATEWAY,
    );
  }

  // ------- helpers -------

  private generateIdEnvio(): string {
    // idEnvio: 32 caracteres hex (UUID v4 sem hífens). Único por requisição.
    return randomUUID().replace(/-/g, '');
  }

  private detectModalidade(
    dto: SendPixDto,
  ): 'chave' | 'copiaECola' | 'dadosBancarios' {
    if (dto.chave) return 'chave';
    if (dto.pixCopiaECola) return 'copiaECola';
    return 'dadosBancarios';
  }

  /**
   * Endpoints distintos por modalidade (conforme doc oficial Efí):
   *   - chave / dadosBancarios: PUT /v3/gn/pix/:idEnvio
   *   - copia-e-cola (QR Code): PUT /v2/gn/pix/:idEnvio/qrcode
   */
  private buildEndpointUrl(
    modalidade: 'chave' | 'copiaECola' | 'dadosBancarios',
    idEnvio: string,
  ): string {
    if (modalidade === 'copiaECola') {
      return `/v2/gn/pix/${idEnvio}/qrcode`;
    }
    return `/v3/gn/pix/${idEnvio}`;
  }

  private buildSendPixBody(dto: SendPixDto): Record<string, unknown> {
    // pagador.chave: a chave PIX registrada na conta Efí que dispara o pagamento.
    // Vem do DTO ou do .env (EFI_PAGADOR_CHAVE).
    // OBRIGATÓRIA — e precisa ter webhook configurado, senão Efí recusa.
    const pagadorChave = dto.pagadorChave || process.env.EFI_PAGADOR_CHAVE;

    const pagador: Record<string, unknown> = {};
    if (pagadorChave) {
      pagador.chave = pagadorChave;
    }
    if (dto.descricao) {
      pagador.infoPagador = dto.descricao;
    }

    // Pagamento de QR Code (copia-e-cola): formato diferente.
    if (dto.pixCopiaECola) {
      return {
        valor: dto.valor,
        pagador,
        pixCopiaECola: dto.pixCopiaECola,
      };
    }

    const base: Record<string, unknown> = {
      valor: dto.valor,
      pagador,
    };

    if (dto.chave) {
      base.favorecido = { chave: dto.chave };
    } else if (dto.dadosBancarios) {
      base.favorecido = {
        contaBanco: {
          nome: dto.dadosBancarios.nome,
          cpf: dto.dadosBancarios.cpfCnpj,
          codigoBanco: dto.dadosBancarios.banco,
          agencia: dto.dadosBancarios.agencia,
          conta: dto.dadosBancarios.conta,
          tipoConta: dto.dadosBancarios.tipoConta || 'cacc',
        },
      };
    }

    return base;
  }
}

export interface EfiSendPixResponse {
  idEnvio: string;
  e2eId?: string;
  status?: string;
  valor?: string;
  horario?: { solicitacao?: string; liquidacao?: string };
}
