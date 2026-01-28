#!/bin/bash

# Script para build do app Android em modo release
# Gera App Bundle (AAB) para upload no Google Play

set -e

echo "🚀 Iniciando build Android Release..."
echo ""

# Verificar se Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Erro: Flutter não encontrado."
    echo "   Instale o Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Verificar se está no diretório correto
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Erro: Execute este script na raiz do projeto Flutter"
    exit 1
fi

# Verificar se key.properties existe
if [ ! -f "android/key.properties" ]; then
    echo "⚠️  Aviso: android/key.properties não encontrado"
    echo "   Execute primeiro: ./scripts/setup-android-signing.sh"
    read -p "Continuar mesmo assim? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Limpar build anterior
echo "🧹 Limpando build anterior..."
flutter clean

# Obter dependências
echo "📦 Obtendo dependências..."
flutter pub get

# Verificar versão
echo ""
echo "📋 Versão atual:"
grep "^version:" pubspec.yaml || echo "   Não encontrado"

echo ""
read -p "Deseja continuar com o build? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Build cancelado."
    exit 0
fi

# Build App Bundle
echo ""
echo "🔨 Gerando App Bundle (AAB)..."
flutter build appbundle --release

# Verificar se o arquivo foi gerado
AAB_FILE="build/app/outputs/bundle/release/app-release.aab"

if [ -f "$AAB_FILE" ]; then
    FILE_SIZE=$(du -h "$AAB_FILE" | cut -f1)
    echo ""
    echo "✅ Build concluído com sucesso!"
    echo ""
    echo "📦 Arquivo gerado:"
    echo "   $AAB_FILE"
    echo "   Tamanho: $FILE_SIZE"
    echo ""
    echo "📤 Próximos passos:"
    echo "   1. Acesse: https://play.google.com/console"
    echo "   2. Vá em: Teste > Teste interno"
    echo "   3. Clique em: Criar nova versão"
    echo "   4. Faça upload do arquivo acima"
    echo ""
    
    # Perguntar se deseja abrir o diretório
    if command -v open &> /dev/null; then
        read -p "Deseja abrir o diretório do arquivo? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            open "$(dirname "$AAB_FILE")"
        fi
    fi
else
    echo "❌ Erro: Arquivo AAB não foi gerado"
    exit 1
fi


