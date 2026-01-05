#!/bin/bash

# Script para fazer deploy das regras do Firestore
# Uso: ./deploy-firestore-rules.sh

echo "🔥 Fazendo deploy das regras do Firestore..."

# Verificar se está autenticado
if ! firebase projects:list &>/dev/null; then
  echo "❌ Você precisa estar autenticado no Firebase."
  echo "Execute: firebase login"
  exit 1
fi

# Fazer deploy apenas das regras
firebase deploy --only firestore:rules

if [ $? -eq 0 ]; then
  echo "✅ Regras do Firestore deployadas com sucesso!"
else
  echo "❌ Erro ao fazer deploy das regras."
  exit 1
fi

