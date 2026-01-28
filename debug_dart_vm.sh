#!/bin/bash

# Script para diagnosticar problema do Dart VM Service
# Execute: bash debug_dart_vm.sh

echo "🔍 Diagnosticando problema do Dart VM Service..."
echo ""

echo "1️⃣ Verificando se o dispositivo está conectado..."
flutter devices

echo ""
echo "2️⃣ Limpando build anterior..."
flutter clean

echo ""
echo "3️⃣ Obtendo dependências..."
flutter pub get

echo ""
echo "4️⃣ Verificando configuração do iOS..."
cd ios
pod --version
pod repo list

echo ""
echo "5️⃣ Tentando executar com mais verbosidade..."
cd ..
echo ""
echo "Execute manualmente com logs detalhados:"
echo "  flutter run -v"
echo ""
echo "Ou tente executar em modo release (sem debugger):"
echo "  flutter run --release"

