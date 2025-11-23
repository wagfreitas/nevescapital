#!/bin/bash

# Script para executar o app Flutter
# Uso: ./flutter.sh [device-id]

set -e

echo "🚀 Iniciando Flutter app..."

# Verifica se Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Erro: Flutter não encontrado"
    echo "   Instale o Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Lista dispositivos disponíveis
echo ""
echo "📋 Dispositivos disponíveis:"
flutter devices

# Se um device-id foi fornecido, usa ele
if [ -n "$1" ]; then
    DEVICE_ID="$1"
    echo ""
    echo "🎯 Executando no dispositivo: $DEVICE_ID"
    flutter run -d "$DEVICE_ID"
else
    # Caso contrário, executa no primeiro dispositivo disponível
    echo ""
    echo "🎯 Executando no primeiro dispositivo disponível..."
    flutter run
fi

