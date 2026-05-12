# HANDOFF.md — Pag Pag (Neves Capital)

Documento de passagem de bastão para novos desenvolvedores. Última atualização: Maio 2026.

---

## 1. Visão Geral do Projeto

### O que é

**Pag Pag** é um aplicativo mobile de pagamentos (maquininha/POS digital) da marca **Neves Capital**. Permite que comerciantes recebam pagamentos via cartão de crédito e PIX diretamente pelo celular.

### Público-alvo

Microempreendedores, autônomos e pequenos comerciantes que precisam de uma solução de pagamento sem hardware dedicado.

### Status Atual

| Funcionalidade | Status |
|---|---|
| Cadastro de usuários (7 telas) | ✅ Funcional |
| Login via OTP WhatsApp/SMS | ✅ Funcional |
| Autenticação biométrica (Face ID/Touch ID) | ✅ Funcional |
| Dashboard e perfil | ✅ Funcional |
| Fluxo de pagamento (5 steps) | ✅ Funcional (cartão) |
| Integração PIX via Efí Pay | ⚠️ Em integração (homologação OK, produção pendente) |
| Gestão de chaves PIX | ✅ Funcional |
| Histórico de vendas | ✅ Funcional |
| Backend NestJS (Railway) | ✅ Funcional |
| Webhooks PIX | ⚠️ Parcial (receiver implementado, reconciliação pendente) |
| Testes automatizados | ❌ Não implementados |
| CI/CD | ❌ Não implementado |

---

## 2. Stack Tecnológica

### Mobile (Flutter)

- **Framework**: Flutter (Dart SDK `>=3.5.0 <4.0.0`)
- **Versão do app**: `1.0.0+4`
- **Plataformas**: iOS + Android
- **State Management**: `ChangeNotifier` + `ListenableBuilder` (sem BLoC, sem Riverpod)
- **DI**: Manual via factory classes (`*_usecase_factory.dart`)
- **Armazenamento local**: `SharedPreferences` (progresso de cadastro), `FlutterSecureStorage` (tokens)
- **HTTP**: pacote `http` (Dart)
- **Localização**: pt-BR (via `flutter_localizations`)

### Backend (NestJS)

- **Framework**: NestJS `^10.3.0`
- **Runtime**: Node.js `>=20.0.0`
- **Linguagem**: TypeScript `^5.3.3`
- **Deploy**: [Railway](https://railway.app) (porta 8080)
- **URL de produção**: `https://nevescapital-production.up.railway.app`
- **Documentação API**: Swagger em `/api/docs`

### Firebase

- **Projeto**: `pagpagapp`
- **Serviços utilizados**:
  - **Firestore** — banco de dados principal (collections: `users`, `registration_progress`, `otps`, `pix_webhooks`)
  - **Storage** — upload de documentos KYC (selfie, documentos)
  - **Auth** — usado parcialmente (a autenticação principal é via OTP próprio + JWT)
- **Importante**: O backend usa tanto Firebase Admin SDK (`firebase-admin`) para Firestore/Storage/Auth quanto serviços REST customizados (`FirestoreRestService`, `AuthJwtService`, `StorageRestService`). O app Flutter usa os SDKs nativos do Firebase (`cloud_firestore`, `firebase_auth`, `firebase_storage`).

### Integrações Externas

| Serviço | Finalidade | Status |
|---|---|---|
| **Twilio** | Envio de OTP via WhatsApp e SMS | ✅ Ativo |
| **Efí Pay** | PIX-out (enviar pagamentos PIX) | ⚠️ Homologação OK |
| **ViaCEP** | Busca de endereço por CEP | ✅ Ativo |

---

## 3. Arquitetura do App (Flutter)

### Padrão Arquitetural

Clean Architecture + MVVM com `ChangeNotifier`.

```
lib/
├── main.dart                         # Entry point
├── firebase_options.dart             # Configuração Firebase gerada
├── config/
│   └── firebase_config_example.dart  # Exemplo de config Firebase
├── core/                            # Infraestrutura transversal
│   ├── config/
│   │   ├── app_config.dart           # URL base da API
│   │   ├── env_service.dart          # Carrega .env (flutter_dotenv)
│   │   └── feature_flags.dart        # Feature flags
│   ├── constants/
│   │   └── app_constants.dart        # Constantes globais
│   ├── design_system/
│   │   └── design_system.dart        # Tokens de design (spacing, radius, botões)
│   ├── errors/
│   │   └── failures.dart             # Classes de erro (Result pattern)
│   ├── network/
│   │   └── network_info.dart         # Verificação de conectividade
│   ├── theme/
│   │   ├── app_theme.dart            # Cores, ThemeData (tema verde escuro)
│   │   └── theme_controller.dart     # Controller de tema (dark/light)
│   └── utils/
│       ├── app_logger.dart           # Logger configurável (substitui print)
│       ├── card_validator.dart       # Validação de cartão de crédito
│       └── result.dart               # Result<T> pattern
├── features/                         # Features isoladas (Clean Architecture)
│   ├── auth/                         # Autenticação e cadastro
│   ├── home/                         # Dashboard e tela principal
│   ├── payment/                      # Fluxo de pagamento (5 steps)
│   ├── profile/                      # Perfil e configurações do usuário
│   └── investments/                  # Investimentos (reservado, não implementado)
└── shared/                           # Código compartilhado entre features
    ├── components/                   # Widgets reutilizáveis (GlassAppBar, CustomButton, etc.)
    ├── data/                         # Dados estáticos (lista de bancos, nomes de países)
    ├── helpers/                      # Formatters, validators (CPF, CEP, email, telefone)
    ├── models/                       # Models compartilhados (Balance, Transaction)
    ├── screens/                      # Telas compartilhadas (Splash, Termos, Privacidade)
    ├── services/                     # Services compartilhados
    └── widgets/                      # Widgets adicionais
```

### Feature: Auth (`lib/features/auth/`)

Responsável por login, cadastro e autenticação.

```
auth/
├── data/
│   ├── datasources/
│   │   ├── auth_local_datasource.dart              # Interface local
│   │   ├── auth_remote_datasource.dart             # Interface remota
│   │   ├── firebase_auth_remote_datasource.dart    # Implementação Firebase
│   │   └── shared_preferences_auth_local_datasource.dart  # Implementação local
│   ├── models/
│   │   └── user_model.dart                         # Modelo de dados do usuário
│   ├── repositories/
│   │   └── auth_repository_impl.dart               # Implementação do repositório
│   └── services/
│       ├── auth_api_service.dart                   # Chamadas HTTP ao backend
│       ├── local_registration_storage.dart         # Persistência local do cadastro
│       └── registration_service.dart               # Salva progresso no Firestore
├── domain/
│   ├── entities/
│   │   ├── registration_progress.dart              # Entidade de progresso do cadastro
│   │   └── user.dart                               # Entidade de usuário
│   ├── repositories/
│   │   └── auth_repository.dart                    # Interface do repositório
│   └── usecases/
│       ├── get_current_user_usecase.dart
│       ├── get_user_by_cpf_usecase.dart
│       ├── login_usecase.dart
│       ├── login_with_otp_usecase.dart
│       ├── logout_usecase.dart
│       ├── register_usecase.dart
│       └── verify_otp_usecase.dart
└── presentation/
    ├── controllers/
    │   ├── auth_controller.dart                    # Controller principal de auth
    │   └── registration_lifecycle_observer.dart     # NÃO USAR (ver convenções)
    ├── factories/
    │   └── auth_usecase_factory.dart               # Factory de DI
    ├── helpers/
    │   ├── registration_navigation_helper.dart     # NÃO USAR para save
    │   ├── registration_navigator.dart             # Navegação do cadastro
    │   └── registration_progress_indicator.dart    # Indicador visual de progresso
    └── screens/
        ├── login_otp/
        │   ├── biometric_setup_screen.dart         # Config biometria
        │   └── login_step3_otp_screen.dart         # Verificação OTP
        ├── new_registration/
        │   ├── registration_additional_info_screen.dart  # Step 6: Info adicional
        │   ├── registration_address_screen.dart          # Step 5: Endereço
        │   ├── registration_email_screen.dart            # Step 3: Email
        │   ├── registration_otp_screen.dart              # Step 2: OTP
        │   ├── registration_personal_data_screen.dart    # Step 4: Dados pessoais
        │   ├── registration_phone_screen.dart            # Step 1: Telefone
        │   ├── step7_selfie_screen.dart                  # Step 7: Selfie (legacy)
        │   └── step8_document_screen.dart                # Step 8: Documento (legacy)
        ├── biometric_fallback_screen.dart
        ├── change_password_screen.dart
        ├── cpf_check_screen.dart
        ├── onboarding_screen.dart                  # Tela inicial (logo + botão login)
        ├── personal_data_screen.dart
        ├── phone_login_screen.dart                 # Entrada de telefone
        ├── reset_password_otp_screen.dart
        ├── unified_cpf_screen.dart                 # CPF → decide se login ou cadastro
        └── whatsapp_otp_screen.dart                # Verificação OTP WhatsApp
```

### Feature: Payment (`lib/features/payment/`)

Fluxo de pagamento em 5 etapas.

| Tela | Arquivo | Propósito |
|---|---|---|
| Step 1 | `payment_step1_screen.dart` | Nome do estabelecimento e ramo de atuação |
| Step 2 | `payment_step2_screen.dart` | Valor da venda |
| Step 3 | `payment_step3_screen.dart` | Chave PIX do recebedor |
| Step 4 | `payment_step4_screen.dart` | Dados do cartão de crédito |
| Step 5 | `payment_step5_screen.dart` | Resumo e confirmação (dispara PIX via Efí) |
| Resultado | `payment_result_screen.dart` | Resultado do pagamento |
| Conclusão | `sale_completion_screen.dart` | Venda concluída com sucesso |

### Feature: Home (`lib/features/home/`)

| Tela | Propósito |
|---|---|
| `main_tab_screen.dart` | Container com tab bar (Vendas / Conta) |
| `dashboard_screen.dart` | Dashboard principal — saldo, últimas vendas |
| `home_screen.dart` | Tela home (obsoleta, substituída por DashboardScreen) |
| `sales_history_screen.dart` | Histórico de vendas completo |

### Feature: Profile (`lib/features/profile/`)

| Tela | Propósito |
|---|---|
| `profile_screen.dart` | Tela de perfil/conta do usuário |
| `edit_personal_data_screen.dart` | Edição de dados pessoais |
| `edit_store_data_screen.dart` | Edição de dados da loja |
| `edit_pix_keys_screen.dart` | Gerenciamento de chaves PIX |
| `bank_account_screen.dart` | Dados bancários |

### Services Compartilhados (`lib/shared/services/`)

| Service | Propósito |
|---|---|
| `auth_service.dart` | Gerencia estado de autenticação |
| `biometric_service.dart` | Face ID / Touch ID / senha do dispositivo |
| `encryption_service.dart` | Criptografia AES + hash SHA-256 para dados sensíveis |
| `firestore_service.dart` | CRUD de usuários, vendas, dados bancários no Firestore |
| `firebase_storage_service.dart` | Upload/download de documentos KYC |
| `secure_storage_service.dart` | Armazenamento seguro (flutter_secure_storage) |
| `efi_pix_api_service.dart` | Client HTTP para endpoints PIX do backend |
| `cep_service.dart` | Consulta CEP via ViaCEP |
| `balance_service.dart` | Consulta de saldo |
| `user_cache_service.dart` | Cache local de dados do usuário |
| `optimized_http_service.dart` | HTTP client otimizado |
| `secure_http_client.dart` | HTTP client com headers de segurança |
| `keyboard_accessory_service.dart` | Botão "OK" no teclado numérico iOS (nativo Swift) |

---

## 4. Arquitetura do Backend (NestJS)

### Estrutura de Módulos

```
functions/src/
├── main.ts                    # Bootstrap NestJS (porta 8080, Swagger, CORS, Helmet)
├── app.module.ts              # Módulo raiz
├── health.controller.ts       # GET /health + keep-alive Firestore (30 min)
├── auth/                      # Módulo de autenticação
│   ├── auth.module.ts
│   ├── auth.controller.ts     # Endpoints de auth (OTP, login, status)
│   ├── whatsapp-webhook.controller.ts  # Webhook Twilio (resposta automática)
│   ├── email-sender.service.ts        # Envio de emails
│   ├── email-template.service.ts      # Templates de email
│   ├── dto/
│   │   ├── otp.dto.ts
│   │   ├── registration-otp.dto.ts
│   │   ├── reset-password.dto.ts
│   │   ├── send-phone-otp.dto.ts
│   │   └── verify-otp.dto.ts
│   └── services/
│       ├── simple-otp.service.ts      # Geração e verificação de OTP (Firestore)
│       ├── whatsapp.service.ts        # Envio de OTP via Twilio WhatsApp
│       ├── sms.service.ts            # Envio de OTP via Twilio SMS
│       └── verify.service.ts         # OTP via Twilio Verify API v2 (SMS + WhatsApp)
├── users/                     # Módulo de usuários
│   ├── users.module.ts
│   ├── users.controller.ts   # CRUD de usuários, chaves PIX, dados da loja
│   ├── users.service.ts      # Lógica de negócios de usuários
│   ├── dto/
│   │   ├── create-user.dto.ts
│   │   ├── update-user.dto.ts
│   │   ├── verify-password.dto.ts
│   │   ├── store-data.dto.ts
│   │   └── pix-key.dto.ts
│   └── services/
│       └── pix-validation.service.ts  # Validação de chaves PIX
├── efi/                       # Módulo Efí Pay (PIX)
│   ├── efi.module.ts
│   ├── efi-config.service.ts  # Configuração Efí (ambiente, credenciais, certificado)
│   ├── efi-auth.service.ts    # OAuth2 com mTLS para obter access_token
│   ├── efi-pix.service.ts     # PIX-out, saldo, webhook
│   ├── efi-pix.controller.ts  # Endpoints de produção: POST /api/pix/send, etc.
│   ├── efi-test.controller.ts # Endpoints internos de teste: /api/_internal/efi/test/*
│   ├── efi-webhook.controller.ts  # Receiver de webhooks PIX (POST /api/webhooks/efi/pix)
│   └── dto/
│       └── send-pix.dto.ts    # DTO de envio PIX (chave, copia-e-cola, dados bancários)
├── firebase-rest/             # Módulo Firebase REST (Global)
│   ├── firebase-rest.module.ts
│   ├── firestore-rest.service.ts    # CRUD Firestore via REST API
│   ├── firestore-rest.utils.ts      # Utilitários Firestore
│   ├── auth-jwt.service.ts          # Geração e verificação JWT
│   └── storage-rest.service.ts      # Firebase Storage via REST
├── common/
│   └── guards/
│       └── api-key.guard.ts         # Guard: valida header x-api-key
└── database/
    └── migrations/                  # Reservado (não utilizado)
```

### Endpoints Principais

#### Auth (`/api/auth`)

Todos protegidos por `ApiKeyGuard` (header `x-api-key`).

| Método | Endpoint | Rate Limit | Descrição |
|---|---|---|---|
| `POST` | `/api/auth/send-otp-whatsapp` | 3/min | Gera OTP 4 dígitos e envia via WhatsApp (Twilio) |
| `POST` | `/api/auth/send-otp-sms` | 3/min | Gera OTP e envia via SMS (canal alternativo) |
| `POST` | `/api/auth/send-otp-verify` | 3/min | Envia OTP via Twilio Verify Service (canais: sms, whatsapp) |
| `POST` | `/api/auth/check-otp-verify` | 10/min | Verifica código OTP via Twilio Verify Service |
| `POST` | `/api/auth/send-otp` | 3/min | Gera OTP (retorna código no response — apenas testes) |
| `POST` | `/api/auth/verify-otp` | 10/min | Verifica OTP |
| `POST` | `/api/auth/verify-otp-login` | 10/min | Verifica OTP + busca usuário + retorna JWT |
| `POST` | `/api/auth/check-user-status` | 10/min | Valida JWT, busca usuário, retorna status (LOGGED_IN/REGISTER) |
| `POST` | `/api/auth/reset-password` | 5/min | Envia email de redefinição de senha |

#### Users (`/api/users`)

| Método | Endpoint | Descrição |
|---|---|---|
| `POST` | `/api/users/register` | Registrar novo usuário |
| `GET` | `/api/users/cpf/:cpf` | Buscar usuário por CPF (retorna dados) |
| `GET` | `/api/users/check-cpf/:cpf` | Verificar se CPF existe (sem PII) |
| `GET` | `/api/users/email/:email` | Buscar usuário por email |
| `POST` | `/api/users/verify-password` | Verificar senha do usuário |
| `PUT` | `/api/users/:id` | Atualizar dados do usuário |
| `DELETE` | `/api/users/:id` | Soft delete do usuário |
| `DELETE` | `/api/users/:id/complete` | Hard delete completo (Firestore + Storage + Auth) |
| `POST` | `/api/users/sync-firebase-email` | Sincronizar email Firebase ↔ Firestore |
| `GET` | `/api/users/:id/store` | Buscar dados da loja |
| `PUT` | `/api/users/:id/store` | Criar/atualizar dados da loja |
| `GET` | `/api/users/:id/pix-keys` | Listar chaves PIX |
| `POST` | `/api/users/:id/pix-keys` | Adicionar chave PIX |
| `DELETE` | `/api/users/:id/pix-keys/:keyId` | Remover chave PIX |

#### PIX - Efí (`/api/pix`)

| Método | Endpoint | Descrição |
|---|---|---|
| `POST` | `/api/pix/send` | Enviar PIX (chave, copia-e-cola ou dados bancários) |
| `GET` | `/api/pix/status/:idEnvio` | Consultar status de PIX enviado |
| `GET` | `/api/pix/balance` | Consultar saldo da conta Efí |

#### PIX - Testes Internos (`/api/_internal/efi/test`)

| Método | Endpoint | Descrição |
|---|---|---|
| `GET` | `/api/_internal/efi/test/auth` | Smoke test: verifica config e obtém token |
| `GET` | `/api/_internal/efi/test/balance` | Consulta saldo |
| `POST` | `/api/_internal/efi/test/pix` | Dispara PIX de teste |
| `GET` | `/api/_internal/efi/test/pix/:idEnvio` | Consulta status de PIX |
| `GET` | `/api/_internal/efi/test/webhook/:chave` | Consulta webhook registrado |
| `POST` | `/api/_internal/efi/test/webhook` | Registra webhook na chave PIX |

#### Webhooks (`/api/webhooks/efi`)

| Método | Endpoint | Proteção | Descrição |
|---|---|---|---|
| `GET` | `/api/webhooks/efi` | Nenhuma | Health check (Efí testa antes de registrar) |
| `POST` | `/api/webhooks/efi/pix` | Nenhuma | Receiver de confirmação PIX da Efí |

#### Outros

| Método | Endpoint | Descrição |
|---|---|---|
| `GET` | `/health` | Health check do servidor |
| `GET` | `/api/docs` | Documentação Swagger |

### Autenticação do Backend

- **API Key**: Todos os endpoints (exceto webhooks e health) exigem header `x-api-key` com valor da env var `API_KEY`.
- **JWT**: Gerado pelo backend via `AuthJwtService.signToken()`. Contém `sub` (userId) e `phone`. Verificado via `AuthJwtService.verifyToken()`.
- **Rate Limiting**: `@nestjs/throttler` — 100 requests/min global, limites específicos por endpoint.

### Integração Efí Pay (PIX)

A integração com a Efí funciona via OAuth2 com mTLS (certificado `.p12`):

1. **`EfiConfigService`**: Carrega configuração (ambiente, credenciais, certificado)
2. **`EfiAuthService`**: Obtém `access_token` via `POST /oauth/token` com certificado mTLS. Cache com renovação automática.
3. **`EfiPixService`**: Operações PIX:
   - `sendPix()`: PUT `/v3/gn/pix/{idEnvio}` — envio com idempotência
   - `getPixStatus()`: GET `/v3/gn/pix/enviados/{idEnvio}`
   - `registerWebhook()`: PUT `/v2/webhook/{chave}` — pré-requisito para PIX-out
   - `getBalance()`: GET `/v2/gn/saldo`
4. **`EfiWebhookController`**: Recebe confirmações PIX da Efí via POST, salva em `pix_webhooks/{e2eId}` no Firestore

**Modalidades de PIX suportadas**:
- Por **chave PIX** (CPF, CNPJ, email, telefone, aleatória)
- Por **copia-e-cola** (BR Code / QR Code)
- Por **dados bancários** (agência, conta, CPF/CNPJ)

---

## 5. Fluxos Principais

### 5.1 Fluxo de Cadastro

```
SplashScreen
  └─→ OnboardingScreen (logo + "Entrar com telefone")
       └─→ PhoneLoginScreen (insere número com código do país)
            └─→ WhatsAppOtpScreen (recebe OTP 4 dígitos via WhatsApp/SMS)
                 └─→ UnifiedCpfScreen (insere CPF → backend decide: login ou cadastro)
                      │
                      ├─→ [CPF existe + cadastro completo] → MainTabScreen (login direto)
                      │
                      └─→ [CPF não existe ou cadastro incompleto] → Fluxo de cadastro:
                           │
                           ├─→ RegistrationPhoneScreen (confirma telefone)
                           ├─→ RegistrationOtpScreen (verifica OTP do cadastro)
                           ├─→ RegistrationEmailScreen (insere email)
                           ├─→ RegistrationPersonalDataScreen (nome, nascimento, mãe)
                           ├─→ RegistrationAddressScreen (CEP → busca automática)
                           ├─→ RegistrationAdditionalInfoScreen (PEP, ocupação, renda, documento)
                           │
                           └─→ [Salva no Firestore via backend] → MainTabScreen
```

**Persistência de progresso**:
- Cada tela salva o progresso localmente via `LocalRegistrationStorage.saveLocal()` antes de navegar (tanto `_handleNext()` quanto `_handleBack()`)
- Usa `SharedPreferences` com chave `registration_progress_local`
- Ao reabrir o app com cadastro incompleto, o `SplashScreen` oferece retomar de onde parou
- A entidade `RegistrationProgress` usa `copyWith()` para merge dos dados

**IMPORTANTE**: Nunca usar `RegistrationLifecycleObserver` ou `RegistrationNavigationHelper` para salvar durante navegação — eles falham silenciosamente quando Firestore não responde.

### 5.2 Fluxo de Login (OTP)

```
PhoneLoginScreen (insere telefone)
  └─→ Backend: POST /api/auth/send-otp-whatsapp
       └─→ WhatsAppOtpScreen (insere código 4 dígitos)
            └─→ Backend: POST /api/auth/verify-otp-login
                 │
                 ├─→ status: LOGGED_IN → Salva JWT + flag is_logged_in_otp → MainTabScreen
                 │
                 └─→ status: REGISTER → Redireciona para fluxo de cadastro
```

**Reentrada no app**:
```
SplashScreen
  └─→ Verifica SharedPreferences "is_logged_in_otp"
       ├─→ true → Solicita biometria (Face ID/Touch ID/senha)
       │         ├─→ Sucesso → MainTabScreen
       │         └─→ Falha → Logout → OnboardingScreen
       └─→ false → Verifica cadastro abandonado → OnboardingScreen
```

### 5.3 Fluxo de Pagamento

```
DashboardScreen (botão "Nova Venda")
  └─→ PaymentStep1Screen (nome loja + ramo — pula se já tem dados salvos)
       └─→ PaymentStep2Screen (valor da venda em R$)
            └─→ PaymentStep3Screen (chave PIX do recebedor)
                 └─→ PaymentStep4Screen (dados do cartão de crédito)
                      └─→ PaymentStep5Screen (resumo da operação)
                           │
                           ├─→ Dispara PIX via Efí (POST /api/pix/send)
                           ├─→ Salva venda no Firestore (subcollection users/{id}/sales)
                           │
                           └─→ SaleCompletionScreen (sucesso) ou PaymentResultScreen (erro)
```

**Cálculo de taxa**: 3% sobre o valor bruto. Valor líquido = 97% do valor da venda.

### 5.4 Dados Persistidos no Firestore

**Collection `users`** (dados criptografados):
- `cpfEncrypted`, `cpfHash`, `emailEncrypted`, `emailHash`, `phoneEncrypted`, `phoneHash`
- `displayName`, `birthDate`, `motherName`, `isPep`, `occupation`, `incomeRange`
- `address` (objeto: `street`, `city`, `state`, `cep`, `neighborhood`, `number`, `complement`)
- `store` (objeto: `storeName`, `businessType`)
- `bankAccount` (objeto: `bankCode`, `bankName`, `branch`, `account`)
- `pixKeys` (array de chaves PIX)
- `kycStatus`, `createdAt`, `updatedAt`

**Subcollection `users/{id}/sales`**:
- `valorCentavos`, `valorLiquidoCentavos`, `nomeEstabelecimento`, `ramoAtuacao`
- `cardBrand`, `cardLastFour`, `cardNumber` (mascarado)
- `pixIdEnvio`, `pixE2eId`, `pixStatus`
- `status`, `createdAt`

---

## 6. Configuração do Ambiente de Desenvolvimento

### Pré-requisitos

- **Flutter SDK**: `>=3.5.0 <4.0.0`
- **Dart SDK**: Incluído no Flutter
- **Node.js**: `>=20.0.0`
- **npm** ou **yarn**
- **Xcode** (para iOS) com CocoaPods
- **Android Studio** (para Android)
- **Firebase CLI**: `npm install -g firebase-tools`

### Como rodar o app Flutter

```bash
# 1. Instalar dependências
flutter pub get

# 2. Criar arquivo .env na raiz do projeto com:
#    API_BASE_URL=http://localhost:8080  (ou URL do Railway)
#    API_KEY=<mesma API_KEY do backend>

# 3. Rodar no emulador/dispositivo
flutter run

# 4. Verificar erros de lint
flutter analyze --no-pub
```

### Como rodar o backend local

```bash
cd functions/

# 1. Instalar dependências
npm install

# 2. Criar .env baseado no .env.example
cp .env.example .env
# Preencher com valores reais (ver seção de variáveis abaixo)

# 3. Rodar em modo desenvolvimento
npm run start:dev

# 4. Verificar TypeScript
npx tsc --noEmit

# Backend roda em http://localhost:8080
# Swagger em http://localhost:8080/api/docs
```

### Variáveis de Ambiente — Backend (`functions/.env`)

```env
# Servidor
PORT=8080
NODE_ENV=development

# Firebase
GOOGLE_CLOUD_PROJECT=<firebase-project-id>
FIREBASE_SERVICE_ACCOUNT=<json-da-service-account>
# OU
FIREBASE_CI_TOKEN=<token-do-firebase-cli>

# Segurança
API_KEY=<chave-api-compartilhada-com-o-app>
ALLOWED_ORIGINS=http://localhost:*,http://127.0.0.1:*

# Twilio (WhatsApp + SMS + Verify)
TWILIO_ACCOUNT_SID=<sid-da-conta>
TWILIO_AUTH_TOKEN=<auth-token>
TWILIO_WHATSAPP_FROM=<numero-whatsapp>
TWILIO_OTP_CONTENT_SID=<content-sid-do-template>
TWILIO_MESSAGING_SERVICE_SID=<messaging-service-sid>
TWILIO_VERIFY_SERVICE_SID=<verify-service-sid>

# Efí Pay (PIX)
EFI_AMBIENTE=homologacao  # ou 'producao'
EFI_CLIENT_ID=<client-id-efi>
EFI_CLIENT_SECRET=<client-secret-efi>
EFI_CERT_BASE64=<certificado-p12-em-base64>
# OU
EFI_CERT_PATH=./certs/homologacao.p12
EFI_CERT_PASSPHRASE=<passphrase-se-houver>
EFI_PAGADOR_CHAVE=<chave-pix-da-conta-efi>
```

### Variáveis de Ambiente — App Flutter (`.env` na raiz)

```env
API_BASE_URL=https://nevescapital-production.up.railway.app
API_KEY=<mesma-chave-do-backend>
```

### Configuração Firebase

O projeto Firebase é `pagpagapp`. Os arquivos de configuração já estão no projeto:
- **Android**: `android/app/google-services.json`
- **iOS**: `ios/Runner/GoogleService-Info.plist`
- **Flutter**: `lib/firebase_options.dart`

Para reconfigurar: `flutterfire configure --project=pagpagapp`

### Configuração Efí Pay (certificados)

1. Acesse o painel Efí → API → Aplicações
2. Baixe o certificado `.p12` (homologação e/ou produção)
3. Para deploy (Railway), converta para base64: `base64 -i certificado.p12 | tr -d '\n'`
4. Coloque na env var `EFI_CERT_BASE64`
5. Para dev local, coloque o arquivo em `functions/certs/` e use `EFI_CERT_PATH`
6. A chave PIX do pagador (`EFI_PAGADOR_CHAVE`) precisa ter webhook registrado antes de enviar PIX

---

## 7. Deploy

### Backend (Railway)

O backend está deployado no [Railway](https://railway.app) na URL `https://nevescapital-production.up.railway.app`.

1. Conectar o repositório Git ao Railway
2. Configurar todas as env vars listadas acima no painel do Railway
3. Railway detecta automaticamente o NestJS e faz build/deploy
4. O `Procfile` ou script `start:prod` executa `node dist/main`
5. Health check: `GET /health`

### App iOS

1. Abrir `ios/Runner.xcworkspace` no Xcode
2. Configurar signing com conta Apple Developer
3. Bundle ID: configurado no `GoogleService-Info.plist`
4. Build: `flutter build ios --release`
5. Archive e upload via Xcode → App Store Connect

### App Android

1. Gerar keystore: `scripts/generate-keystore.sh`
2. Build: `flutter build appbundle --release`
3. Upload do `.aab` no Google Play Console
4. Configurações de versão em `pubspec.yaml` (campo `version`)

### Firebase Rules

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage
```

---

## 8. Convenções de Código

### Nomeação

| Tipo | Convenção | Exemplo |
|---|---|---|
| Telas de cadastro | Prefixo `registration_*` | `registration_phone_screen.dart` |
| Telas de pagamento | Prefixo `payment_step*` | `payment_step1_screen.dart` |
| Classes de tela | PascalCase + sufixo `Screen` | `RegistrationPhoneScreen` |
| Factories de DI | Sufixo `_usecase_factory.dart` | `auth_usecase_factory.dart` |
| Services | Sufixo `_service.dart` | `encryption_service.dart` |
| Controllers | Sufixo `_controller.dart` | `auth_controller.dart` |

### Padrões de UI

- **AppBar**: Usar `GlassAppBar` (transparente) nas telas de cadastro com `extendBodyBehindAppBar: true`
- **Body padding**: `MediaQuery.padding.top + kToolbarHeight + 16 (se progress indicator) + 40`
- **Títulos AppBar**: fontSize 20, bold, branco
- **Botão primário**: 56px altura, borderRadius 12, `AppTheme.primaryColor` (#28CC28)
- **Cores**: Sempre usar `AppTheme.*` — nunca hex direto
- **Espaçamento**: Usar `DesignSystem.spacing*` (XS=4, SM=8, MD=16, LG=24, XL=32, XXL=40)
- **Textos**: Sempre em pt-BR
- **Swipe-back**: Todas as telas de cadastro usam `PopScope(canPop: false, onPopInvokedWithResult: ...)`

### Paleta de Cores Principal

| Constante | Hex | Uso |
|---|---|---|
| `primaryColor` | `#28CC28` | Botões, acentos, sucesso |
| `splashColor` | `#023E25` | Splash screen, MainTab background |
| `backgroundColor` | `#122118` | Fundo padrão das telas |
| `surfaceColor` | `#1A2B1F` | Superfícies, inputs |
| `cardColor` | `#1F2A1F` | Cards |
| `textPrimary` | `#FFFFFF` | Texto principal |
| `textSecondary` | `#A1A1AA` | Texto secundário |
| `errorColor` | `#EF4444` | Erros |

### Logging

- Usar `AppLogger` (nunca `print` ou `debugPrint` em código novo)
- `AppLogger.debug()` — rastreamento (só dev)
- `AppLogger.info()` — informação geral
- `AppLogger.warning()` — avisos
- `AppLogger.error()` — erros (sempre no catch)
- `AppLogger.sensitive()` — dados sensíveis (mascarados automaticamente, nunca em produção)
- Em release mode, apenas `warning` e `error` são logados

### Commits

- Mensagens em **português**
- Prefixos: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`
- Exemplo: `feat: adicionar tela de gerenciamento de chaves PIX`

---

## 9. Problemas Conhecidos e Limitações

### iOS

- **iOS < 26**: Autofill de OTP via WhatsApp não funciona (só via SMS). `AutofillHints.oneTimeCode` já está implementado — funcionará automaticamente a partir do iOS 26+.
- **Keyboard accessory**: Botão "OK" no teclado numérico é implementado nativamente em Swift (`KeyboardDoneAccessory.swift`). Inicialização pode falhar silenciosamente.

### Entidade RegistrationProgress

- Contém campos **legacy** que não são usados no fluxo atual: `selfiePath`, `documentFrontPath`, `documentBackPath`, `documentType`
- As telas `step7_selfie_screen.dart` e `step8_document_screen.dart` existem mas não fazem parte do fluxo ativo

### PIX (Efí Pay)

- Integração funcional em **homologação** — produção requer:
  - Certificado `.p12` de produção
  - Alterar `EFI_AMBIENTE` para `producao`
  - Registrar webhook na chave PIX do pagador
- **Webhook receiver**: Salva eventos em `pix_webhooks/{e2eId}` no Firestore, mas a **reconciliação automática** com a collection `sales` não está implementada (ver `efi-webhook.controller.ts` — há um TODO)
- Sem webhook registrado na chave do pagador, a Efí recusa o envio com erro `documento_bloqueado`

### Firestore Rules

- As regras atuais são **permissivas demais** para produção:
  - `users`: `allow create, update, read: if true` — necessário para o cadastro funcionar sem auth, mas deve ser restringido
  - `registration_progress`: `allow read, write: if true`
  - `sales`: `allow read, create, update: if true`
- Dados sensíveis (CPF, email, telefone) estão criptografados no Firestore, mitigando parcialmente o risco

### Segurança

- O endpoint `POST /api/auth/send-otp` retorna o código OTP no response (`code: result.code`) — marcado como "APENAS PARA TESTES" — **remover em produção**
- A `API_KEY` é estática e compartilhada — considerar implementar rotação de chaves
- `flutter_dotenv` carrega o `.env` como asset do app — o arquivo é incluído no bundle e pode ser extraído

### Dependências

- `intl: 0.20.2` tem override forçado via `dependency_overrides` para resolver conflito entre `flutter_localizations` e `flutter_credit_card_detector`
- `credit_card_scanner` está desabilitado (conflito com Firebase) — TODO: procurar alternativa

### Backend

- Módulo `database/` com pasta `migrations/` está reservado mas não utilizado
- `firebase-admin` é listado como dependência no `package.json`, coexistindo com os serviços REST customizados (`FirestoreRestService`, `AuthJwtService`) — a intenção era migrar tudo para REST, mas a migração não foi concluída

---

## 10. Próximos Passos Sugeridos

### Prioridade Alta

1. **Finalizar integração Efí PIX em produção**
   - Obter certificado de produção
   - Testar fluxo completo em ambiente produção
   - Registrar webhook na chave PIX do pagador em produção

2. **Implementar reconciliação de webhooks PIX**
   - Quando receber webhook da Efí, buscar a venda correspondente na subcollection `sales` e atualizar o status
   - Atualmente os webhooks são salvos em `pix_webhooks/` mas não vinculados às vendas

3. **Remover código de teste em produção**
   - Remover retorno do OTP code no endpoint `send-otp`
   - Revisar logs que expõem dados sensíveis

### Prioridade Média

4. **Restringir Firestore rules**
   - Implementar autenticação adequada nas regras
   - Considerar usar Custom Claims no JWT para validação

5. **Implementar testes automatizados**
   - Testes unitários para services e controllers (backend)
   - Widget tests para telas críticas (Flutter)
   - Testes de integração para o fluxo de cadastro e pagamento

6. **Configurar CI/CD**
   - GitHub Actions para lint, testes e build
   - Deploy automático do backend no Railway
   - Build automático de iOS/Android

7. **Limpar campos legacy de RegistrationProgress**
   - Remover `selfiePath`, `documentFrontPath`, `documentBackPath`
   - Ou reintegrar o fluxo de selfie/documento se necessário

### Prioridade Baixa

8. **Melhorar segurança do `.env` no Flutter**
   - Migrar para `--dart-define` ou `--dart-define-from-file` em vez de `flutter_dotenv`
   - Garantir que a API_KEY não seja extraível do bundle

9. **Implementar notificações push**
   - Confirmação de PIX recebido
   - Status de venda

10. **Feature de investimentos**
    - O módulo `lib/features/investments/` existe com entidades básicas mas não está implementado

---

## Glossário

| Termo | Significado |
|---|---|
| **OTP** | One-Time Password — código de verificação de uso único |
| **KYC** | Know Your Customer — verificação de identidade |
| **PEP** | Pessoa Exposta Politicamente |
| **mTLS** | Mutual TLS — autenticação bidirecional com certificado |
| **PIX-out** | Envio de PIX (a Pag Pag envia dinheiro para o recebedor) |
| **e2eId** | End-to-End ID — identificador único do PIX no sistema bancário |
| **idEnvio** | Identificador de envio — gerado pela Pag Pag para idempotência |
| **Efí** | Efí Pay (antigo Gerencianet) — gateway de pagamentos PIX |
| **BR Code** | Código do PIX copia-e-cola |
