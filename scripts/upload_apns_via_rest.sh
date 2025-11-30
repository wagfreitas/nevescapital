#!/bin/bash

# Script para fazer upload de APNs via API REST do Firebase
# Requisitos: gcloud CLI instalada e autenticada

set -e

echo "🔥 Upload de APNs Key via API REST"
echo ""

# Verificar argumentos
if [ "$#" -ne 3 ]; then
    echo "❌ Uso: $0 <caminho-para-apns-key.p8> <key-id> <team-id>"
    echo ""
    echo "Exemplo:"
    echo "  $0 ./AuthKey_ABC123.p8 ABC123 3T4MG5QU7G"
    exit 1
fi

APNS_KEY_PATH=$1
KEY_ID=$2
TEAM_ID=$3

# Verificar arquivo
if [ ! -f "$APNS_KEY_PATH" ]; then
    echo "❌ APNs Key não encontrado: $APNS_KEY_PATH"
    exit 1
fi

# Verificar autenticação gcloud
if ! gcloud auth print-access-token &> /dev/null; then
    echo "⚠️  gcloud não autenticado"
    echo "Execute: gcloud auth login"
    exit 1
fi

echo "📋 Configuração:"
echo "   Projeto: pagpagapp"
echo "   Bundle ID: com.nevescapital.pagpag"
echo "   Key ID: $KEY_ID"
echo "   Team ID: $TEAM_ID"
echo ""

# Ler conteúdo da chave (escapar newlines)
APNS_KEY_CONTENT=$(cat "$APNS_KEY_PATH" | sed ':a;N;$!ba;s/\n/\\n/g')

# Obter token
TOKEN=$(gcloud auth print-access-token)

echo "🚀 Enviando configuração para Firebase..."
echo ""

# Fazer upload via API REST
RESPONSE=$(curl -s -X PATCH \
  "https://fcm.googleapis.com/v1/projects/pagpagapp/apnsConfig" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"keyId\": \"$KEY_ID\",
    \"teamId\": \"$TEAM_ID\",
    \"privateKey\": \"$APNS_KEY_CONTENT\"
  }")

if echo "$RESPONSE" | grep -q "error"; then
    echo "❌ Erro ao fazer upload:"
    echo "$RESPONSE" | jq '.'
    exit 1
fi

echo "✅ APNs Key configurado com sucesso!"
echo ""
echo "📋 Resposta:"
echo "$RESPONSE" | jq '.'
echo ""
echo "🎯 Próximos passos:"
echo "1. Habilite Phone Authentication no Firebase Console"
echo "2. Execute: ./fix_firebase_phone_auth.sh"
echo "3. Teste o login por telefone no app"

