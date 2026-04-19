# Integração Efí Pay PIX API (Cash-In + Cash-Out + Cobranças + Split)

**Tipo:** Task
**Projeto:** SCRUM
**Prioridade:** Média / Alta (definir com time)

---

## Contexto

Avaliar e implementar integração com a API PIX da **Efí Pay** (ex-Gerencianet) como gateway PIX nativo do app Pag Pag. Hoje o app não tem PIX implementado (apenas cartão via Pagar.me, que está em reavaliação).

Documentação: https://dev.efipay.com.br/docs/api-pix/credenciais/

---

## Funcionalidades disponíveis

- **Cash-In automatizado**: receber PIX de clientes
- **Cash-Out via API**: enviar PIX direto da API
- **Cobranças imediatas (Pix Cob)**: gera QR Code + link para pagamento
- **Cobranças com vencimento (Pix CobV)**: boletos PIX com data
- **Split PIX**: repasse automático (útil para taxa da Pag Pag)
- **Webhooks**: confirmação de pagamento em tempo real
- **Extratos de conciliação automáticos**

---

## Modelo técnico

### Autenticação

- OAuth2 com HTTP Basic Auth (`Client_Id:Client_Secret` em base64)
- **mTLS obrigatório**: certificado PKCS12 (`.p12`) anexado a cada request
- Token bearer válido por **3600s (1h)** — precisa renovar

### Ambientes

| Tipo | Base URL |
|---|---|
| Produção | `https://pix.api.efipay.com.br` |
| Homologação | `https://pix-h.api.efipay.com.br` |

### Endpoints principais (padrão BCB)

| Método | Path | Função |
|---|---|---|
| POST | `/oauth/token` | Autenticação |
| PUT | `/v2/cob/{txid}` | Criar cobrança imediata |
| GET | `/v2/cob/{txid}` | Consultar cobrança |
| POST | `/v2/webhook/{chave}` | Registrar webhook |
| GET | `/v2/pix/{e2eid}` | Consultar PIX recebido |
| POST | `/v2/pix/{e2eid}/devolucao/{id}` | Estornar |

---

## Setup inicial necessário

1. Criar conta Efí Digital (CNPJ)
2. Criar aplicação no painel → gerar `Client_Id` e `Client_Secret`
3. Gerar certificado PKCS12 no painel (até 5 por ambiente, download único)
4. Configurar escopos: `cob.read`, `cob.write`, `pix.read`, `pix.write`, `webhook.read`, `webhook.write`
5. Cadastrar chave PIX (CPF/CNPJ/email/celular/aleatória)
6. Testar em homologação → migrar para produção

---

## Proposta de implementação

### Backend (NestJS em `functions/`)

- Criar módulo `EfiPixModule`
- Criar `EfiPixService` com:
  - `getAccessToken()` — cache de 55 min
  - `createCharge({txid, valor, devedor?, infoAdicionais})` — gera cobrança + QR Code
  - `getCharge(txid)` — consulta status
  - `registerWebhook(chave, url)` — registra callback
- Criar `EfiWebhookController` para receber notificações de pagamento
- Armazenar certificado `.p12` em volume seguro do Railway (**NÃO** no repo)
- Variáveis de ambiente:
  - `EFI_CLIENT_ID`
  - `EFI_CLIENT_SECRET`
  - `EFI_PIX_KEY`
  - `EFI_CERT_PATH` ou `EFI_CERT_BASE64`
  - `EFI_ENV` (`production` | `sandbox`)

### Flutter

- Novo fluxo de pagamento PIX:
  - Tela de valor já existe (`payment_step2_screen.dart`)
  - Substituir Step3 (bancários) + Step4 (cartão) pela geração de QR Code PIX
  - Nova tela: `payment_pix_qrcode_screen.dart`
  - Polling no backend para confirmar pagamento (ou listener via FCM + webhook)
- Atualizar `payment_step_helper.dart` para novo fluxo

---

## Questões em aberto (pré-implementação)

1. **Comercial**: tarifa por transação PIX na Efí (não aparece na doc técnica)
2. **Split**: validar se split nativo atende ao modelo da Pag Pag (taxa do app)
3. **Certificado**: definir storage seguro (Google Secret Manager? Railway volumes?)
4. **KYC/Onboarding**: Efí exige onboarding do lojista ou a Pag Pag opera como intermediadora?
5. **Webhook**: requer endpoint público HTTPS (Railway já atende)

---

## Critérios de aceite

- [ ] Backend autentica na API Efí (sandbox)
- [ ] Criar cobrança imediata e gerar QR Code funcional
- [ ] Webhook recebe notificação de pagamento
- [ ] Tela Flutter exibe QR Code + status "Aguardando pagamento"
- [ ] Atualização em tempo real quando pagamento confirmado
- [ ] Fluxo testado em homologação antes de produção
- [ ] Documentar processo de renovação de certificado

---

## Dependências

- Criação da conta Efí (CNPJ Pag Pag)
- Definição da chave PIX da Pag Pag
- Decisão sobre modelo de split (se aplicável)

---

## Referências

- Credenciais: https://dev.efipay.com.br/docs/api-pix/credenciais/
- Endpoints gerais: https://dev.efipay.com.br/docs/api-pix/endpoints
- Padrão BCB PIX API: https://bacen.github.io/pix-api/
