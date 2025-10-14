# 🚀 Deploy Guide - Cloud Run (RECOMENDADO)

## 📋 **POR QUE CLOUD RUN É MELHOR:**

### **Vantagens sobre Cloud Functions:**

1. **✅ Melhor para PostgreSQL:**
   - Pool de conexões persistente
   - Menos cold starts com min instances
   - Melhor gerenciamento de recursos

2. **✅ Performance Superior:**
   - Cold start: 0.5-1s (vs 1-3s Functions)
   - Instâncias warm disponíveis
   - Controle fino de recursos

3. **✅ Mais Flexível:**
   - Suporte a WebSockets
   - Background jobs
   - Timeout até 60 minutos

4. **✅ Portabilidade:**
   - Container Docker padrão
   - Roda em qualquer cloud
   - Fácil teste local

5. **✅ Custo Similar:**
   - Free tier: 2M requests/mês
   - Pay-per-use após free tier
   - Mais eficiente com volume

---

## 🚀 **PASSO 1: Preparar Ambiente**

```bash
# Navegar para pasta functions
cd functions

# Verificar se Docker está instalado
docker --version

# Verificar se gcloud está configurado
gcloud config list
```

---

## 🚀 **PASSO 2: Criar Secrets no Google Cloud**

```bash
# 1. Criar secret para senha do banco
echo -n "Jews726178*" | gcloud secrets create db-password \
  --data-file=- \
  --replication-policy="automatic"

# 2. Criar secret para chave de criptografia
echo -n "neves-capital-secret-key-2024!" | gcloud secrets create encryption-key \
  --data-file=- \
  --replication-policy="automatic"

# 3. Criar secret para API key
echo -n "neves-capital-api-key-prod-2024" | gcloud secrets create api-key \
  --data-file=- \
  --replication-policy="automatic"

# 4. Dar permissões para Cloud Run acessar secrets
PROJECT_NUMBER=$(gcloud projects describe apppagpag --format="value(projectNumber)")

gcloud secrets add-iam-policy-binding db-password \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding encryption-key \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding api-key \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

---

## 🚀 **PASSO 3: Testar Localmente com Docker**

```bash
# Construir imagem
docker build -t neves-capital-api .

# Rodar container local
docker run -p 8080:8080 \
  -e DB_HOST=34.95.242.60 \
  -e DB_PORT=5432 \
  -e DB_NAME=neves_capital \
  -e DB_USER=postgres \
  -e DB_PASSWORD=Jews726178* \
  -e ENCRYPTION_KEY=neves-capital-secret-key-2024! \
  -e API_KEY=neves-capital-api-key-prod-2024 \
  -e NODE_ENV=production \
  neves-capital-api

# Testar health check
curl http://localhost:8080/health
```

---

## 🚀 **PASSO 4: Deploy para Cloud Run**

```bash
# Build e push para Container Registry
gcloud builds submit --tag gcr.io/apppagpag/neves-capital-api

# Deploy no Cloud Run
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

**Parâmetros Explicados:**
- `--min-instances 1`: Mantém 1 instância sempre ativa (elimina cold starts)
- `--max-instances 10`: Escala até 10 instâncias sob demanda
- `--memory 512Mi`: Memória suficiente para Node.js + pool de conexões
- `--cpu 1`: 1 vCPU (suficiente para sua API)
- `--timeout 60`: Timeout de 60 segundos (padrão é 5 minutos)
- `--allow-unauthenticated`: API pública (autenticação por API Key)

---

## 🚀 **PASSO 5: Obter URL da API**

```bash
# URL será algo como:
# https://neves-capital-api-xxxxxxxxxxxx-uc.a.run.app

# Salvar URL
export API_URL=$(gcloud run services describe neves-capital-api \
  --platform managed \
  --region us-central1 \
  --format 'value(status.url)')

echo "API URL: $API_URL"
```

---

## 🧪 **PASSO 6: Testar Endpoints**

```bash
# 1. Health Check
curl $API_URL/health

# 2. Testar registro
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

# 3. Testar busca por CPF
curl -X GET $API_URL/api/users/cpf/12345678901 \
  -H "x-api-key: neves-capital-api-key-prod-2024"

# 4. Testar verificação de senha
curl -X POST $API_URL/api/users/verify-password \
  -H "x-api-key: neves-capital-api-key-prod-2024" \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "12345678901",
    "password": "Teste123!"
  }'
```

---

## 📊 **PASSO 7: Monitoramento**

```bash
# Ver logs em tempo real
gcloud run services logs read neves-capital-api \
  --platform managed \
  --region us-central1 \
  --limit 50 \
  --follow

# Ver métricas
gcloud run services describe neves-capital-api \
  --platform managed \
  --region us-central1
```

---

## 💰 **ESTIMATIVA DE CUSTOS:**

### **Cenário: 1000 usuários/dia, 5000 requests/dia**

```
Cloud Run Pricing:
├─ CPU: $0.00002400 por vCPU-segundo
├─ Memory: $0.00000250 por GiB-segundo
├─ Requests: $0.40 por milhão

Cálculo Mensal (30 dias):
├─ Requests: 150,000 requests/mês
├─ CPU Time: ~50 horas/mês
├─ Memory: 512MB

Custo Estimado:
├─ Free Tier: 2M requests/mês = $0
├─ CPU: $4.32/mês
├─ Memory: $0.38/mês
├─ Total: ~$5-7/mês
```

**Com min-instances = 1:**
- Custo adicional: ~$10-12/mês
- **Benefício:** Zero cold starts, sempre disponível
- **Total:** ~$15-20/mês

---

## 🔧 **COMANDOS ÚTEIS:**

```bash
# Atualizar serviço
gcloud run deploy neves-capital-api \
  --image gcr.io/apppagpag/neves-capital-api \
  --platform managed \
  --region us-central1

# Ver detalhes
gcloud run services describe neves-capital-api \
  --platform managed \
  --region us-central1

# Deletar serviço
gcloud run services delete neves-capital-api \
  --platform managed \
  --region us-central1

# Listar serviços
gcloud run services list --platform managed

# Ver revisões
gcloud run revisions list \
  --service neves-capital-api \
  --platform managed \
  --region us-central1

# Rollback para revisão anterior
gcloud run services update-traffic neves-capital-api \
  --to-revisions REVISION-NAME=100 \
  --platform managed \
  --region us-central1
```

---

## ✅ **CHECKLIST DE DEPLOY:**

- [ ] Docker instalado e funcionando
- [ ] gcloud CLI configurado
- [ ] Secrets criados no GCP
- [ ] Permissions configuradas
- [ ] Dockerfile criado
- [ ] .dockerignore configurado
- [ ] Teste local com Docker OK
- [ ] Build da imagem OK
- [ ] Deploy no Cloud Run OK
- [ ] Testes dos endpoints OK
- [ ] URL da API obtida
- [ ] Atualizar Flutter com nova URL

---

## 🎯 **VANTAGENS EM PRODUÇÃO:**

1. **Zero Downtime Deployments:**
   - Cloud Run gerencia tráfego entre versões
   - Rollback instantâneo se necessário

2. **Auto-Scaling Inteligente:**
   - Escala baseado em CPU, memória e requests
   - Min instances = 1 garante disponibilidade

3. **Observabilidade:**
   - Logs automáticos no Cloud Logging
   - Métricas no Cloud Monitoring
   - Traces distribuídos

4. **Segurança:**
   - HTTPS automático
   - Secrets gerenciados pelo Secret Manager
   - Isolamento de container

**Cloud Run é claramente superior para sua arquitetura!** 🚀

