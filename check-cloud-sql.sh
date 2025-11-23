#!/bin/bash
# Script para verificar o estado do Cloud SQL e diagnosticar problemas

set -e

echo "🔍 Verificando estado do Cloud SQL..."
echo ""

PROJECT_ID="pag-pag-dev"
INSTANCE_NAME="pagpag-db-dev"
CONNECTION_NAME="$PROJECT_ID:us-central1:$INSTANCE_NAME"

# Verificar projeto atual
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
  echo "⚠️  Projeto atual: $CURRENT_PROJECT"
  echo "   Configurando para: $PROJECT_ID"
  gcloud config set project "$PROJECT_ID"
fi

echo "📋 Informações da Instância:"
echo "   Projeto: $PROJECT_ID"
echo "   Instância: $INSTANCE_NAME"
echo "   Connection Name: $CONNECTION_NAME"
echo ""

# Verificar estado da instância
echo "🔍 Verificando estado da instância..."
INSTANCE_STATE=$(gcloud sql instances describe "$INSTANCE_NAME" --format="get(state)" 2>&1 || echo "ERROR")

if [ "$INSTANCE_STATE" = "ERROR" ]; then
  echo "❌ Erro ao verificar instância. Verificando autenticação..."
  if ! gcloud auth application-default print-access-token > /dev/null 2>&1; then
    echo "❌ Não autenticado. Execute:"
    echo "   gcloud auth application-default login"
    exit 1
  fi
  echo "✅ Autenticado"
  echo ""
  echo "Tentando novamente..."
  INSTANCE_STATE=$(gcloud sql instances describe "$INSTANCE_NAME" --format="get(state)" 2>&1 || echo "ERROR")
fi

if [ "$INSTANCE_STATE" = "RUNNABLE" ]; then
  echo "✅ Instância está RODANDO (RUNNABLE)"
elif [ "$INSTANCE_STATE" = "SUSPENDED" ]; then
  echo "⚠️  Instância está SUSPENSA"
  echo "   Execute: gcloud sql instances patch $INSTANCE_NAME --activation-policy=ALWAYS"
elif [ "$INSTANCE_STATE" = "PENDING_CREATE" ] || [ "$INSTANCE_STATE" = "PENDING_UPDATE" ]; then
  echo "⏳ Instância está em operação pendente: $INSTANCE_STATE"
  echo "   Aguarde alguns minutos e tente novamente"
elif [ "$INSTANCE_STATE" = "MAINTENANCE" ]; then
  echo "🔧 Instância está em MANUTENÇÃO"
  echo "   Aguarde a conclusão da manutenção"
else
  echo "⚠️  Estado desconhecido: $INSTANCE_STATE"
fi

echo ""

# Verificar se o proxy está rodando
echo "🔍 Verificando Cloud SQL Proxy..."
if lsof -i :5432 > /dev/null 2>&1; then
  PROXY_PID=$(lsof -t -i :5432 | head -1)
  echo "✅ Proxy está rodando (PID: $PROXY_PID)"
  
  # Verificar se é o processo correto
  if ps -p "$PROXY_PID" | grep -q cloud-sql-proxy; then
    echo "✅ Processo correto: cloud-sql-proxy"
  else
    echo "⚠️  Outro processo está usando a porta 5432"
    echo "   PID $PROXY_PID: $(ps -p $PROXY_PID -o comm=)"
  fi
else
  echo "❌ Proxy NÃO está rodando"
  echo "   Execute: ./start-proxy.sh"
fi

echo ""

# Verificar conexão
echo "🔍 Testando conexão..."
if psql -h 127.0.0.1 -p 5432 -U postgres -d pagpag -c "SELECT 1;" > /dev/null 2>&1; then
  echo "✅ Conexão com banco de dados OK"
else
  echo "❌ Não foi possível conectar ao banco de dados"
  echo ""
  echo "Possíveis causas:"
  echo "1. Instância não está rodando (verifique acima)"
  echo "2. Proxy não está rodando (verifique acima)"
  echo "3. Credenciais incorretas"
  echo "4. Instância em manutenção ou operação pendente"
fi

echo ""
echo "📝 Próximos passos:"
echo ""

if [ "$INSTANCE_STATE" != "RUNNABLE" ]; then
  echo "1. Aguarde alguns minutos se a instância está em operação pendente"
  echo "2. Se estiver SUSPENSA, execute:"
  echo "   gcloud sql instances patch $INSTANCE_NAME --activation-policy=ALWAYS"
  echo "3. Reinicie o proxy após a instância estar rodando:"
  echo "   killall cloud-sql-proxy && ./start-proxy.sh"
else
  echo "1. Se o proxy não está rodando, execute: ./start-proxy.sh"
  echo "2. Se o proxy está rodando mas não conecta, reinicie:"
  echo "   killall cloud-sql-proxy && ./start-proxy.sh"
fi

