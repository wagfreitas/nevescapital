#!/bin/bash

# Script para gerar keystore para assinatura do app Android
# Execute este script apenas UMA VEZ para gerar o keystore

set -e

echo "🔐 Gerando keystore para assinatura do app Android..."
echo ""

# Verificar se keytool está disponível
if ! command -v keytool &> /dev/null; then
    echo "❌ Erro: keytool não encontrado."
    echo "   Instale o Java JDK para usar o keytool."
    exit 1
fi

# Diretório do keystore
KEYSTORE_DIR="$HOME"
KEYSTORE_FILE="$KEYSTORE_DIR/upload-keystore.jks"

# Verificar se keystore já existe
if [ -f "$KEYSTORE_FILE" ]; then
    echo "⚠️  ATENÇÃO: Keystore já existe em: $KEYSTORE_FILE"
    read -p "Deseja sobrescrever? (NÃO RECOMENDADO) [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operação cancelada."
        exit 0
    fi
fi

echo "📝 Preencha as informações solicitadas:"
echo ""

# Gerar keystore
keytool -genkey -v -keystore "$KEYSTORE_FILE" \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias upload

echo ""
echo "✅ Keystore gerado com sucesso!"
echo ""
echo "📍 Localização: $KEYSTORE_FILE"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   1. Guarde a senha em local seguro!"
echo "   2. Faça backup do keystore!"
echo "   3. NUNCA compartilhe o keystore ou senha!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Execute: ./scripts/setup-android-signing.sh"
echo "   2. Configure o arquivo android/key.properties com as senhas"
echo ""


