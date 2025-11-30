#!/bin/bash

# Script para limpar e rebuild após correções do Firebase Phone Auth

echo "🔥 Limpando build do iOS..."

cd ios

# Clean no Xcode
echo "📦 Removendo Pods..."
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec

# Clean no Flutter
cd ..
echo "🧹 Flutter clean..."
flutter clean

# Pub get
echo "📥 Baixando dependências..."
flutter pub get

# Pod install
cd ios
echo "📦 Instalando Pods..."
pod install

cd ..

echo ""
echo "✅ Limpeza concluída!"
echo ""
echo "📋 Próximos passos:"
echo ""
echo "1. Abra o Xcode:"
echo "   open ios/Runner.xcworkspace"
echo ""
echo "2. No Xcode, faça:"
echo "   Product → Clean Build Folder (Shift+Cmd+K)"
echo "   Product → Build (Cmd+B)"
echo "   Product → Run (Cmd+R)"
echo ""
echo "3. ⚠️  IMPORTANTE: Configure APNs no Firebase Console"
echo "   Leia: docs/FIREBASE_PHONE_AUTH_SETUP.md"
echo ""
echo "4. Teste o login por telefone"
echo ""
