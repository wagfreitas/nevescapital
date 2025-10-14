#!/bin/bash

echo "🧪 TESTE COMPLETO - API NESTJS"
echo "=============================="
echo ""

API_URL="http://localhost:8080"
API_KEY="neves-capital-api-key-prod-2024"

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Health Check
echo -e "${BLUE}1️⃣  Health Check${NC}"
curl -s "$API_URL/health" | jq '.'
echo ""

# 2. Registrar usuário
echo -e "${BLUE}2️⃣  Registrar Usuário${NC}"
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/api/users/register" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "joao@example.com",
    "password": "Senha123!",
    "fullName": "João Silva",
    "cpf": "11122233344",
    "phone": "11987654321",
    "cep": "01310100",
    "address": "Av Paulista",
    "neighborhood": "Bela Vista",
    "city": "São Paulo",
    "state": "SP",
    "number": "1000"
  }')

echo "$REGISTER_RESPONSE" | jq '.'

if [[ $REGISTER_RESPONSE == *"success"* ]]; then
  echo -e "${GREEN}✅ Usuário registrado com sucesso!${NC}"
else
  echo -e "${RED}❌ Erro no registro${NC}"
fi
echo ""

# 3. Buscar por CPF
echo -e "${BLUE}3️⃣  Buscar Usuário por CPF${NC}"
FIND_RESPONSE=$(curl -s -X GET "$API_URL/api/users/cpf/11122233344" \
  -H "x-api-key: $API_KEY")

echo "$FIND_RESPONSE" | jq '.'

if [[ $FIND_RESPONSE == *"email"* ]]; then
  echo -e "${GREEN}✅ Usuário encontrado!${NC}"
else
  echo -e "${RED}❌ Usuário não encontrado${NC}"
fi
echo ""

# 4. Verificar senha correta
echo -e "${BLUE}4️⃣  Verificar Senha Correta${NC}"
VERIFY_CORRECT=$(curl -s -X POST "$API_URL/api/users/verify-password" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "11122233344",
    "password": "Senha123!"
  }')

echo "$VERIFY_CORRECT" | jq '.'

if [[ $VERIFY_CORRECT == *"true"* ]]; then
  echo -e "${GREEN}✅ Senha válida!${NC}"
else
  echo -e "${RED}❌ Senha inválida${NC}"
fi
echo ""

# 5. Verificar senha incorreta
echo -e "${BLUE}5️⃣  Verificar Senha Incorreta${NC}"
VERIFY_WRONG=$(curl -s -X POST "$API_URL/api/users/verify-password" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "11122233344",
    "password": "SenhaErrada123!"
  }')

echo "$VERIFY_WRONG" | jq '.'

if [[ $VERIFY_WRONG == *"false"* ]]; then
  echo -e "${GREEN}✅ Verificação correta (senha inválida)!${NC}"
else
  echo -e "${RED}❌ Erro na verificação${NC}"
fi
echo ""

# 6. Tentar registrar CPF duplicado
echo -e "${BLUE}6️⃣  Tentar Registrar CPF Duplicado${NC}"
DUPLICATE_RESPONSE=$(curl -s -X POST "$API_URL/api/users/register" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "outro@example.com",
    "password": "Senha123!",
    "fullName": "Outro Nome",
    "cpf": "11122233344"
  }')

echo "$DUPLICATE_RESPONSE" | jq '.'

if [[ $DUPLICATE_RESPONSE == *"já cadastrado"* ]]; then
  echo -e "${GREEN}✅ Validação de CPF duplicado funcionando!${NC}"
else
  echo -e "${RED}❌ Erro na validação de duplicidade${NC}"
fi
echo ""

echo "=============================="
echo -e "${GREEN}✅ TODOS OS TESTES CONCLUÍDOS!${NC}"
echo ""
echo "📚 Acesse a documentação Swagger:"
echo "   $API_URL/api/docs"
