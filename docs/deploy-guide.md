# Deploy Guide - Cloud Functions + PostgreSQL

## 📋 **PRÉ-REQUISITOS:**

1. ✅ PostgreSQL criado e configurado no Cloud SQL
2. ✅ Tabela `users` criada
3. ✅ gcloud CLI instalado e configurado
4. ✅ Projeto GCP selecionado

---

## 🚀 **PASSO 1: Configurar Variáveis de Ambiente**

```bash
# Criar arquivo .env na pasta functions/
cd functions

# Copiar exemplo
cp .env.example .env

# Editar com suas credenciais
nano .env
```

**Configurações necessárias:**
```env
DB_HOST=34.95.242.60
DB_PORT=5432
DB_NAME=neves_capital
DB_USER=postgres
DB_PASSWORD=Jews726178*
INSTANCE_CONNECTION_NAME=apppagpag:us-central1:neves-capital-db
ENCRYPTION_KEY=neves-capital-secret-key-2024!
API_KEY=neves-capital-api-key-prod-2024
```

---

## 🚀 **PASSO 2: Instalar Dependências**

```bash
cd functions
npm install
```

---

## 🚀 **PASSO 3: Testar Localmente**

```bash
# Configurar proxy Cloud SQL (em terminal separado)
cloud-sql-proxy apppagpag:us-central1:neves-capital-db

# Rodar API localmente
npm start

# Testar endpoints
curl http://localhost:8080/health
```

---

## 🚀 **PASSO 4: Deploy para Cloud Functions**

```bash
# Deploy da função
gcloud functions deploy neves-capital-api \
  --gen2 \
  --runtime nodejs20 \
  --region us-central1 \
  --source . \
  --entry-point api \
  --trigger-http \
  --allow-unauthenticated \
  --set-env-vars DB_HOST=34.95.242.60,DB_PORT=5432,DB_NAME=neves_capital,DB_USER=postgres \
  --set-secrets DB_PASSWORD=database-password:latest,ENCRYPTION_KEY=encryption-key:latest,API_KEY=api-key:latest
```

---

## 🔐 **PASSO 5: Criar Secrets no GCP**

```bash
# Criar secret para senha do banco
echo -n "Jews726178*" | gcloud secrets create database-password --data-file=-

# Criar secret para chave de criptografia
echo -n "neves-capital-secret-key-2024!" | gcloud secrets create encryption-key --data-file=-

# Criar secret para API key
echo -n "neves-capital-api-key-prod-2024" | gcloud secrets create api-key --data-file=-

# Dar permissão para Cloud Functions acessar secrets
gcloud secrets add-iam-policy-binding database-password \
  --member=serviceAccount:apppagpag@appspot.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor

gcloud secrets add-iam-policy-binding encryption-key \
  --member=serviceAccount:apppagpag@appspot.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor

gcloud secrets add-iam-policy-binding api-key \
  --member=serviceAccount:apppagpag@appspot.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor
```

---

## 🧪 **PASSO 6: Testar Endpoints**

Depois do deploy, você receberá uma URL como:
```
https://us-central1-apppagpag.cloudfunctions.net/neves-capital-api
```

### **Testar Health Check:**
```bash
curl https://us-central1-apppagpag.cloudfunctions.net/neves-capital-api/health
```

### **Testar Registro:**
```bash
curl -X POST \
  https://us-central1-apppagpag.cloudfunctions.net/neves-capital-api/api/users/register \
  -H "x-api-key: neves-capital-api-key-prod-2024" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste@example.com",
    "password": "Teste123!",
    "fullName": "Teste Silva",
    "cpf": "12345678901",
    "phone": "11999999999",
    "cep": "01310100",
    "address": "Avenida Paulista",
    "neighborhood": "Bela Vista",
    "city": "São Paulo",
    "state": "SP",
    "number": "100",
    "complement": "Apto 10"
  }'
```

### **Testar Busca por CPF:**
```bash
curl -X GET \
  https://us-central1-apppagpag.cloudfunctions.net/neves-capital-api/api/users/cpf/12345678901 \
  -H "x-api-key: neves-capital-api-key-prod-2024"
```

### **Testar Verificação de Senha:**
```bash
curl -X POST \
  https://us-central1-apppagpag.cloudfunctions.net/neves-capital-api/api/users/verify-password \
  -H "x-api-key: neves-capital-api-key-prod-2024" \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "12345678901",
    "password": "Teste123!"
  }'
```

---

## 📱 **PASSO 7: Atualizar DatabaseService no Flutter**

Depois do deploy, atualize a URL base no Flutter:

```dart
// lib/shared/services/database_service.dart
static const String _baseUrl = 'https://us-central1-apppagpag.cloudfunctions.net/neves-capital-api/api';
static const String _apiKey = 'neves-capital-api-key-prod-2024';
```

---

## 🔧 **COMANDOS ÚTEIS:**

```bash
# Ver logs em tempo real
gcloud functions logs read neves-capital-api --region us-central1 --limit 50

# Atualizar função
gcloud functions deploy neves-capital-api --region us-central1

# Deletar função
gcloud functions delete neves-capital-api --region us-central1

# Listar funções
gcloud functions list --region us-central1

# Ver detalhes da função
gcloud functions describe neves-capital-api --region us-central1
```

---

## 🎯 **PRÓXIMOS PASSOS:**

1. ✅ Deploy da Cloud Function
2. ✅ Testar endpoints com Postman/Insomnia
3. ✅ Atualizar DatabaseService no Flutter
4. ✅ Testar fluxo completo de cadastro
5. ✅ Implementar login por CPF
6. ✅ Testar autenticação completa

**Pronto para deploy!** 🚀

