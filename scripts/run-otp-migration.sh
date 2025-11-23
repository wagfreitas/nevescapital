#!/bin/bash
# Script para executar migration da tabela password_reset_otps

set -e

echo "📋 Executando migration: password_reset_otps"
echo ""

# Verificar se o Cloud SQL Proxy está rodando
if ! lsof -i :5432 > /dev/null 2>&1; then
    echo "❌ Cloud SQL Proxy não está rodando na porta 5432"
    echo ""
    echo "Execute em outro terminal:"
    echo "  cloud-sql-proxy pag-pag-dev:us-central1:pagpag-db-dev --port=5432"
    echo ""
    exit 1
fi

echo "✅ Cloud SQL Proxy está rodando"
echo ""

# Carregar variáveis de ambiente do .env
if [ -f "functions/.env" ]; then
    export $(grep -v '^#' functions/.env | grep -E '^DB_' | xargs)
    echo "📝 Variáveis de ambiente carregadas do .env"
else
    echo "⚠️  Arquivo functions/.env não encontrado"
    echo "   Você precisará informar a senha manualmente"
fi

echo ""
echo "🔐 Executando migration..."
echo ""

# Executar migration
psql -h 127.0.0.1 -p 5432 -U postgres -d pagpag \
  -f functions/src/database/migrations/002_create_password_reset_otps.sql

echo ""
echo "✅ Migration executada com sucesso!"
echo ""
echo "Verificando se a tabela foi criada..."
psql -h 127.0.0.1 -p 5432 -U postgres -d pagpag \
  -c "\dt password_reset_otps" || echo "⚠️  Erro ao verificar tabela"

