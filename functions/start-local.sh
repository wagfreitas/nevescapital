#!/bin/bash

# Script para iniciar o backend local
# Uso: ./start-local.sh

echo "🚀 Iniciando Backend Local - Neves Capital"
echo "=========================================="
echo ""

# Verificar se está na pasta functions
if [ ! -f "package.json" ]; then
    echo "❌ Erro: Execute este script na pasta functions/"
    exit 1
fi

# Verificar se .env existe
if [ ! -f ".env" ]; then
    echo "⚠️  Arquivo .env não encontrado!"
    echo "📝 Criando .env a partir de .env.example..."
    
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "✅ Arquivo .env criado. Configure as variáveis antes de continuar."
        echo ""
        echo "📋 Variáveis importantes:"
        echo "   - PORT=8080"
        echo "   - API_KEY=neves-capital-api-key-prod-2024"
        echo ""
        read -p "Pressione Enter para continuar após configurar o .env..."
    else
        echo "❌ Arquivo .env.example não encontrado!"
        exit 1
    fi
fi

# Verificar se node_modules existe
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependências..."
    npm install
    echo ""
fi

# Verificar se está rodando na porta 8080
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Porta 8080 já está em uso!"
    echo "   Deseja matar o processo? (s/n)"
    read -r response
    if [[ "$response" =~ ^([sS][iI][mM]|[sS])$ ]]; then
        echo "🛑 Matando processo na porta 8080..."
        lsof -ti:8080 | xargs kill -9
        sleep 2
    else
        echo "❌ Não é possível iniciar. Porta 8080 em uso."
        exit 1
    fi
fi

echo "✅ Iniciando servidor em modo desenvolvimento..."
echo "📍 URL: http://localhost:8080"
echo "📚 Swagger: http://localhost:8080/api/docs"
echo "💚 Health: http://localhost:8080/health"
echo ""
echo "Pressione Ctrl+C para parar o servidor"
echo ""

# Iniciar em modo desenvolvimento
npm run start:dev

