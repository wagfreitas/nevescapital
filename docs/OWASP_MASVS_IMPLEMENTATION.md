# 🔒 Implementação OWASP MASVS no PagPag

## 📋 Visão Geral

Este documento descreve como o aplicativo PagPag implementa os controles de segurança do **OWASP Mobile Application Security Verification Standard (MASVS)**.

Referência: [https://mas.owasp.org/MASVS/](https://mas.owasp.org/MASVS/)

---

## ✅ MASVS-STORAGE: Armazenamento Seguro

### MASVS-STORAGE-1: Dados Sensíveis Armazenados Criptografados

**Status**: ✅ Implementado

**Implementação**:
```dart
// lib/shared/services/secure_storage_service.dart
- flutter_secure_storage para dados sensíveis
- Keychain (iOS) e KeyStore (Android)
- Tokens, credenciais e dados pessoais criptografados
```

**Dados Protegidos**:
- ✅ Tokens de autenticação
- ✅ ID do usuário
- ✅ Email do usuário
- ✅ Último CPF usado
- ✅ Configurações de biometria

**Configuração Android**:
```kotlin
AndroidOptions(
  encryptedSharedPreferences: true,
  resetOnError: true
)
```

**Configuração iOS**:
```dart
IOSOptions(
  accessibility: KeychainAccessibility.first_unlock_this_device,
  synchronizable: false  // Não sincronizar com iCloud
)
```

### MASVS-STORAGE-2: Dados Não Incluídos em Backups Não Criptografados

**Status**: ✅ Implementado

**Implementação**:
```xml
<!-- AndroidManifest.xml -->
android:allowBackup="false"
```

---

## 🔐 MASVS-CRYPTO: Criptografia

### MASVS-CRYPTO-1: Algoritmos Criptográficos Aprovados

**Status**: ✅ Implementado

**Backend** (`functions/src/common/services/encryption-v2.service.ts`):
- ✅ **AES-256-GCM** (substituiu CryptoJS)
- ✅ **SHA-256** para hashing
- ✅ **bcrypt** (12 rounds) para senhas
- ✅ **HMAC-SHA256** para hash pesquisável

**Antes (❌ Problema)**:
```typescript
// CryptoJS com salt aleatório
// Cada criptografia gerava valor diferente
// Impossível buscar no banco
```

**Depois (✅ Solução)**:
```typescript
// AES-256-GCM com IV aleatório
encrypt(text: string): string {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  // ... autenticação incluída
}

// HMAC para busca determinística
createSearchableHash(text: string): string {
  const hmac = crypto.createHmac('sha256', key);
  return hmac.digest('hex');
}
```

### MASVS-CRYPTO-2: Geração de Chaves Segura

**Status**: ✅ Implementado

- ✅ `crypto.randomBytes()` para IVs e tokens
- ✅ `crypto.createHash('sha256')` para derivação de chaves
- ✅ Salt único por registro (bcrypt)
- ✅ Chaves não hardcoded (environment variables)

---

## 🔑 MASVS-AUTH: Autenticação e Autorização

### MASVS-AUTH-1: Armazenamento Seguro de Credenciais

**Status**: ✅ Implementado

- ✅ Tokens armazenados em `SecureStorageService`
- ✅ Senhas nunca armazenadas localmente
- ✅ Biometria usa Keychain/KeyStore

### MASVS-AUTH-2: Autenticação Biométrica

**Status**: ✅ Implementado

```dart
// lib/features/auth/presentation/controllers/auth_controller_real.dart
- local_auth plugin
- Fallback para senha se biometria falhar
- Configuração salva em secure storage
```

### MASVS-AUTH-3: Validação Server-Side

**Status**: ✅ Implementado

- ✅ Autenticação via Firebase
- ✅ Validação de CPF no PostgreSQL
- ✅ API Key obrigatória (`ApiKeyGuard`)
- ✅ Rate limiting (Throttle)

---

## 🌐 MASVS-NETWORK: Comunicação de Rede

### MASVS-NETWORK-1: Certificate Pinning

**Status**: ⚠️ Parcialmente Implementado

**Implementação**:
```dart
// lib/shared/services/secure_http_client.dart
- Cliente HTTP customizado
- Validação de certificados
- Preparado para pinning (fingerprints a serem configurados)
```

**Android**:
```xml
<!-- android/app/src/main/res/xml/network_security_config.xml -->
- Configuração de pinning preparada
- Apenas TLS
- Cleartext bloqueado
```

**⚠️ Ação Necessária**:
```bash
# Obter fingerprint do certificado do servidor
openssl s_client -connect seu-dominio.com:443 | \
  openssl x509 -pubkey -noout | \
  openssl pkey -pubin -outform der | \
  openssl dgst -sha256 -binary | \
  openssl enc -base64
```

### MASVS-NETWORK-2: TLS Seguro

**Status**: ✅ Implementado

```xml
<!-- AndroidManifest.xml -->
android:usesCleartextTraffic="false"
```

```dart
// Apenas TLS 1.2+
final securityContext = SecurityContext.defaultContext;
```

---

## 📱 MASVS-PLATFORM: Interação com Plataforma

### MASVS-PLATFORM-1: Proteção Contra Screenshots

**Status**: ✅ Implementado

**Android**:
```kotlin
// SecurityPlugin.kt
window.setFlags(
  WindowManager.LayoutParams.FLAG_SECURE,
  WindowManager.LayoutParams.FLAG_SECURE
)
```

**Uso**:
```dart
// Em telas sensíveis (pagamento, dados pessoais)
await SecurityService.enableScreenshotProtection();
```

**iOS**: 
- ⚠️ iOS não permite bloquear screenshots
- Alternativa: Detectar quando screenshot é tirado

### MASVS-PLATFORM-2: Logs Sanitizados

**Status**: ✅ Implementado

```dart
// lib/shared/services/security_service.dart
static String sanitizeLog(String message) {
  // Remove CPF, email, cartão, CVV, tokens
  return sanitized;
}

// Uso
SecurityService.secureLog('Processando pagamento...');
```

**Padrões Removidos**:
- ✅ CPF (000.000.000-00)
- ✅ Email
- ✅ Cartão de crédito (16 dígitos)
- ✅ CVV (3-4 dígitos)
- ✅ Tokens longos (32+ caracteres)

### MASVS-PLATFORM-3: Dados Não Vazam na UI

**Status**: ✅ Implementado

- ✅ Campos de senha com `obscureText: true`
- ✅ Cartão mascarado (•••• 1234)
- ✅ CVV nunca exibido após digitação
- ✅ CPF mascarado em algumas telas

---

## 🔧 MASVS-CODE: Qualidade de Código

### MASVS-CODE-1: Dependências Atualizadas

**Status**: ⚠️ Em Andamento

```bash
# Verificar dependências com vulnerabilidades
flutter pub outdated
npm audit

# Atualizar regularmente
flutter pub upgrade
npm update
```

### MASVS-CODE-2: Validação de Entrada

**Status**: ✅ Implementado

```dart
// Validação em todos os formulários
- CPF: ValidatorHelper.cpf()
- Email: ValidatorHelper.email()
- Cartão: ValidatorHelper.cardNumber()
- CVV: ValidatorHelper.cvv()
```

### MASVS-CODE-3: Tratamento de Erros

**Status**: ✅ Implementado

```dart
// Erros genéricos para o usuário
catch (e) {
  _setError('Erro ao processar. Tente novamente.');
  // Log detalhado apenas no console (sanitizado)
}
```

### MASVS-CODE-4: Sem Dados Sensíveis em Logs

**Status**: ✅ Implementado

- ✅ `SecurityService.sanitizeLog()`
- ✅ Logs de produção reduzidos
- ✅ Prints apenas em debug

---

## 🛡️ MASVS-RESILIENCE: Resiliência

### MASVS-RESILIENCE-1: Detecção de Root/Jailbreak

**Status**: ✅ Implementado

**Android**:
```kotlin
// SecurityPlugin.kt
private fun isDeviceRooted(): Boolean {
  // Verifica arquivos su
  // Verifica build tags
  // Verifica apps de root
}
```

**Uso**:
```dart
final isCompromised = await SecurityService.isDeviceCompromised();
if (isCompromised) {
  // Mostrar aviso ou bloquear app
}
```

### MASVS-RESILIENCE-2: Detecção de Debugger

**Status**: ✅ Implementado

```kotlin
private fun isDebuggerConnected(): Boolean {
  return Debug.isDebuggerConnected() || 
         Debug.waitingForDebugger()
}
```

### MASVS-RESILIENCE-3: Ofuscação de Código

**Status**: ⏳ Planejado

**Próximos Passos**:
```gradle
// android/app/build.gradle
buildTypes {
  release {
    minifyEnabled true
    shrinkResources true
    proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
  }
}
```

---

## 🕵️ MASVS-PRIVACY: Privacidade

### MASVS-PRIVACY-1: Minimização de Dados

**Status**: ✅ Implementado

- ✅ Apenas dados necessários coletados
- ✅ Dados criptografados no backend
- ✅ Não sincronização automática com cloud

### MASVS-PRIVACY-2: Política de Privacidade

**Status**: ✅ Implementado

- ✅ Documento criado (`docs/politica.html`)
- ✅ Conforme LGPD
- ✅ Específico para fintech

### MASVS-PRIVACY-3: Permissões Mínimas

**Status**: ✅ Implementado

```xml
<!-- Apenas permissões necessárias -->
- CAMERA (KYC)
- READ_EXTERNAL_STORAGE (Upload documentos)
- INTERNET (API)
- USE_BIOMETRIC (Autenticação)
```

### MASVS-PRIVACY-4: Exclusão de Dados

**Status**: ⏳ Planejado

**Próximos Passos**:
- Implementar endpoint de exclusão de conta
- GDPR/LGPD compliance completo

---

## 📊 Resumo de Compliance

| Categoria | Status | Implementado | Planejado | Total |
|-----------|--------|--------------|-----------|-------|
| **MASVS-STORAGE** | ✅ | 2/2 | 0 | 100% |
| **MASVS-CRYPTO** | ✅ | 2/2 | 0 | 100% |
| **MASVS-AUTH** | ✅ | 3/3 | 0 | 100% |
| **MASVS-NETWORK** | ⚠️ | 1/2 | 1 | 50% |
| **MASVS-PLATFORM** | ✅ | 3/3 | 0 | 100% |
| **MASVS-CODE** | ⚠️ | 3/4 | 1 | 75% |
| **MASVS-RESILIENCE** | ⚠️ | 2/3 | 1 | 67% |
| **MASVS-PRIVACY** | ⚠️ | 3/4 | 1 | 75% |
| **TOTAL** | **✅** | **19/23** | **4** | **83%** |

---

## 🎯 Próximas Ações

### Prioridade Alta (🔴)
1. **Configurar Certificate Pinning**
   - Obter fingerprints dos certificados
   - Atualizar `network_security_config.xml`
   - Testar em produção

2. **Habilitar Code Obfuscation**
   - Configurar ProGuard
   - Testar build release
   - Verificar tamanho do APK

### Prioridade Média (🟡)
3. **Auditoria de Dependências**
   - Configurar renovate/dependabot
   - Automatizar verificação de vulnerabilidades
   - Criar processo de atualização

4. **Implementar Exclusão de Dados**
   - Endpoint de exclusão de conta
   - Compliance LGPD completo
   - Testes de exclusão

### Prioridade Baixa (🟢)
5. **Monitoramento de Segurança**
   - Firebase Crashlytics
   - Logs de tentativas de ataque
   - Alertas de anomalias

---

## 🔗 Referências

- [OWASP MASVS](https://mas.owasp.org/MASVS/)
- [OWASP MASTG](https://mas.owasp.org/MASTG/)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)
- [Android Security Best Practices](https://developer.android.com/topic/security/best-practices)
- [iOS Security](https://support.apple.com/guide/security/welcome/web)

---

## 📝 Changelog

### 2025-10-15
- ✅ Implementação inicial MASVS
- ✅ SecureStorageService criado
- ✅ EncryptionV2Service no backend
- ✅ SecurityPlugin Android
- ✅ Network Security Config
- ✅ Documentação completa

---

## 👥 Contribuidores

- Wagner Alves (desenvolvedor)
- OWASP MASVS Team (guidelines)

---

**Última Atualização**: 15 de outubro de 2025
**Versão do App**: 1.0.0
**MASVS Version**: v2.1.0

