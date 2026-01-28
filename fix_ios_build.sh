#!/bin/bash

# Script para corrigir erro de build do Xcode no Flutter
# Execute: bash fix_ios_build.sh

echo "🧹 Limpando projeto Flutter..."
flutter clean

echo "📦 Obtendo dependências Flutter..."
flutter pub get

echo "🍎 Limpando build do iOS..."
cd ios
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies

echo "📱 Reinstalando CocoaPods..."
pod deintegrate || true
pod install --repo-update

echo "🔄 Limpando cache do Xcode..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*

echo "✅ Limpeza concluída!"
echo ""
echo "Agora tente executar novamente:"
echo "  flutter run"

