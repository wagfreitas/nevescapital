# Cloud Functions - Neves Capital API

## Estrutura de diretórios:
```
functions/
├── index.js                 # Funções principais
├── config/
│   └── database.js         # Configuração PostgreSQL
├── middleware/
│   └── auth.js             # Middleware de autenticação
├── routes/
│   ├── users.js            # Rotas de usuários
│   └── auth.js             # Rotas de autenticação
├── services/
│   ├── encryption.js       # Serviço de criptografia
│   └── validation.js       # Validação de dados
├── package.json
└── .env.example
```

## Endpoints a serem criados:

### **1. POST /api/users/register**
- Registra usuário no PostgreSQL
- Criptografa dados sensíveis (CPF, email, telefone, endereço)
- Hash de senha com bcrypt
- Retorna user_id

### **2. GET /api/users/cpf/:cpf**
- Busca usuário por CPF
- Retorna email para login no Firebase
- Descriptografa dados necessários

### **3. POST /api/users/verify-password**
- Verifica senha do usuário
- Compara hash bcrypt
- Retorna boolean

### **4. PUT /api/users/:id**
- Atualiza dados do usuário
- Criptografa novos dados sensíveis

### **5. DELETE /api/users/:id**
- Remove usuário do PostgreSQL
- Soft delete (marca como inativo)

## Segurança:

1. **Autenticação:** API Key + JWT
2. **Criptografia:** AES-256 para dados sensíveis
3. **Hash:** bcrypt para senhas
4. **CORS:** Apenas domínios autorizados
5. **Rate Limiting:** 100 req/min por IP
6. **SQL Injection:** Prepared statements
7. **HTTPS:** Obrigatório
8. **Logs:** Cloud Logging para auditoria

## Variáveis de ambiente necessárias:

```env
# PostgreSQL
DB_HOST=your-cloud-sql-instance
DB_PORT=5432
DB_NAME=neves_capital
DB_USER=postgres
DB_PASSWORD=your-secure-password

# Criptografia
ENCRYPTION_KEY=your-32-character-secret-key
JWT_SECRET=your-jwt-secret-key

# API
API_KEY=your-api-key-for-flutter-app

# Cloud SQL
INSTANCE_CONNECTION_NAME=project:region:instance
```

## Comandos para deploy:

```bash
# 1. Criar diretório functions
mkdir -p functions
cd functions

# 2. Inicializar projeto Node.js
npm init -y

# 3. Instalar dependências
npm install express pg bcrypt cors dotenv
npm install crypto-js jsonwebtoken helmet

# 4. Deploy
gcloud functions deploy neves-capital-api \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --region us-central1 \
  --set-env-vars DB_HOST=$DB_HOST,DB_NAME=$DB_NAME
```

## Próximos passos:

1. ✅ Confirmar conexão com PostgreSQL (já feito)
2. 🔄 Criar Cloud Functions
3. 🔄 Implementar endpoints
4. 🔄 Testar com Postman/Insomnia
5. 🔄 Atualizar DatabaseService no Flutter
6. 🔄 Testar fluxo completo
