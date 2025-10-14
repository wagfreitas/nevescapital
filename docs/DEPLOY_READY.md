# 🎉 API NESTJS PRONTA PARA DEPLOY!

## ✅ **STATUS:**

- ✅ TypeScript compilando sem erros
- ✅ Estrutura modular NestJS completa
- ✅ Validação automática com decorators
- ✅ Swagger configurado
- ✅ PostgreSQL connection pool
- ✅ Criptografia AES-256 + bcrypt
- ✅ API Key authentication
- ✅ Rate limiting
- ✅ Dockerfile otimizado
- ✅ Health checks

---

## 🚀 **COMANDOS PARA DEPLOY:**

### **1. Criar arquivo .env (local):**
```bash
cd functions
cat > .env << 'EOF'
DB_HOST=34.95.242.60
DB_PORT=5432
DB_NAME=neves_capital
DB_USER=postgres
DB_PASSWORD=Jews726178*
ENCRYPTION_KEY=neves-capital-secret-key-2024!
API_KEY=neves-capital-api-key-prod-2024
NODE_ENV=development
PORT=8080
EOF
```

### **2. Testar localmente:**
```bash
npm run start:dev

# Acessar:
# http://localhost:8080/health
# http://localhost:8080/api/docs (Swagger UI)
```

### **3. Criar secrets no GCP:**
```bash
# Senha do banco
echo -n "Jews726178*" | gcloud secrets create db-password \
  --data-file=- \
  --replication-policy="automatic"

# Chave de criptografia
echo -n "neves-capital-secret-key-2024!" | gcloud secrets create encryption-key \
  --data-file=- \
  --replication-policy="automatic"

# API Key
echo -n "neves-capital-api-key-prod-2024" | gcloud secrets create api-key \
  --data-file=- \
  --replication-policy="automatic"

# Dar permissões
PROJECT_NUMBER=$(gcloud projects describe apppagpag --format="value(projectNumber)")

for secret in db-password encryption-key api-key; do
  gcloud secrets add-iam-policy-binding $secret \
    --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
done
```

### **4. Build e deploy no Cloud Run:**
```bash
# Build da imagem
gcloud builds submit --tag gcr.io/apppagpag/neves-capital-api

# Deploy
gcloud run deploy neves-capital-api \
  --image gcr.io/apppagpag/neves-capital-api \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --min-instances 1 \
  --max-instances 10 \
  --memory 512Mi \
  --cpu 1 \
  --timeout 60 \
  --set-env-vars "DB_HOST=34.95.242.60,DB_PORT=5432,DB_NAME=neves_capital,DB_USER=postgres,NODE_ENV=production" \
  --set-secrets "DB_PASSWORD=db-password:latest,ENCRYPTION_KEY=encryption-key:latest,API_KEY=api-key:latest"
```

### **5. Obter URL da API:**
```bash
gcloud run services describe neves-capital-api \
  --platform managed \
  --region us-central1 \
  --format 'value(status.url)'

# Salvar URL
export API_URL=$(gcloud run services describe neves-capital-api \
  --platform managed \
  --region us-central1 \
  --format 'value(status.url)')

echo "API URL: $API_URL"
echo "Swagger: $API_URL/api/docs"
```

---

## 🧪 **TESTAR ENDPOINTS:**

### **1. Health Check:**
```bash
curl $API_URL/health
```

**Resposta esperada:**
```json
{
  "status": "OK",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "service": "Neves Capital API",
  "version": "1.0.0"
}
```

### **2. Registro de Usuário:**
```bash
curl -X POST $API_URL/api/users/register \
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

**Resposta esperada:**
```json
{
  "success": true,
  "user_id": "uuid-here",
  "created_at": "2024-01-01T00:00:00.000Z"
}
```

### **3. Buscar por CPF:**
```bash
curl -X GET $API_URL/api/users/cpf/12345678901 \
  -H "x-api-key: neves-capital-api-key-prod-2024"
```

**Resposta esperada:**
```json
{
  "id": "uuid",
  "email": "teste@example.com",
  "full_name": "Teste Silva",
  "cpf": "12345678901",
  "phone": "11999999999",
  "cep": "01310100",
  "address": "Avenida Paulista",
  "neighborhood": "Bela Vista",
  "city": "São Paulo",
  "state": "SP",
  "number": "100",
  "complement": "Apto 10",
  "created_at": "2024-01-01T00:00:00.000Z"
}
```

### **4. Verificar Senha:**
```bash
curl -X POST $API_URL/api/users/verify-password \
  -H "x-api-key: neves-capital-api-key-prod-2024" \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "12345678901",
    "password": "Teste123!"
  }'
```

**Resposta esperada:**
```json
{
  "valid": true
}
```

---

## 📱 **ATUALIZAR FLUTTER:**

Depois do deploy, atualizar `lib/shared/services/database_service.dart`:

```dart
class DatabaseService {
  static const String _baseUrl = 'https://neves-capital-api-xxxx.a.run.app/api';
  static const String _apiKey = 'neves-capital-api-key-prod-2024';

  static Future<Map<String, dynamic>> createUser({...}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/register'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
      },
      body: jsonEncode({...}),
    );
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao criar usuário: ${response.statusCode}');
    }
  }
}
```

---

## 📊 **MONITORAMENTO:**

### **Logs em tempo real:**
```bash
gcloud run services logs read neves-capital-api \
  --platform managed \
  --region us-central1 \
  --limit 50 \
  --follow
```

### **Métricas:**
```bash
gcloud run services describe neves-capital-api \
  --platform managed \
  --region us-central1
```

### **Cloud Console:**
```
https://console.cloud.google.com/run/detail/us-central1/neves-capital-api
```

---

## 💰 **ESTIMATIVA DE CUSTO:**

**Cenário: 1000 usuários/dia, 5000 requests/dia**

```
Cloud Run:
├─ Min instances (1): $10-12/mês
├─ CPU time: $4-5/mês
├─ Memory: $0.50/mês
├─ Requests: $2/mês (dentro do free tier)
└─ Total: ~$15-20/mês
```

**Benefícios:**
- ✅ Zero cold starts
- ✅ Performance consistente
- ✅ Escalabilidade automática
- ✅ Alta disponibilidade

---

## ✅ **CHECKLIST PRE-DEPLOY:**

- [x] TypeScript compilando sem erros
- [x] Estrutura NestJS completa
- [x] Validação automática
- [x] Swagger configurado
- [x] Dockerfile otimizado
- [ ] .env criado localmente
- [ ] Testado localmente
- [ ] Secrets criados no GCP
- [ ] Build da imagem OK
- [ ] Deploy no Cloud Run OK
- [ ] Endpoints testados
- [ ] Flutter atualizado com URL
- [ ] Fluxo completo testado

---

## 🎯 **PRÓXIMOS PASSOS:**

1. **Criar .env** e testar localmente (5 min)
2. **Criar secrets** no GCP (5 min)
3. **Deploy** no Cloud Run (10 min)
4. **Testar** endpoints (5 min)
5. **Atualizar** Flutter (5 min)
6. **Testar** fluxo completo (10 min)

**Total: ~40 minutos para produção completa!** 🚀

---

**Está tudo pronto! Quer fazer o deploy agora?**

