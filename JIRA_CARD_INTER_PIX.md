# Spike: Validar API Banco Inter para PIX-out (tesouraria de adiantamento)

**Tipo:** Task (Spike Técnico)
**Projeto:** SCRUM
**Prioridade:** Alta (bloqueia arquitetura de tesouraria)
**Branch sugerida:** `spike/inter-pix-out`

---

## Contexto e modelo de negócio

A Pag Pag é um app POS ("maquininha") cujo diferencial é **adiantar imediatamente** ao vendedor o valor de cada venda confirmada — sem esperar D+1 (PIX) ou D+30 (cartão).

```
1. Comprador paga no app (cartão / PIX) → R$ 100
2. Pagamento é confirmado pelo acquirer
3. Pag Pag dispara PIX IMEDIATO de R$ X (R$ 100 - taxa Pag Pag)
   da SUA conta de tesouraria para a chave PIX do vendedor
4. Em D+1 / D+30 o dinheiro do comprador liquida na conta da Pag Pag,
   recompondo o caixa de tesouraria
5. Pag Pag ganha o spread (taxa de adiantamento)
```

**O Banco Inter, neste card, é avaliado como PROVEDOR DA TESOURARIA E DO PIX-OUT** — não como acquirer. O lado de entrada (recebimento do cartão/PIX do comprador) é tema de card separado e ainda em definição.

---

## Escopo deste spike

**Objetivo:** rodar **simulações end-to-end no sandbox do Inter** para validar que a API atende aos requisitos críticos do caso de uso de Pag Pag, **antes** de qualquer compromisso comercial.

**Fora de escopo:** integração com lado de entrada (acquirer), painel administrativo de tesouraria, fluxo regulatório/compliance, produção real.

---

## Achados técnicos da API (research prévio)

### Endpoints e autenticação

| Item | Valor |
|---|---|
| Base URL produção | `https://cdpj.partners.bancointer.com.br` |
| Token endpoint | `POST /oauth/v2/token` (OAuth2 `client_credentials`) |
| **PIX Pagamento (envio)** | `POST /banking/v2/pix-pagamento` |
| Escopo OAuth necessário | `pagamento-pix.write` |
| Token TTL | 60 minutos (cachear e reusar) |
| Autenticação | OAuth2 + **mTLS obrigatório** (cert `.p12`/`.pfx`) |
| Header de conta | `x-conta-corrente` (qual conta PJ debita) |
| Idempotência | Header `x-id-idempotente` |
| Modalidades de envio | Chave PIX, copia-e-cola, dados bancários |
| Sandbox | Disponível |
| SDKs oficiais | Java e C# apenas — **sem Node.js** |
| Webhooks | Suportado (registrável via API) |
| Pix Automático | Existe, mas é para *receber* (cobrança recorrente). Não serve. |
| CNAB | Disponível para reconciliação batch |

### Escopos OAuth conhecidos (relevantes pra Pag Pag)

- `pagamento-pix.write` — disparar PIX-out **(crítico)**
- `pix.read` — consultar PIX recebidos
- `webhook.write` / `webhook.read` — gerenciar webhooks
- `extrato.read` — extrato bancário (reconciliação)
- `cob.write` — cobrança PIX (não usado neste card)

---

## 🚨 Três alertas críticos identificados no research

### 1. Rate limit de **1 PIX/segundo** (60 PIX/minuto)

Documentado: *"60 calls per minute, limited to 1 call per second"*.

**Impacto:** em pico de venda (Black Friday, fim de mês), 200 vendas/min geram fila de 140 vendedores esperando — quebra a proposta de "receba imediatamente".

**Ação:** validar com Inter o rate limit elevado **antes** de assinar contrato.

### 2. Aprovação manual ligada por padrão

Documentado: *"this payment may require manual approval before execution... adjusted by the master user via Internet Banking"*.

**Impacto:** sem desligar, cada PIX cai em fila humana no Internet Banking — inviável.

**Ação:** confirmar com o Inter qual a régua de aprovação automática (teto por operação, teto diário) e configurar conta antes de testar.

### 3. Sem SDK Node.js oficial

Backend Pag Pag é NestJS. mTLS terá que ser implementado via `https.Agent` com `cert`/`key` em `Buffer`. Certificado precisa ficar como **env var no Railway** (PEM/base64), padrão `FIREBASE_SERVICE_ACCOUNT`.

**Risco:** sem SDK = manutenção/atualização da API por nossa conta. Risco baixo (a API é estável), mas existe.

---

## Tarefas do spike

### Setup (pré-requisito)
- [ ] Abrir conta PJ no Inter (CNPJ Pag Pag)
- [ ] No Internet Banking PJ: gerar credenciais de API (`client_id` + `client_secret`)
- [ ] Gerar certificado `.p12` para sandbox
- [ ] Solicitar acesso ao ambiente sandbox

### Implementação (backend NestJS, módulo isolado)
- [ ] Criar módulo `functions/src/inter/` (independente do código existente)
- [ ] Service `InterAuthService`: obtém e cacheia token OAuth (TTL 60min)
- [ ] Service `InterPixService`:
  - [ ] `sendPix({ chave, valor, descricao, idempotencyKey })` — envio por chave
  - [ ] `sendPix({ pixCopiaECola, valor, idempotencyKey })` — envio por copia-e-cola
  - [ ] `sendPix({ banco, agencia, conta, cpf, valor, idempotencyKey })` — envio por dados bancários
  - [ ] `getPaymentStatus(endToEndId)` — consulta status
- [ ] Controller `InterTestController` (rota interna `/api/_internal/inter/*`, protegida por `ApiKeyGuard`):
  - [ ] `POST /test/pix` — dispara PIX de teste
  - [ ] `POST /test/webhook-register` — registra webhook
  - [ ] `GET /test/balance` — consulta saldo
- [ ] Webhook receiver `POST /api/inter/webhook` (validação de assinatura)
- [ ] Tratamento de mTLS: certificado em env var, parseado em `Buffer` no boot

### Validações experimentais (sandbox)
- [ ] **Disparar 100 PIX seguidos**: medir latência média e P99
- [ ] **Disparar 70 PIX em 1 minuto**: confirmar comportamento ao bater rate limit (resposta? retry-after?)
- [ ] **Idempotência**: enviar 2× o mesmo `x-id-idempotente` — confirmar que não duplica
- [ ] **Webhook**: validar entrega após PIX bem-sucedido e após PIX recusado (saldo insuficiente)
- [ ] **Falha de rede**: simular timeout no client e validar que retry com mesmo idempotencyKey não duplica
- [ ] **Tempo de confirmação** real: do `POST` até o webhook chegar — média e cauda

### Métricas a coletar
- Latência do `POST /pix-pagamento`: P50, P95, P99
- Tempo entre `POST` e webhook de confirmação: P50, P95, P99
- Taxa de erro em 1.000 disparos sequenciais
- Comportamento ao bater rate limit (HTTP code, retry-after, comportamento da fila)

---

## Checklist comercial (para reunião com Inter)

> **🚨 Aprendizado do spike Efí (2026-04-27)**: a Efí, com setup default,
> exige **2FA por transação** para PIX-out (senha eletrônica + autenticador
> mobile). A API recebe erro genérico `documento_bloqueado`, mesmo com a
> conta liberada para PIX manual via web. Esse mesmo padrão é comum em
> bancos/PSPs e **pode invalidar o uso pra adiantamento automático**.
> Por isso, **a primeira pergunta pra qualquer provedor é**: posso disparar
> PIX-out via API contando só com mTLS + OAuth, sem 2FA por transação?

Antes de fechar contrato:

- [ ] **🔴 CRÍTICO — 2FA por transação**: posso disparar PIX-out via API sem 2FA por transação? Sem isso, a operação automática é inviável.
- [ ] Rate limit elevado para o volume estimado (X PIX/segundo de pico)?
- [ ] Aprovação automática sem teto operacional, ou com qual régua?
- [ ] Custo por PIX-out em volume: faixas de tarifação?
- [ ] Limite diário/mensal de PIX-out na conta?
- [ ] SLA publicado da API? Histórico de uptime?
- [ ] **Inter Empresas / BaaS**: Pag Pag pode operar adiantamento de recebíveis sob a licença Inter, ou precisa de licença IP/SCD própria?
- [ ] Saldo em conta rende? Aplicação automática em CDB Inter? Qual taxa?
- [ ] Certificado mTLS: rotação automática ou manual? Validade?
- [ ] Suporte técnico: canal dedicado para integradores?
- [ ] Possibilidade de operar **multi-conta** (uma conta master + sub-contas para segregação)?

---

## Critérios de aprovação do spike

O spike é considerado **bem-sucedido** se:

1. ✅ PIX-out funciona em sandbox (chave, copia-e-cola, dados bancários)
2. ✅ Idempotência impede duplicação em retry
3. ✅ Webhook chega com payload utilizável e em tempo hábil (< 5s P95)
4. ✅ Comportamento ao bater rate limit é tratável programaticamente
5. ✅ Latência do `POST` permite UX de "receba imediatamente" (< 1s P95)
6. ✅ Não há bloqueio de aprovação manual no fluxo automatizado

Se 3 ou mais critérios falharem → reavaliar com Efí ou Stark Bank.

---

## Comparação atualizada (sob ótica PIX-out / tesouraria)

| Critério | Inter | Efí |
|---|---|---|
| Custo por PIX enviado | ✅ Tipicamente grátis em conta PJ | ❌ Tarifa de gateway |
| Onde fica o dinheiro | ✅ Banco real (FGC, rendimento CDB) | ❌ Saldo PSP |
| Reconciliação | ✅ Extrato bancário único | ⚠️ Cruzamento PSP + banco |
| Rate limit | ⚠️ 60/min default (negociável) | ⚠️ Negociável (PSP) |
| SDK Node.js oficial | ❌ Não | ❌ Não |
| Aprovação manual | ⚠️ Default ligado, configurável | ✅ Não tem |
| BaaS / licença regulatória | ✅ Inter Empresas (negociar) | ✅ Licença IP própria |
| Doc PIX-out | ⚠️ JS-rendered, dispersa | ✅ PIX-first, mais clara |

**Recomendação preliminar:** Inter sai à frente **se** os 3 alertas (rate limit, aprovação automática, custo de PIX-out) forem resolvidos no contrato. Caso contrário, voltar à Efí ou avaliar **Stark Bank** (PIX-out em volume com SDK Node oficial — card a criar).

---

## Pendências fora deste card

- [ ] **Lado de entrada (acquirer)**: card separado em definição. Por enquanto, este spike usa **valores simulados** (Pag Pag finge que recebeu pagamento e dispara PIX).
- [ ] **Modelo regulatório**: avaliar necessidade de IP/SCD própria vs operar via BaaS (Inter Empresas ou Efí). Card separado.
- [ ] **Painel administrativo de tesouraria**: monitoramento de saldo, fila de PIX, retentativa, conciliação. Posterior à validação técnica.

---

## Referências

- [Inter — Portal do Desenvolvedor](https://developers.inter.co/references/pix)
- [Inter — API Banking Empresas](https://inter.co/empresas/api-banking/)
- [Inter — API Pix Empresas](https://inter.co/empresas/api-pix/)
- [Inter — Sandbox](https://developers.inter.co/sandbox)
- [Postman público — token endpoint Inter](https://www.postman.com/marlosoliveira/varejofacil/request/oav2pj4/https-cdpj-partners-bancointer-com-br-oauth-v2-token)
- [SDK comunitária Node.js (não oficial)](https://github.com/marmita-fit/inter-sdk)
- [SDK comunitária PHP (referência de endpoints)](https://github.com/graduan/API-PIX-Banco-Inter)
- Padrão BCB (Pix API): https://bacen.github.io/pix-api/
