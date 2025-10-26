# 🚀 Guia Completo - Iniciar Backend NestJS

## 📋 Pré-requisitos

Antes de iniciar, você precisa ter instalado:

- ✅ **Node.js 20+** (versão LTS recomendada)
- ✅ **PostgreSQL** rodando localmente
- ✅ **npm** ou **yarn**

---

## 🗄️ Passo 1: Configurar PostgreSQL

### Opção A: PostgreSQL Local

1. **Instalar PostgreSQL** (se não tiver):
   ```bash
   # macOS (Homebrew)
   brew install postgresql@15
   brew services start postgresql@15
   
   # Linux (Ubuntu/Debian)
   sudo apt update
   sudo apt install postgresql postgresql-contrib
   sudo systemctl start postgresql
   
   # Windows
   # Baixar instalador em: https://www.postgresql.org/download/windows/
   ```

2. **Criar banco de dados**:
   ```bash
   # Conectar ao PostgreSQL
   psql postgres
   
   # Criar banco
   CREATE DATABASE neves_capital;
   
   # Criar usuário (opcional)
   CREATE USER neves_user WITH PASSWORD 'sua_senha_segura';
   
   # Dar permissões
   GRANT ALL PRIVILEGES ON DATABASE neves_capital TO neves_user;
   
   # Sair
   \q
   ```

3. **Executar migrations** (criar tabelas):
   ```bash
   # Assumindo que você tem um arquivo SQL com as migrations
   psql -U postgres -d neves_capital -f backend/functions/sql/schema.sql
   ```

---

## ⚙️ Passo 2: Configurar Variáveis de Ambiente

1. **Editar arquivo `.env`** em `/functions/.env`:
   ```bash
   cd functions
   nano .env  # ou use seu editor preferido
   ```

2. **Configurar variáveis importantes**:
   ```env
   # PostgreSQL
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=neves_capital
   DB_USER=postgres
   DB_PASSWORD=sua_senha_aqui  # ⚠️ IMPORTANTE: Alterar!
   
   # Segurança
   API_KEY=neves-capital-api-key-prod-2024
   ENCRYPTION_KEY=0123...  # (já está configurada)
   
   # Servidor
   PORT=8080
   NODE_ENV=development
   ```

3. **Salvar e fechar** (Ctrl+O, Enter, Ctrl+X no nano)

---

## 📦 Passo 3: Instalar Dependências

```bash
cd functions

# Instalar pacotes do Node.js
npm install

# Aguardar instalação concluir...
```

---

## 🏗️ Passo 4: Compilar o Backend

```bash
# Compilar código TypeScript
npm run build

# Verificar se compilou com sucesso
# Deve criar uma pasta 'dist/' com os arquivos JS
```

---

## ▶️ Passo 5: Iniciar o Servidor

### Modo Desenvolvimento (com hot-reload)

```bash
npm run start:dev
```

### Modo Produção

```bash
npm run start:prod
```

---

## ✅ Passo 6: Verificar se está Funcionando

### 1. **Health Check**
Abra o navegador em: http://localhost:8080/health

Deve retornar:
```json
{
  "status": "ok",
  "timestamp": "2024-10-20T...",
  "uptime": 123.456
}
```

### 2. **Documentação Swagger**
Abra o navegador em: http://localhost:8080/api/docs

Você verá a documentação interativa da API.

### 3. **Testar Endpoint de Usuários**
```bash
# No terminal, testar registro
curl -X POST http://localhost:8080/api/users/register \
  -H "Content-Type: application/json" \
  -H "x-api-key: neves-capital-api-key-prod-2024" \
  -d '{
    "email": "teste@example.com",
    "password": "senha123",
    "fullName": "Teste Usuário",
    "cpf": "12345678900",
    "phone": "11999999999",
    "cep": "01310-100",
    "address": "Rua Teste",
    "neighborhood": "Centro",
    "city": "São Paulo",
    "state": "SP",
    "number": "123"
  }'
```

---

## 🔍 Logs do Terminal

Quando o backend estiver rodando, você verá:

```
🚀 API rodando na porta 8080
📚 Documentação: http://localhost:8080/api/docs
💚 Health check: http://localhost:8080/health
✅ Conectado ao PostgreSQL Cloud SQL
```

---

## 🐛 Solução de Problemas

### Erro: "Connection refused" (PostgreSQL)

**Problema**: Backend não consegue conectar ao PostgreSQL

**Solução**:
1. Verificar se PostgreSQL está rodando:
   ```bash
   # macOS
   brew services list | grep postgres
   
   # Linux
   sudo systemctl status postgresql
   ```

2. Verificar credenciais no `.env`:
   ```env
   DB_HOST=localhost
   DB_PORT=5432
   DB_USER=postgres
   DB_PASSWORD=sua_senha_correta
   ```

3. Testar conexão manual:
   ```bash
   psql -h localhost -U postgres -d neves_capital
   ```

---

### Erro: "Port 8080 already in use"

**Problema**: Porta 8080 já está em uso

**Solução**:
1. Encontrar processo usando a porta:
   ```bash
   lsof -i :8080
   ```

2. Matar o processo:
   ```bash
   kill -9 <PID>
   ```

3. Ou alterar a porta no `.env`:
   ```env
   PORT=8081
   ```

---

### Erro: "MODULE_NOT_FOUND"

**Problema**: Dependências não instaladas

**Solução**:
```bash
cd functions
rm -rf node_modules package-lock.json
npm install
npm run build
npm run start:dev
```

---

### Erro: "ECONNREFUSED" no Flutter

**Problema**: App Flutter não conecta ao backend

**Solução**:
1. **Backend rodando?** Verificar logs do terminal
2. **Porta correta?** Verificar se está na porta 8080
3. **URL correta no Flutter?**
   ```dart
   // lib/shared/services/database_service.dart
   static const String _baseUrl = 'http://localhost:8080/api';
   ```

---

## 📊 Comandos Úteis

```bash
# Ver logs em tempo real
npm run start:dev

# Rodar em modo debug
npm run start:debug

# Rodar testes
npm run test

# Ver cobertura de testes
npm run test:cov

# Formatar código
npm run format

# Verificar linting
npm run lint

# Compilar para produção
npm run build

# Iniciar produção
npm run start:prod
```

---

## 🔄 Fluxo de Cadastro (após correção)

Com a correção implementada, o fluxo agora é:

1. **Flutter** envia dados para **Backend NestJS**
2. **Backend** grava no **PostgreSQL** PRIMEIRO
3. **Backend** retorna `user_id` para Flutter
4. **Flutter** tenta gravar no **Firebase**
5. Se Firebase falhar → **Flutter** deleta do **PostgreSQL** (rollback)
6. ✅ Usuário só existe se estiver em **AMBOS** os bancos

---

## 📚 Documentação Relacionada

- [NestJS Documentation](https://docs.nestjs.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [API Reference (Swagger)](http://localhost:8080/api/docs)

---

## 🆘 Suporte

Se tiver dúvidas:

1. Verificar logs do terminal
2. Verificar arquivo `.env`
3. Testar health check: http://localhost:8080/health
4. Consultar documentação: http://localhost:8080/api/docs

---

**Desenvolvido para:** PagPag - Neves Capital  
**Data:** Outubro 2024  
**Versão:** 1.0.0

