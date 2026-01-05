#!/bin/bash

echo "🔧 Atualizando API_BASE_URL para IP local..."
echo ""

# Obter IP local
LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

if [ -z "$LOCAL_IP" ]; then
    echo "❌ Não foi possível detectar o IP local"
    exit 1
fi

echo "📍 IP detectado: $LOCAL_IP"
echo ""

# Atualizar .env
if [ -f ".env" ]; then
    # Backup
    cp .env .env.backup
    
    # Atualizar API_BASE_URL
    if grep -q "API_BASE_URL=" .env; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|API_BASE_URL=.*|API_BASE_URL=http://$LOCAL_IP:8080|" .env
        else
            # Linux
            sed -i "s|API_BASE_URL=.*|API_BASE_URL=http://$LOCAL_IP:8080|" .env
        fi
        echo "✅ .env atualizado: API_BASE_URL=http://$LOCAL_IP:8080"
    else
        echo "API_BASE_URL=http://$LOCAL_IP:8080" >> .env
        echo "✅ API_BASE_URL adicionado ao .env"
    fi
else
    echo "❌ Arquivo .env não encontrado"
    exit 1
fi

echo ""
echo "📋 Próximos passos:"
echo "   1. Reinicie o app Flutter"
echo "   2. Teste novamente o login"
echo ""

