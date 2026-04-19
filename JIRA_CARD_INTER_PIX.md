# Avaliação API Banco Inter (Pix + Cobrança + Banking) vs Efí Pay

**Tipo:** Task (Spike / Decisão Técnica)
**Projeto:** SCRUM
**Prioridade:** Alta (bloqueia decisão de gateway PIX)

---

## Contexto

Estamos avaliando gateways de PIX para o Pag Pag. Já criamos o card da **Efí Pay** (`SCRUM-[nº]`). Agora surgiu como alternativa a API do **Banco Inter**. Este card compara as duas soluções e recomenda qual seguir.

Docs Inter: https://developers.inter.co/references/token

---

## Comparativo

| Critério | Efí Pay | Banco Inter |
|---|---|---|
| **Tipo** | Gateway PIX (intermediador) | Banco digital PJ + API |
| **Auth** | OAuth2 + mTLS (.p12) | OAuth2 + mTLS (.p12) |
| **Onboarding do lojista** | Pag Pag pode operar como intermediadora | Lojista precisa ter conta Inter PJ |
| **Split nativo** | ✅ Sim, documentado | ⚠️ Não mencionado explicitamente |
| **APIs disponíveis** | PIX Cob, CobV, Cash-In, Cash-Out, Split, Webhooks | Banking, PIX (Cobrança, Pagamento, Automático), Cobrança/BolePix, CNAB |
| **Ambientes** | Produção + Homologação | Produção + Sandbox |
| **SDKs oficiais** | Múltiplas linguagens | Java e C# |
| **Liquidação** | Conta Efí (transferir para banco) | Conta Inter PJ (já é banco) |
| **Custo por transação** | Não documentado (negociar) | Não documentado (negociar) |
| **Setup** | Painel Efí → app → cert .p12 | Internet Banking PJ → nova integração → cert |
| **Foco da API** | Pagamentos (PIX-first) | Banking completo + PIX |

---

## Prós e contras

### Efí Pay (Gateway)

**Prós:**
- **Pag Pag pode operar como intermediadora** — lojista não precisa abrir conta em banco específico
- Split nativo para cobrar taxa da Pag Pag
- Documentação técnica mais detalhada e PIX-first
- SDKs em mais linguagens (incluindo Node.js, facilita o backend NestJS)

**Contras:**
- Liquidação passa pela Efí — precisa transferir pra conta final
- Custos de gateway somam ao processamento PIX

### Banco Inter (Banco + API)

**Prós:**
- **Lojista fica banco completo** (conta PJ + PIX + boleto + CNAB)
- Sem intermediador — liquidação direto na conta do lojista
- Banco consolidado (tradição, confiança)
- APIs de Banking completas (extrato, saldo, pagamentos)

**Contras:**
- **Obriga lojista a ter conta Inter PJ** (barreira de onboarding)
- Split não documentado — incerteza sobre cobrar taxa da Pag Pag
- SDKs limitados (Java e C#, sem Node.js/Dart)
- Foco misto (banco + API), doc menos PIX-first que Efí
- Processo de criação da integração vinculado ao Internet Banking

---

## Recomendação

### Pag Pag = app POS para lojistas heterogêneos (SMB, MEI)

O modelo ideal é **não forçar o lojista a ter conta em um banco específico**. Lojista instala o app, cadastra a chave PIX que ele já tem (em qualquer banco) e começa a receber.

**Recomendo Efí Pay** pelos motivos:

1. **Flexibilidade**: qualquer lojista pode entrar sem mudar de banco
2. **Split nativo**: essencial para cobrar a taxa da Pag Pag no ato
3. **Doc e SDKs PIX-first**: melhor para o backend NestJS
4. **Redução de fricção no onboarding**

O Inter faz sentido se no futuro a Pag Pag quiser oferecer **"Conta Pag Pag"** como produto adicional (whitelabel via BaaS), mas para o MVP de receber PIX, Efí é mais adequado.

---

## Alternativas futuras a considerar

- **Cappta** (citado na memória do projeto) — White Label Payments + Banking
- **Pagar.me** — volta para cartão, mas PIX também via Pagar.me
- **Stone / Cielo LIO** — maquininhas físicas integradas
- **MercadoPago** — API PIX + conta digital
- **Asaas / Iugu** — gateways brasileiros com split

---

## Próximos passos após decisão

1. Fechar decisão: Efí Pay ✅ ou Inter ou híbrido
2. Criar conta no provedor escolhido (CNPJ Pag Pag)
3. Gerar credenciais + certificado em homologação
4. Me passar as credenciais pra implementar (card já existe: `SCRUM-[Efí]`)

---

## Referências

- Inter: https://developers.inter.co/references/token
- Inter PIX: https://developers.inter.co/references/pix
- Efí Pay: https://dev.efipay.com.br/docs/api-pix/credenciais/
- Padrão BCB (ambos seguem): https://bacen.github.io/pix-api/
