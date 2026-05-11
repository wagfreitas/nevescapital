# [PagPag] Ativar envio de OTP via SMS (Twilio)

**Tipo:** Task
**Projeto:** PagPag (`appagpag.atlassian.net`)
**Prioridade:** Média
**Estimativa:** 1 dia (backend) + 0,5 dia (Flutter) + 0,5 dia (QA com número real)

---

## Contexto

Hoje o OTP de login/cadastro é enviado **exclusivamente via WhatsApp** (`POST /api/auth/send-otp-whatsapp` → `WhatsAppService` em `functions/src/auth/services/whatsapp.service.ts`).

Isso falha em três cenários reais:

1. Usuário **não tem WhatsApp instalado** (raro, mas existe).
2. WhatsApp do usuário está **desatualizado / com problema de notificação**.
3. iOS **< 26** não suporta autofill de OTP via WhatsApp — só por SMS (já documentado no `CLAUDE.md`).

Solução: habilitar **SMS como canal alternativo** usando a mesma conta Twilio que já enviamos WhatsApp.

---

## Objetivo

Permitir que o usuário receba o código OTP por **SMS** quando o WhatsApp não chegar, mantendo a infra atual (mesma conta Twilio, mesmo `simple-otp.service.ts` que já gera e valida o código no Firestore).

---

## Custo (Twilio — Maio/2026)

| Item | Valor |
|---|---|
| **SMS A2P pra Brasil** | **~US$ 0,075 / mensagem** |
| **Sender ID alfanumérico** ("PAGPAG") | Grátis no Brasil (sem aluguel de número) |
| **Carrier fees BR** | Inclusos no preço acima (Twilio repassa) |
| **Custo estimado em BRL** (USD/BRL ~5,00) | **~R$ 0,38 por SMS** |

**Comparação com alternativas:**
- WhatsApp template (atual): ~US$ 0,038/mensagem
- Twilio Verify (alternativa premium): US$ 0,05/verificação bem-sucedida + US$ 0,075 SMS = ~US$ 0,125 ≈ R$ 0,63

**Decisão:** usar **Programmable SMS direto** (não Verify), porque o backend já gera/valida OTP via `SimpleOtpService` (Firestore) e Verify duplicaria essa responsabilidade pagando 67% a mais.

**Projeção de custo mensal:**
- 1.000 SMS/mês = **~R$ 380/mês**
- 10.000 SMS/mês = **~R$ 3.800/mês**
- Premissa: SMS só dispara quando WhatsApp falhar OU usuário pedir explicitamente → volume baixo.

---

## Decisões pendentes (confirmar antes de codar)

### 1) UX — SMS é fallback automático ou escolha do usuário?

**Opção A — Fallback automático** (Pag Pag tenta WhatsApp primeiro, se Twilio retornar erro de entrega em N segundos, dispara SMS).
- Prós: usuário não pensa.
- Contras: dobra custo em alguns casos; difícil detectar "WhatsApp não entregue" sem webhook de status.

**Opção B — Botão "Não recebi" → manda SMS** (recomendado).
- Prós: custo controlado (só dispara quando usuário pede); UI explícita.
- Contras: 1 clique a mais.

### 2) Endpoint — reusar ou criar novo?

**Opção A — Endpoint novo** `POST /api/auth/send-otp-sms` (recomendado).
- Prós: gêmeo do `send-otp-whatsapp`, telemetria limpa por canal, retrocompatível.
- Contras: nenhuma.

**Opção B — Endpoint unificado** `POST /api/auth/send-otp` com body `{ phone, channel: 'whatsapp' | 'sms' }`.
- Prós: API mais "limpa" no longo prazo.
- Contras: refactor maior, quebra o app atual em produção, mistura responsabilidades.

---

## Escopo técnico

### Backend (`functions/src/auth/`)

**1. Novo serviço `SmsService`** (`services/sms.service.ts`)
- Gêmeo do `whatsapp.service.ts`
- Usa o mesmo `Twilio()` client (mesmas envs `TWILIO_ACCOUNT_SID`/`TWILIO_AUTH_TOKEN`)
- Nova env: `TWILIO_SMS_FROM` = `PAGPAG` (Sender ID alfanumérico)
- Método principal:
  ```ts
  async sendOtpMessage(phone: string, code: string): Promise<boolean>
  ```
  Body do SMS sugerido:
  ```
  Pag Pag: seu codigo de verificacao e {code}. Nao compartilhe.
  ```
  (sem acentos pra evitar problemas de encoding GSM-7 / fallback pra UCS-2 que aumentaria o custo).

**2. Novo endpoint** `POST /api/auth/send-otp-sms`
- Mesmo throttle (3 req/min)
- Mesma `ApiKeyGuard`
- Reusa `SimpleOtpService.sendOtp(phone)` pra gerar/salvar OTP no Firestore
- Chama `SmsService.sendOtpMessage` (fire-and-forget igual WhatsApp)
- Verify continua sendo o `/api/auth/verify-otp-login` existente (não muda nada)

**3. `auth.module.ts`** — registrar `SmsService` no providers

**4. Variáveis de ambiente novas**
- `TWILIO_SMS_FROM=PAGPAG` (Sender ID — registrar antes no console Twilio)

### Flutter (`lib/features/auth/`)

**1. `auth_api_service.dart`** — novo método `sendOtpSms(phone)`
**2. `whatsapp_otp_screen.dart`** — adicionar botão "Não recebi? Enviar por SMS"
  - Aparece **após 30s** sem o usuário digitar (timer)
  - Ou sempre visível, abaixo do "Reenviar código"
  - Ao clicar: chama novo endpoint SMS, mostra snackbar "Código enviado por SMS"
**3. Reset password OTP** (`reset_password_otp_screen.dart`) — replicar o mesmo botão se aplicável

### Configuração Twilio (manual no console)

1. Console Twilio → Messaging → Sender IDs → **Register Alphanumeric Sender ID** = `PAGPAG`
   - Brasil **não exige** documentação extra pra Sender ID alfanumérico (ao contrário da Índia, Arábia etc.)
   - Tempo de aprovação: imediato a 24h
2. **Validar entrega real** mandando SMS pra 2-3 operadoras BR (Vivo, Claro, TIM)
   - Operadoras BR têm filtragem agressiva de Sender ID desconhecido — pode cair em spam

---

## Critérios de aceite

- [ ] `SmsService` criado em `functions/src/auth/services/sms.service.ts`
- [ ] Endpoint `POST /api/auth/send-otp-sms` funcionando com throttle e ApiKeyGuard
- [ ] `TWILIO_SMS_FROM=PAGPAG` registrado no `.env.local` (com `op://` reference) e nas envs do Railway
- [ ] Sender ID `PAGPAG` aprovado no console Twilio
- [ ] Botão "Enviar por SMS" na `whatsapp_otp_screen.dart`
- [ ] SMS de teste recebido em pelo menos 1 número Vivo e 1 Claro/TIM
- [ ] `flutter analyze --no-pub` limpo
- [ ] `npx tsc --noEmit` no `functions/` limpo
- [ ] Log de custo: telemetria gravando quantos SMS foram enviados (pra acompanhar custo mensal)

---

## Fora de escopo

- Substituir WhatsApp por SMS (SMS é **alternativa**, não substituto)
- Mudar fluxo de cadastro
- Twilio Verify (decisão: usar Programmable SMS direto)
- Internacionalização (só Brasil por enquanto — qualquer telefone com DDI ≠ 55 cai em erro de validação no `formatPhone`)

---

## Riscos

| Risco | Mitigação |
|---|---|
| Operadoras BR filtrarem Sender ID `PAGPAG` como spam | Testar com 3 operadoras antes de subir; se filtrar, registrar long code BR ($1/mês) |
| Custo subir descontrolado se virar fallback automático | Por isso recomendado opção B (escolha explícita do usuário) |
| iOS < 26 não autopreencher (mesmo problema do WhatsApp) | SMS **deveria** funcionar com `AutofillHints.oneTimeCode` desde iOS 12 — validar em device real iOS 17/18 |
| Twilio bloquear envio por content moderation | Texto sem links, sem palavras "spammy" |

---

## Links / Referências

- [Twilio SMS pricing Brazil](https://www.twilio.com/en-us/sms/pricing/br)
- [Twilio Brazil SMS Guidelines](https://www.twilio.com/en-us/guidelines/br/sms)
- [Alphanumeric Sender ID docs](https://www.twilio.com/docs/glossary/what-alphanumeric-sender-id)
- Arquivo atual: `functions/src/auth/services/whatsapp.service.ts`
- Endpoint atual: `functions/src/auth/auth.controller.ts:91-133`
