#!/bin/bash

# Script para iniciar todo o ambiente de desenvolvimento
# Inicia: Cloud SQL Proxy + Backend NestJS

set -e

echo "🚀 Iniciando ambiente de desenvolvimento..."
echo ""

# Verificar se estamos no diretório correto
if [ ! -d "functions" ]; then
  echo "❌ Erro: Execute este script da raiz do projeto"
  exit 1
fi

# Verificar se cloud-sql-proxy está instalado
if ! command -v cloud-sql-proxy &> /dev/null; then
  echo "❌ cloud-sql-proxy não encontrado"
  echo ""
  echo "Instale com:"
  echo "  brew install cloud-sql-proxy"
  exit 1
fi

# Verificar se a porta 5432 já está em uso
if lsof -i :5432 > /dev/null 2>&1; then
  echo "✅ Cloud SQL Proxy já está rodando na porta 5432"
else
  echo "🔌 Iniciando Cloud SQL Proxy em background..."
  INSTANCE="pag-pag-dev:us-central1:pagpag-db-dev"
  cloud-sql-proxy "$INSTANCE" --port=5432 > /tmp/cloud-sql-proxy.log 2>&1 &
  PROXY_PID=$!
  echo "   PID: $PROXY_PID"
  
  # Aguardar alguns segundos para o proxy iniciar
  echo "   Aguardando proxy iniciar..."
  sleep 3
  
  # Verificar se o proxy está rodando
  if ! lsof -i :5432 > /dev/null 2>&1; then
    echo "❌ Erro ao iniciar Cloud SQL Proxy"
    echo "   Verifique os logs: /tmp/cloud-sql-proxy.log"
    exit 1
  fi
  echo "✅ Cloud SQL Proxy iniciado"
fi

echo ""

# Verificar se a porta 8080 já está em uso
if lsof -i :8080 > /dev/null 2>&1; then
  echo "⚠️  Porta 8080 já está em uso"
  echo "   O backend pode já estar rodando"
  echo ""
  read -p "Deseja continuar mesmo assim? (s/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    exit 1
  fi
fi

cd functions

# Verificar se node_modules existe
if [ ! -d "node_modules" ]; then
  echo "📦 Instalando dependências do backend..."
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
echo "⚠️  Mantenha este terminal aberto"
echo "   Pressione Ctrl+C para parar tudo"
echo ""

# Função para limpar processos ao sair
cleanup() {
  echo ""
  echo "🛑 Parando processos..."
  if [ ! -z "$PROXY_PID" ]; then
    kill $PROXY_PID 2>/dev/null || true
    echo "   Cloud SQL Proxy parado"
  fi
  exit 0
}

trap cleanup SIGINT SIGTERM

# Iniciar em modo desenvolvimento (watch mode)
npm run start:dev

