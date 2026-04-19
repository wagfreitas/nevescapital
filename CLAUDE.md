# CLAUDE.md — Pag Pag (Neves Capital)

Arquivo de contexto para sessions do Claude Code. Leia primeiro antes de começar a trabalhar neste projeto.

---

## O que é

App Flutter de pagamentos (maquininha/POS) chamado **Pag Pag**, marca da Neves Capital. iOS + Android.

## Stack

- **Flutter** (Dart SDK >=3.5.0 <4.0.0), versão 1.0.0+4
- **Clean Architecture** + MVVM/ChangeNotifier (sem Riverpod/BLoC)
- **DI manual** via factories
- **Backend** NestJS próprio em `functions/` (porta 8080, deployed no Railway)
- **Firebase** (Auth REST, Firestore REST, Storage) — usa REST, não admin SDK
- **Twilio** para WhatsApp OTP
- **Pagar.me** removido (em avaliação de substituto)
- **PIX** não implementado (cards Efí/Inter em avaliação)

## Estrutura de pastas

```
lib/
  core/            # Config, theme, utils, errors, design system
  features/        # auth, payment, home, profile, investments
  shared/          # Components, services, helpers, models
functions/         # Backend NestJS
```

## Convenções

### Nomeação de telas
- Telas de cadastro: prefixo `registration_*` (ex: `registration_phone_screen.dart`)
- Telas de pagamento: prefixo `payment_step*` (ex: `payment_step1_screen.dart`)
- Classes sempre em PascalCase com sufixo `Screen`

### State Management
- Sempre `ChangeNotifier` + `ListenableBuilder`
- Nunca Riverpod, BLoC, ou Provider package
- Manual DI via factories em `*_usecase_factory.dart`

### Persistência de progresso
- **Fluxo de cadastro**: `LocalRegistrationStorage.saveLocal()` direto + merge via `copyWith`
- **NÃO usar** `RegistrationLifecycleObserver` ou `RegistrationNavigationHelper` para save durante navegação — eles falham silenciosamente quando Firestore não responde
- `_handleBack()` **sempre** salva antes de `Navigator.pop`
- `_handleNext()` **sempre** salva antes de navegar

### UI
- `GlassAppBar` padrão para telas de cadastro (transparente)
- `extendBodyBehindAppBar: true` quando usa GlassAppBar
- Body top padding: `MediaQuery.padding.top + kToolbarHeight + [16 se tem progress indicator] + 40`
- Títulos AppBar: **fontSize 20, bold, branco**
- Botão primário: **56px altura, borderRadius 12, AppTheme.primaryColor**
- Cores: usar `AppTheme.*` constants, nunca hex direto
- Espaçamento: `DesignSystem.spacing*` tokens (spacingMD=16, spacingLG=24)
- Textos sempre em pt-BR
- `PopScope(canPop: false, onPopInvokedWithResult: ...)` em todas as telas do cadastro pra interceptar swipe-back

### Logs
- Usar `AppLogger` (não print/debugPrint)
- Evitar logs verbose (emojis, MOCK:, etc.) — remover depois de debugar
- `AppLogger.error(...)` no catch, `AppLogger.debug(...)` pra rastreamento

### Commits
- Mensagens em português
- Prefixos: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`
- Não fazer commit sem pedido explícito

## Fluxos principais

### Cadastro (7 telas, branch `feature/cleanup-registration-flow`)
```
PhoneLoginScreen → WhatsAppOtpScreen → UnifiedCpfScreen
  → RegistrationPhoneScreen (se novo)
  → RegistrationOtpScreen
  → RegistrationEmailScreen
  → RegistrationPersonalDataScreen
  → RegistrationAddressScreen
  → RegistrationAdditionalInfoScreen
  → (finaliza no Firestore) → MainTabScreen
```

**Importante**: o `UnifiedCpfScreen._handleRegistration` carrega `LocalRegistrationStorage.getLocal()` para preservar dados quando o usuário volta até CPF e avança de novo.

### Login (OTP via WhatsApp)
```
PhoneLoginScreen → WhatsAppOtpScreen → (verificaOtp) → MainTabScreen
```

### Pagamento (em reestruturação)
```
payment_step1 (Dados da Loja) → step2 (Valor) → step3 (Dados Bancários)
  → step4 (Dados do Cartão) → step5 (Resumo)
```
Step3 e Step4 serão substituídos quando PIX entrar.

## Problemas conhecidos

- **iOS < 26** não suporta autofill de OTP via WhatsApp (só SMS). `AutofillHints.oneTimeCode` já adicionado — funcionará automaticamente em iOS 26+.
- **Entidade `RegistrationProgress`** ainda tem campos legacy: `selfiePath`, `documentFrontPath`, `documentBackPath`, `documentType` (não são usados no fluxo atual).
- **Token Jira atual** tem permissões limitadas — cards precisam ser colados manualmente no Jira.

## Arquivos de docs gerados

Na raiz (não commitados ainda):
- `JIRA_SUMMARY.md` — resumo do refactor do cadastro
- `JIRA_CARD_EFI_PIX.md` — card proposto para Efí Pay
- `JIRA_CARD_INTER_PIX.md` — comparação Inter vs Efí
- `CLAUDE.md` — este arquivo

## Backend (functions/)

### Estrutura
```
functions/src/
  app.module.ts
  main.ts
  auth/          # OTP, login, JWT, WhatsApp
  users/         # CRUD usuários
  firebase-rest/ # FirestoreRestService, AuthJwtService, StorageRestService
  common/        # ApiKeyGuard, shared utilities
  database/      # (módulo reservado)
  health.controller.ts
```

### Endpoints principais
- `POST /api/auth/send-otp-whatsapp` — envia OTP via Twilio
- `POST /api/auth/verify-otp-login` — valida OTP e retorna JWT
- `POST /api/users/check-cpf/:cpf` — verifica se CPF existe
- `POST /api/auth/check-user-status` — valida token e retorna status
- `POST /api/auth/reset-password` — envia email de redefinição

### Env vars
- `FIREBASE_PROJECT_ID`, `FIREBASE_WEB_API_KEY`
- `JWT_SECRET`, `JWT_EXPIRES_IN`
- `API_KEY` (proteção de endpoints)
- `TWILIO_*` (WhatsApp OTP)
- `FIREBASE_SERVICE_ACCOUNT` ou `FIREBASE_CI_TOKEN` ou `GOOGLE_CREDENTIALS_JSON` (pra Firestore)

## Como começar uma nova session

1. Ler este arquivo
2. Ler `~/.claude/projects/-Users-wagneralves-StudioProjects-neves-capital/memory/MEMORY.md` (histórico)
3. `git status` pra ver estado atual
4. `git log --oneline -10` pra ver o que foi commitado recentemente
5. Perguntar ao usuário o que ele quer fazer antes de mergulhar no código

## Quando em dúvida

- **Sempre** perguntar antes de criar novos arquivos fora dos padrões
- **Nunca** mudar o layout visual sem pedido explícito
- **Nunca** quebrar a persistência local do cadastro (`LocalRegistrationStorage`)
- **Nunca** reintroduzir `RegistrationLifecycleObserver` nas telas de cadastro
- **Sempre** rodar `flutter analyze --no-pub` antes de dar como pronto
- **Sempre** rodar `npx tsc --noEmit` no `functions/` antes de considerar backend OK
