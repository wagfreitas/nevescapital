# 🚀 Guia Rápido de Segurança - PagPag

## 📱 Para Desenvolvedores Flutter

### 1. Armazenar Dados Sensíveis

```dart
import 'package:neves_capital/shared/services/secure_storage_service.dart';

// ✅ CORRETO: Usar SecureStorageService
await SecureStorageService.saveAuthToken(token);
await SecureStorageService.saveUserId(userId);

// ❌ ERRADO: Usar SharedPreferences para dados sensíveis
await prefs.setString('token', token); // NÃO FAÇA ISSO!
```

### 2. Fazer Requisições HTTP

```dart
import 'package:neves_capital/shared/services/secure_http_client.dart';

// ✅ CORRETO: Usar SecureHttpClient
final response = await SecureHttpClient.get(
  Uri.parse('https://api.exemplo.com/users'),
  headers: {'Authorization': 'Bearer $token'},
);

// ❌ ERRADO: http.Client padrão (sem pinning)
final response = await http.get(url); // NÃO FAÇA ISSO!
```

### 3. Proteger Telas Sensíveis

```dart
import 'package:neves_capital/shared/services/security_service.dart';

class PaymentScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    // Habilitar proteção contra screenshots
    SecurityService.enableScreenshotProtection();
  }

  @override
  void dispose() {
    // Desabilitar ao sair da tela
    SecurityService.disableScreenshotProtection();
    super.dispose();
  }
}
```

### 4. Logs Seguros

```dart
import 'package:neves_capital/shared/services/security_service.dart';

// ✅ CORRETO: Log sanitizado
SecurityService.secureLog('Processando pagamento para CPF: 123.456.789-00');
// Output: Processando pagamento para CPF: ***REDACTED***

// ❌ ERRADO: Print direto com dados sensíveis
print('CPF: $cpf, Email: $email'); // NÃO FAÇA ISSO!
```

### 5. Validar Entrada do Usuário

```dart
// ✅ CORRETO: Sempre validar
if (!ValidatorHelper.cpf(cpf)) {
  return 'CPF inválido';
}

if (!ValidatorHelper.cardNumber(cardNumber)) {
  return 'Cartão inválido';
}
```

---

## 🖥️ Para Desenvolvedores Backend (NestJS)

### 1. Usar EncryptionV2Service

```typescript
// functions/src/common/services/encryption-v2.service.ts

// ✅ CORRETO: AES-256-GCM
const encrypted = this.encryptionV2.encrypt(cpf);
const decrypted = this.encryptionV2.decrypt(encrypted);

// Para busca no banco
const searchHash = this.encryptionV2.createSearchableHash(cpf);

// ❌ ERRADO: CryptoJS (deprecated)
const encrypted = CryptoJS.AES.encrypt(cpf, key); // NÃO USE MAIS!
```

### 2. Estrutura de Tabela com Criptografia

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  -- Campo criptografado (AES-256-GCM)
  cpf_encrypted TEXT NOT NULL,
  -- Hash para busca (HMAC-SHA256)
  cpf_hash TEXT NOT NULL UNIQUE,
  email_encrypted TEXT NOT NULL,
  email_hash TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Índice no hash (não no encrypted)
CREATE INDEX idx_users_cpf_hash ON users(cpf_hash);
```

### 3. Implementar Busca com Hash

```typescript
async findByCpf(cpf: string) {
  // 1. Criar hash do CPF
  const cpfHash = this.encryptionV2.createSearchableHash(cpf);
  
  // 2. Buscar pelo hash (rápido)
  const result = await this.pool.query(
    'SELECT * FROM users WHERE cpf_hash = $1',
    [cpfHash]
  );
  
  // 3. Descriptografar dados
  if (result.rows.length > 0) {
    const user = result.rows[0];
    return {
      id: user.id,
      cpf: this.encryptionV2.decrypt(user.cpf_encrypted),
      email: this.encryptionV2.decrypt(user.email_encrypted),
    };
  }
  
  return null;
}
```

### 4. Salvar com Criptografia e Hash

```typescript
async create(createUserDto: CreateUserDto) {
  // Criptografar dados sensíveis
  const cpfEncrypted = this.encryptionV2.encrypt(createUserDto.cpf);
  const emailEncrypted = this.encryptionV2.encrypt(createUserDto.email);
  
  // Criar hashes para busca
  const cpfHash = this.encryptionV2.createSearchableHash(createUserDto.cpf);
  const emailHash = this.encryptionV2.createSearchableHash(createUserDto.email);
  
  // Hash de senha com bcrypt
  const passwordHash = await this.encryptionV2.hashPassword(createUserDto.password);
  
  await this.pool.query(
    `INSERT INTO users (
      cpf_encrypted, cpf_hash,
      email_encrypted, email_hash,
      password_hash
    ) VALUES ($1, $2, $3, $4, $5)`,
    [cpfEncrypted, cpfHash, emailEncrypted, emailHash, passwordHash]
  );
}
```

---

## 🔧 Checklist de Segurança

### Antes de Commitar

- [ ] Remover console.log/print com dados sensíveis
- [ ] Validar todas as entradas do usuário
- [ ] Usar SecureStorageService para dados sensíveis
- [ ] Não hardcodar API keys ou secrets
- [ ] Sanitizar logs com SecurityService

### Antes de Deploy

- [ ] Testar proteção contra screenshots
- [ ] Verificar certificate pinning configurado
- [ ] Auditar dependências (`flutter pub outdated`, `npm audit`)
- [ ] Testar em dispositivo real (não apenas emulador)
- [ ] Verificar que `usesCleartextTraffic="false"`
- [ ] Testar detecção de root/jailbreak

### Em Produção

- [ ] Monitorar logs de segurança
- [ ] Revisar relatórios de crash
- [ ] Atualizar dependências mensalmente
- [ ] Renovar certificados antes do vencimento
- [ ] Revisar acessos e permissões

---

## ⚠️ Nunca Faça Isso

### 1. Armazenamento Inseguro
```dart
// ❌ ERRADO
await prefs.setString('password', password);
await prefs.setString('cpf', cpf);
await prefs.setString('token', token);
```

### 2. Logs com Dados Sensíveis
```dart
// ❌ ERRADO
print('Login: $cpf / $password');
print('Token: $authToken');
print('Cartão: $cardNumber CVV: $cvv');
```

### 3. Hardcoded Secrets
```dart
// ❌ ERRADO
const API_KEY = 'sk_live_123456789';
const SECRET_KEY = 'super-secret-key';
```

### 4. HTTP sem TLS
```dart
// ❌ ERRADO
final url = 'http://api.exemplo.com'; // Use HTTPS!
```

### 5. Ignorar Validação
```dart
// ❌ ERRADO
await makePayment(cardNumber); // Validar primeiro!
```

---

## 📚 Exemplos Completos

### Exemplo 1: Tela de Login Segura

```dart
import 'package:flutter/material.dart';
import 'package:neves_capital/shared/services/secure_storage_service.dart';
import 'package:neves_capital/shared/services/security_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Proteger tela de login
    SecurityService.enableScreenshotProtection();
    _loadLastCpf();
  }

  Future<void> _loadLastCpf() async {
    // Carregar último CPF usado (se disponível)
    final lastCpf = await SecureStorageService.getLastCpf();
    if (lastCpf != null) {
      _cpfController.text = lastCpf;
    }
  }

  Future<void> _handleLogin() async {
    final cpf = CpfHelper.getCpfNumbers(_cpfController.text);
    final password = _passwordController.text;

    // Validar entrada
    if (!ValidatorHelper.cpf(cpf)) {
      _showError('CPF inválido');
      return;
    }

    if (password.length < 6) {
      _showError('Senha muito curta');
      return;
    }

    try {
      // Fazer login
      final success = await _authController.loginWithCpf(
        cpf: cpf,
        password: password,
      );

      if (success) {
        // Salvar último CPF
        await SecureStorageService.saveLastCpf(cpf);
        
        // Log seguro
        SecurityService.secureLog('Login bem-sucedido para CPF: $cpf');
        
        // Navegar para home
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      SecurityService.secureLog('Erro no login: $e');
      _showError('Erro ao fazer login');
    }
  }

  @override
  void dispose() {
    // Limpar dados sensíveis
    _cpfController.clear();
    _passwordController.clear();
    SecurityService.disableScreenshotProtection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        child: Column(
          children: [
            TextFormField(
              controller: _cpfController,
              decoration: InputDecoration(labelText: 'CPF'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Senha'),
              obscureText: true, // Ocultar senha
            ),
            ElevatedButton(
              onPressed: _handleLogin,
              child: Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Exemplo 2: Service de API Seguro

```dart
import 'package:neves_capital/shared/services/secure_http_client.dart';
import 'package:neves_capital/shared/services/secure_storage_service.dart';
import 'package:neves_capital/shared/services/security_service.dart';

class UserService {
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      // Obter token do secure storage
      final token = await SecureStorageService.getAuthToken();
      
      if (token == null) {
        SecurityService.secureLog('Token não encontrado');
        return null;
      }

      // Fazer requisição segura
      final response = await SecureHttpClient.get(
        Uri.parse('https://api.pagpag.com/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        SecurityService.secureLog('Perfil carregado com sucesso');
        return jsonDecode(response.body);
      } else {
        SecurityService.secureLog('Erro ao carregar perfil: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      SecurityService.secureLog('Exceção ao carregar perfil: $e');
      return null;
    }
  }
}
```

---

## 🆘 Dúvidas Comuns

### Q: Quando usar SecureStorage vs SharedPreferences?

**A**: Use **SecureStorage** para:
- Tokens de autenticação
- Senhas/PINs temporários
- Dados pessoais sensíveis (CPF, email)
- Configurações de biometria

Use **SharedPreferences** para:
- Preferências de UI (tema, idioma)
- Flags de onboarding
- Cache não sensível
- Configurações públicas

### Q: Como testar segurança em desenvolvimento?

**A**: 
```bash
# Android: Verificar root
adb shell su -c 'ls /data/data'

# Verificar SSL Pinning
# Use Burp Suite ou Charles Proxy
# O app deve rejeitar certificados não autorizados

# Verificar proteção de screenshots
# Tentar tirar screenshot em tela sensível
# Deve aparecer tela preta ou erro
```

### Q: Como atualizar certificado sem quebrar o app?

**A**: Use múltiplos pins e atualização gradual:
```xml
<pin-set expiration="2026-01-01">
  <pin digest="SHA-256">PIN_ATUAL</pin>
  <pin digest="SHA-256">PIN_BACKUP</pin>
</pin-set>
```

---

## 📞 Contato

**Dúvidas sobre segurança?**
- Consulte: `OWASP_MASVS_IMPLEMENTATION.md`
- Issues: GitHub Issues
- Security: security@nevescapital.com

---

**Mantenha este guia atualizado!** 🔒

