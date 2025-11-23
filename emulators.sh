#!/bin/bash

# Script para iniciar o emulador do iOS
# Uso: ./emulators.sh [device-name]

set -e

echo "📱 Iniciando emulador iOS..."

# Lista dispositivos disponíveis
echo ""
echo "📋 Dispositivos disponíveis:"
xcrun simctl list devices available | grep -E "iPhone|iPad" | head -10

# Se um nome de dispositivo foi fornecido, usa ele
if [ -n "$1" ]; then
    DEVICE_NAME="$1"
    echo ""
    echo "🎯 Iniciando dispositivo: $DEVICE_NAME"
    open -a Simulator
    xcrun simctl boot "$DEVICE_NAME" 2>/dev/null || echo "⚠️  Dispositivo pode já estar em execução"
else
    # Caso contrário, tenta iniciar o primeiro iPhone disponível
    echo ""
    echo "🎯 Iniciando primeiro iPhone disponível..."
    open -a Simulator
    
    # Aguarda um pouco para o Simulator abrir
    sleep 2
    
    # Tenta iniciar o primeiro iPhone disponível
    FIRST_IPHONE=$(xcrun simctl list devices available | grep -i "iPhone" | head -1 | sed -E 's/.*\(([^)]+)\).*/\1/')
    
    if [ -n "$FIRST_IPHONE" ]; then
        echo "📱 Iniciando: $FIRST_IPHONE"
        xcrun simctl boot "$FIRST_IPHONE" 2>/dev/null || echo "✅ Simulador já está em execução"
    else
        echo "⚠️  Nenhum iPhone disponível encontrado"
    fi
fi

echo ""
echo "✅ Simulador iOS iniciado!"
echo ""
echo "💡 Dica: Para ver todos os dispositivos disponíveis, use:"
echo "   xcrun simctl list devices available"

