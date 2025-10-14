#!/bin/bash

echo "🧪 Testando API NestJS - Neves Capital"
echo "======================================="
echo ""

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

API_URL="http://localhost:8080"
API_KEY="neves-capital-api-key-prod-2024"

# 1. Health Check
echo "1️⃣  Testando Health Check..."
HEALTH=$(curl -s "$API_URL/health")
if [[ $HEALTH == *"OK"* ]]; then
  echo -e "${GREEN}✅ Health check OK${NC}"
  echo "$HEALTH" | jq '.'
else
  echo -e "${RED}❌ Health check falhou${NC}"
  echo "$HEALTH"
fi
echo ""

# 2. Teste sem API Key
echo "2️⃣  Testando sem API Key (deve falhar)..."
NO_KEY=$(curl -s -X POST "$API_URL/api/users/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com"}')
if [[ $NO_KEY == *"API Key não fornecida"* ]]; then
  echo -e "${GREEN}✅ Autenticação funcionando${NC}"
else
  echo -e "${RED}❌ Problema na autenticação${NC}"
fi
echo "$NO_KEY" | jq '.'
echo ""

# 3. Swagger
echo "3️⃣  Documentação Swagger..."
echo -e "${YELLOW}📚 Acesse: $API_URL/api/docs${NC}"
echo ""

# 4. Registro de usuário
echo "4️⃣  Testando registro de usuário..."
REGISTER=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/users/register" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste'$(date +%s)'@example.com",
    "password": "Teste123!",
    "fullName": "João Silva Santos",
    "cpf": "1234567890'$(shuf -i 0-9 -n 1)'",
    "phone": "11999999999",
    "cep": "01310100",
    "address": "Avenida Paulista",
    "neighborhood": "Bela Vista",
    "city": "São Paulo",
    "state": "SP",
    "number": "100",
    "complement": "Apto 10"
  }')

HTTP_CODE=$(echo "$REGISTER" | tail -n1)
BODY=$(echo "$REGISTER" | head -n-1)

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.'

if [[ $HTTP_CODE == "201" ]]; then
  echo -e "${GREEN}✅ Usuário criado com sucesso!${NC}"
  USER_ID=$(echo "$BODY" | jq -r '.user_id')
  echo "User ID: $USER_ID"
elif [[ $HTTP_CODE == "409" ]]; then
  echo -e "${YELLOW}⚠️  CPF ou email já cadastrado${NC}"
elif [[ $HTTP_CODE == "500" ]]; then
  echo -e "${RED}❌ Erro interno do servidor${NC}"
  echo "Verifique os logs do servidor para mais detalhes"
else
  echo -e "${RED}❌ Erro: HTTP $HTTP_CODE${NC}"
fi
echo ""

echo "======================================="
echo "✅ Testes concluídos!"

