#!/bin/bash

# Script para verificar logs do dispositivo iOS e diagnosticar problemas
# Execute: bash check_ios_logs.sh

echo "📱 Verificando logs do dispositivo iOS..."
echo ""

# Listar dispositivos conectados
echo "1️⃣ Dispositivos conectados:"
xcrun xctrace list devices

echo ""
echo "2️⃣ Verificando logs do dispositivo (últimos 50 linhas)..."
echo "   (Pressione Ctrl+C para parar)"
echo ""

# Capturar logs do dispositivo
xcrun simctl spawn booted log stream --level=debug --predicate 'processImagePath contains "Runner"' --style=compact 2>/dev/null || \
idevicesyslog 2>/dev/null || \
echo "⚠️ Não foi possível acessar logs do dispositivo. Tente:"
echo "   - Conectar dispositivo via USB"
echo "   - Verificar se está confiável no dispositivo"
echo "   - Executar: idevice_id -l"

echo ""
echo "3️⃣ Tentando executar app em modo release (sem debugger):"
echo "   flutter run --release"

