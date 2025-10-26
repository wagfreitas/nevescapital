# ✅ Correção: Cadastro de Usuário com Consistência PostgreSQL + Firebase

## 🎯 Problema Identificado

### 1. **Ordem ERRADA de gravação**
```dart
❌ ANTES (ERRADO):
1. Criar no Firebase
2. Criar no PostgreSQL
```

### 2. **Sem mecanismo de rollback**
- Se Firebase criasse mas PostgreSQL falhasse → Usuário órfão no Firebase
- Se PostgreSQL falhasse mas Firebase criasse → Inconsistência

### 3. **Backend não estava rodando**
```
Connection refused: http://localhost:8080
```

---

## ✅ Solução Implementada

### 📝 **Nova Lógica de Cadastro**

```dart
✅ AGORA (CORRETO):
1. Tentar gravar no PostgreSQL PRIMEIRO
   └─ Se falhar → Parar e retornar erro
   
2. Se PostgreSQL OK → Tentar gravar no Firebase
   └─ Se falhar → DELETAR do PostgreSQL (rollback)
   
3. Usuário só é considerado criado se estiver em AMBOS
```

---

## 🔧 Arquivo Modificado

### `lib/features/auth/presentation/controllers/auth_controller_real.dart`

**Mudança principal:**

```dart
// ==========================================
// ETAPA 1: GRAVAR NO POSTGRESQL PRIMEIRO
// ==========================================
final postgresResult = await DatabaseService.createUser(...);
postgresUserId = postgresResult['user_id'];

// ==========================================
// ETAPA 2: GRAVAR NO FIREBASE
// ==========================================
try {
  final credential = await AuthService.createUserWithEmailAndPassword(...);
  firebaseUser = credential.user;
  
  // SUCESSO: Ambos criados
  return true;
  
} catch (firebaseError) {
  // ==========================================
  // ROLLBACK: DELETAR DO POSTGRESQL
  // ==========================================
  if (postgresUserId != null) {
    await DatabaseService.deleteUser(postgresUserId);
  }
  throw Exception('Erro ao criar no Firebase');
}
```

---

## 🚀 Como Iniciar o Backend (PASSO A PASSO)

### **Passo 1: Criar arquivo `.env`**

Navegue até a pasta `functions` e crie o arquivo `.env`:

```bash
cd functions
nano .env  # ou use seu editor preferido
```

Cole o seguinte conteúdo (AJUSTE as credenciais):

```env
# SERVIDOR
PORT=8080
NODE_ENV=development
ALLOWED_ORIGINS=http://localhost:*,http://127.0.0.1:*

# SEGURANÇA
API_KEY=neves-capital-api-key-prod-2024
ENCRYPTION_KEY=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef

# POSTGRESQL (⚠️ AJUSTAR!)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=neves_capital
DB_USER=postgres
DB_PASSWORD=SUA_SENHA_AQUI
```

Salve e feche (Ctrl+O, Enter, Ctrl+X).

---

### **Passo 2: Instalar Dependências**

```bash
cd functions
npm install
```

Aguarde a instalação concluir...

---

### **Passo 3: Verificar PostgreSQL**

**Verificar se está rodando:**
```bash
# macOS
brew services list | grep postgres

# Linux
sudo systemctl status postgresql
```

**Se não estiver rodando:**
```bash
# macOS
brew services start postgresql@15

# Linux
sudo systemctl start postgresql
```

**Criar banco de dados:**
```bash
psql postgres

# No prompt do psql:
CREATE DATABASE neves_capital;
\q
```

---

### **Passo 4: Executar Migrations (Criar Tabelas)**

```bash
# Procure o arquivo SQL schema
# Provavelmente em: functions/sql/schema.sql

psql -U postgres -d neves_capital -f functions/sql/schema.sql
```

---

### **Passo 5: Iniciar Backend NestJS**

```bash
cd functions
npm run start:dev
```

**Você deve ver:**
```
🚀 API rodando na porta 8080
📚 Documentação: http://localhost:8080/api/docs
💚 Health check: http://localhost:8080/health
✅ Conectado ao PostgreSQL Cloud SQL
```

---

### **Passo 6: Testar Health Check**

Abra o navegador: http://localhost:8080/health

Deve retornar:
```json
{
  "status": "ok",
  "timestamp": "2024-10-20T...",
  "uptime": 123.456
}
```

---

## 📱 Testar Cadastro no App

1. **Backend rodando** ✅
2. **PostgreSQL rodando** ✅
3. **Abrir app Flutter**
4. **Tentar criar uma conta**

### **Logs esperados no terminal do backend:**

```
📝 Etapa 1: Criando usuário no PostgreSQL...
🔍 Criando usuário: João Silva...
✅ Usuário criado no PostgreSQL: 87db5fea-4f63-4788-9c47-ef3db541d18f

📝 Etapa 2: Criando usuário no Firebase...
✅ Usuário criado no Firebase: AbC123XyZ

✅ Cadastro completo! Usuário em PostgreSQL e Firebase
```

### **Se Firebase falhar:**

```
📝 Etapa 1: Criando usuário no PostgreSQL...
✅ Usuário criado no PostgreSQL: 87db5fea-...

📝 Etapa 2: Criando usuário no Firebase...
❌ Erro ao criar no Firebase: [erro]
🔄 ROLLBACK: Deletando usuário do PostgreSQL...
✅ Rollback concluído - Usuário removido do PostgreSQL
```

---

## 🔍 Solução de Problemas

### ❌ Erro: "Connection refused"

**Causa**: Backend não está rodando

**Solução**:
```bash
cd functions
npm run start:dev
```

---

### ❌ Erro: "Cannot connect to PostgreSQL"

**Causa**: PostgreSQL não está rodando ou credenciais erradas

**Solução**:
1. Verificar se PostgreSQL está ativo
2. Verificar credenciais no `.env`
3. Testar conexão:
   ```bash
   psql -h localhost -U postgres -d neves_capital
   ```

---

### ❌ Erro: "Port 8080 already in use"

**Causa**: Outra aplicação usando a porta

**Solução**:
```bash
# Encontrar processo
lsof -i :8080

# Matar processo
kill -9 <PID>
```

Ou alterar a porta no `.env`:
```env
PORT=8081
```

---

## ✅ Checklist de Verificação

Antes de testar o cadastro:

- [ ] PostgreSQL rodando
- [ ] Banco `neves_capital` criado
- [ ] Tabelas criadas (migrations executadas)
- [ ] Arquivo `.env` configurado
- [ ] Backend rodando (`npm run start:dev`)
- [ ] Health check respondendo: http://localhost:8080/health
- [ ] Código do Flutter atualizado

---

## 📊 Fluxo Completo

```
┌─────────────────┐
│  Flutter App    │
└────────┬────────┘
         │
         │ 1. Dados do usuário
         ▼
┌─────────────────────────┐
│  Backend NestJS         │
│  (localhost:8080)       │
└────────┬────────────────┘
         │
         │ 2. INSERT
         ▼
┌─────────────────────────┐
│  PostgreSQL             │
│  (neves_capital DB)     │
└────────┬────────────────┘
         │
         │ 3. user_id retornado
         │
         ▼
┌─────────────────────────┐
│  Flutter App            │
└────────┬────────────────┘
         │
         │ 4. Criar usuário
         ▼
┌─────────────────────────┐
│  Firebase Auth          │
└────────┬────────────────┘
         │
         │ 5. Se falhar → DELETE no PostgreSQL
         │    Se sucesso → Usuário criado ✅
         ▼
    [CONCLUÍDO]
```

---

## 📚 Documentação Relacionada

- [BACKEND_START_GUIDE.md](./BACKEND_START_GUIDE.md) - Guia completo de inicialização
- [BACKEND_COMPLETO.md](./BACKEND_COMPLETO.md) - Arquitetura do backend
- [DEPLOY_READY.md](./DEPLOY_READY.md) - Guia de deploy

---

**Correção implementada em:** 20/10/2024  
**Desenvolvido para:** PagPag - Neves Capital  
**Versão:** 1.0.0

