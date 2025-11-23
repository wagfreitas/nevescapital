#!/bin/bash

# Script para iniciar o backend NestJS localmente
# Requer: Cloud SQL Proxy rodando na porta 5432

set -e

echo "🚀 Iniciando backend NestJS localmente..."
echo ""

# Verificar se estamos no diretório correto
if [ ! -d "functions" ]; then
  echo "❌ Erro: Diretório 'functions' não encontrado"
  echo "   Execute este script da raiz do projeto"
  exit 1
fi

# Verificar se o Cloud SQL Proxy está rodando
if ! lsof -i :5432 > /dev/null 2>&1; then
  echo "⚠️  Cloud SQL Proxy não está rodando na porta 5432"
  echo ""
  echo "Execute em outro terminal:"
  echo "  cloud-sql-proxy pag-pag-dev:us-central1:pagpag-db-dev --port=5432"
  echo ""
  echo "Ou pressione Enter para continuar sem verificação..."
  read -r
fi

cd functions

# Verificar se node_modules existe
if [ ! -d "node_modules" ]; then
  echo "📦 Instalando dependências..."
  npm install
fi

# Carregar variáveis de ambiente se existir .env
if [ -f ".env" ]; then
  echo "📝 Carregando variáveis de ambiente do .env"
  export $(grep -v '^#' .env | xargs)
else
  echo "⚠️  Arquivo .env não encontrado"
  echo "   Certifique-se de ter configurado as variáveis de ambiente"
fi

echo ""
echo "🔧 Iniciando servidor NestJS em modo desenvolvimento..."
echo "   URL: http://localhost:8080"
echo "   Docs: http://localhost:8080/api/docs"
echo ""

# Iniciar em modo desenvolvimento (watch mode)
npm run start:dev

