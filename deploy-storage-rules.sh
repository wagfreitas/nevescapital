#!/bin/bash

# Script para fazer deploy das regras do Firebase Storage
# Uso: ./deploy-storage-rules.sh

echo "🔥 Fazendo deploy das regras do Firebase Storage..."

# Verificar se está autenticado
if ! firebase projects:list &>/dev/null; then
  echo "❌ Você precisa estar autenticado no Firebase."
  echo "Execute: firebase login"
  exit 1
fi

# Fazer deploy apenas das regras do Storage
firebase deploy --only storage

if [ $? -eq 0 ]; then
  echo "✅ Regras do Firebase Storage deployadas com sucesso!"
else
  echo "❌ Erro ao fazer deploy das regras."
  exit 1
fi

