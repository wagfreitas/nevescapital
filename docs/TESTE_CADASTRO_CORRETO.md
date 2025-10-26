# 🧪 Guia de Teste - Cadastro com Consistência

## ⚠️ IMPORTANTE: Como Testar Corretamente

### **Passo 1: PARAR o app Flutter completamente**

```bash
# No terminal onde o Flutter está rodando:
# Pressione Ctrl+C para parar

# Ou no Android Studio / VS Code:
# Clique no botão STOP (quadrado vermelho)
```

**Por quê?** Hot reload pode usar código em cache!

---

### **Passo 2: LIMPAR build cache**

```bash
cd /Users/wagneralves/StudioProjects/neves_capital

flutter clean
flutter pub get
```

---

### **Passo 3: GARANTIR que a API está desligada**

```bash
# Verificar se NADA está rodando na porta 8080
lsof -i :8080

# Se aparecer algo, matar o processo:
kill -9 <PID>

# Ou simplesmente NÃO iniciar a API
```

---

### **Passo 4: INICIAR o app novamente**

```bash
flutter run
```

---

### **Passo 5: TENTAR criar uma conta**

1. Abrir o app
2. Ir para "Criar Conta"
3. Preencher todos os dados
4. Tentar finalizar cadastro

---

## 📊 Resultado Esperado

### ✅ **Se a API estiver DESLIGADA:**

**Logs no terminal Flutter:**
```
📝 Etapa 1: Criando usuário no PostgreSQL...
📤 Enviando dados para API NestJS...
🔗 URL: http://localhost:8080/api/users/register
❌ Erro ao criar usuário: ClientException with SocketException: Connection refused

═══════════════════════════════════════════════
❌ ERRO NO CADASTRO - NADA FOI GRAVADO
═══════════════════════════════════════════════
Erro: Exception: Erro ao salvar no PostgreSQL: ...
PostgreSQL foi criado? NÃO
Firebase foi criado? NÃO
═══════════════════════════════════════════════
```

**Resultado:**
- ❌ **NÃO** deve criar no Firebase
- ❌ **NÃO** deve criar no PostgreSQL
- ✅ Mensagem de erro deve aparecer no app

---

### ✅ **Se a API estiver LIGADA:**

**Logs no terminal Flutter:**
```
📝 Etapa 1: Criando usuário no PostgreSQL...
📤 Enviando dados para API NestJS...
✅ Usuário criado no PostgreSQL: 87db5fea-4f63-4788-9c47-ef3db541d18f

✅ PostgreSQL confirmado! Prosseguindo para Firebase...
📝 Etapa 2: Criando usuário no Firebase...
✅ Usuário criado no Firebase: AbC123XyZ456

✅ Cadastro completo! Usuário em PostgreSQL e Firebase
```

**Resultado:**
- ✅ Criado no PostgreSQL primeiro
- ✅ Criado no Firebase depois
- ✅ Usuário em AMBOS os bancos

---

## 🔍 Se Ainda Estiver Criando no Firebase (API Desligada)

### **Verificação 1: Confirmar que está usando o código correto**

Abra o arquivo:
```
lib/features/auth/presentation/controllers/auth_controller_real.dart
```

Na linha 70, deve ter:
```dart
print('📝 Etapa 1: Criando usuário no PostgreSQL...');
```

Se não tiver esse print, o código não foi atualizado!

---

### **Verificação 2: Confirmar que NÃO há hot reload**

1. **Parar completamente** o app (Ctrl+C)
2. **Fechar** o emulador/simulador
3. **Limpar** build: `flutter clean`
4. **Reinstalar** dependências: `flutter pub get`
5. **Reiniciar** app: `flutter run`

---

### **Verificação 3: Verificar se há outro código criando Firebase**

Procure por outros arquivos que podem estar criando usuário:

```bash
cd /Users/wagneralves/StudioProjects/neves_capital

# Procurar por createUserWithEmailAndPassword
grep -r "createUserWithEmailAndPassword" lib/ --include="*.dart"
```

Se encontrar em outros arquivos além de:
- `auth_controller_real.dart`
- `auth_service.dart`
- `firebase_auth_remote_datasource.dart`

Pode haver outro código criando usuário!

---

### **Verificação 4: Ver os logs COMPLETOS**

Quando tentar criar a conta (com API desligada), copie **TODOS** os logs do terminal e me envie.

Procure especialmente por:
- `📝 Etapa 1: Criando usuário no PostgreSQL...`
- `✅ PostgreSQL confirmado! Prosseguindo para Firebase...`
- `⚠️ ATENÇÃO: Se você está vendo esta mensagem...`

**Se você ver as mensagens acima COM A API DESLIGADA, há um problema!**

---

## 🧪 Teste Completo - Cenário 1: API Desligada

```
┌──────────────────────────────┐
│  1. API desligada           │
│  2. Flutter clean           │
│  3. Flutter run             │
│  4. Tentar criar conta      │
└──────────────────────────────┘
              ↓
┌──────────────────────────────┐
│  ❌ Erro: Connection refused │
│  ❌ PostgreSQL: NÃO criado   │
│  ❌ Firebase: NÃO criado     │
│  ✅ Mensagem de erro no app  │
└──────────────────────────────┘
```

---

## 🧪 Teste Completo - Cenário 2: API Ligada

```
┌──────────────────────────────┐
│  1. Iniciar API (npm run     │
│     start:dev na pasta       │
│     functions)               │
│  2. Flutter clean            │
│  3. Flutter run              │
│  4. Tentar criar conta       │
└──────────────────────────────┘
              ↓
┌──────────────────────────────┐
│  ✅ PostgreSQL: criado       │
│  ✅ Firebase: criado         │
│  ✅ Usuário em AMBOS         │
│  ✅ Sucesso no app           │
└──────────────────────────────┘
```

---

## 🧪 Teste Completo - Cenário 3: Rollback

Para testar o rollback (PostgreSQL OK, Firebase falha):

1. Criar conta com email inválido do Firebase (ex: `teste@invalido`)
2. PostgreSQL deve criar
3. Firebase deve falhar
4. **Rollback deve deletar do PostgreSQL**

**Logs esperados:**
```
✅ Usuário criado no PostgreSQL: 87db5fea-...
📝 Etapa 2: Criando usuário no Firebase...
❌ Erro ao criar no Firebase: ...
🔄 ROLLBACK: Deletando usuário do PostgreSQL...
✅ Rollback concluído - Usuário removido do PostgreSQL
```

---

## 📋 Checklist Final

Antes de dizer que está criando no Firebase com API desligada:

- [ ] App Flutter foi **parado completamente** (Ctrl+C)
- [ ] `flutter clean` foi executado
- [ ] `flutter pub get` foi executado
- [ ] API NestJS está **comprovadamente desligada** (`lsof -i :8080` não retorna nada)
- [ ] App foi **reiniciado do zero** (`flutter run`)
- [ ] Logs mostram `📝 Etapa 1: Criando usuário no PostgreSQL...`
- [ ] Logs mostram erro `Connection refused`
- [ ] Logs mostram `PostgreSQL foi criado? NÃO`
- [ ] Logs mostram `Firebase foi criado? NÃO`

---

## 🆘 Se Ainda Houver Problema

Se após seguir TODOS os passos acima, ainda estiver criando no Firebase com API desligada:

1. **Copie TODOS os logs** do terminal Flutter
2. **Tire um screenshot** da mensagem de erro no app
3. **Confirme** que executou `flutter clean`
4. **Confirme** que a API está desligada (`lsof -i :8080`)
5. **Me envie** essas informações

---

**Atualizado em:** 20/10/2024  
**Versão:** 2.0.0

