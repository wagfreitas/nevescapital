#!/bin/bash

# Script para iniciar o Cloud SQL Proxy
# Conecta o banco PostgreSQL do Cloud SQL localmente

set -e

echo "🔌 Iniciando Cloud SQL Proxy..."
echo ""

# Verificar se cloud-sql-proxy está instalado
if ! command -v cloud-sql-proxy &> /dev/null; then
  echo "❌ cloud-sql-proxy não encontrado"
  echo ""
  echo "Instale com:"
  echo "  brew install cloud-sql-proxy"
  echo ""
  echo "Ou baixe de: https://cloud.google.com/sql/docs/postgres/sql-proxy"
  exit 1
fi

# Verificar se a porta 5432 já está em uso
if lsof -i :5432 > /dev/null 2>&1; then
  echo "⚠️  Porta 5432 já está em uso"
  echo "   O proxy pode já estar rodando"
  echo ""
  read -p "Deseja continuar mesmo assim? (s/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    exit 1
  fi
fi

# Instância do Cloud SQL
INSTANCE="pag-pag-dev:us-central1:pagpag-db-dev"
PORT=5432

echo "📋 Configuração:"
echo "   Instância: $INSTANCE"
echo "   Porta: $PORT"
echo ""
echo "🚀 Iniciando proxy..."
echo "   Conecte-se em: postgresql://postgres@127.0.0.1:$PORT/pagpag"
echo ""
echo "⚠️  Mantenha este terminal aberto enquanto desenvolve"
echo "   Pressione Ctrl+C para parar"
echo ""

# Iniciar proxy
cloud-sql-proxy "$INSTANCE" --port=$PORT

