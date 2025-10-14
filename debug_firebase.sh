#!/bin/bash

# 🔍 Script de Debug Firebase - Neves Capital
# Este script verifica se o Firebase está configurado corretamente

echo "🔍 Verificando configuração do Firebase..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "📋 VERIFICAÇÃO DE ARQUIVOS DE CONFIGURAÇÃO:"
echo "==========================================="

# Verificar google-services.json
if [ -f "android/app/google-services.json" ]; then
    print_success "✅ android/app/google-services.json encontrado"
    
    # Verificar se tem project_id
    if grep -q "project_id" android/app/google-services.json; then
        PROJECT_ID=$(grep -o '"project_id": "[^"]*"' android/app/google-services.json | cut -d'"' -f4)
        print_success "✅ Project ID: $PROJECT_ID"
    else
        print_error "❌ Project ID não encontrado no google-services.json"
    fi
    
    # Verificar se tem api_key
    if grep -q "current_key" android/app/google-services.json; then
        print_success "✅ API Key encontrada no google-services.json"
    else
        print_error "❌ API Key não encontrada no google-services.json"
    fi
else
    print_error "❌ android/app/google-services.json não encontrado"
fi

# Verificar GoogleService-Info.plist
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    print_success "✅ ios/Runner/GoogleService-Info.plist encontrado"
    
    # Verificar se tem PROJECT_ID
    if grep -q "PROJECT_ID" ios/Runner/GoogleService-Info.plist; then
        IOS_PROJECT_ID=$(grep -A1 "PROJECT_ID" ios/Runner/GoogleService-Info.plist | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
        print_success "✅ iOS Project ID: $IOS_PROJECT_ID"
    else
        print_error "❌ Project ID não encontrado no GoogleService-Info.plist"
    fi
else
    print_error "❌ ios/Runner/GoogleService-Info.plist não encontrado"
fi

# Verificar firebase_options.dart
if [ -f "lib/firebase_options.dart" ]; then
    print_success "✅ lib/firebase_options.dart encontrado"
    
    # Verificar se tem projectId
    if grep -q "projectId:" lib/firebase_options.dart; then
        FLUTTER_PROJECT_ID=$(grep -o "projectId: '[^']*'" lib/firebase_options.dart | head -1 | cut -d"'" -f2)
        print_success "✅ Flutter Project ID: $FLUTTER_PROJECT_ID"
    else
        print_error "❌ Project ID não encontrado no firebase_options.dart"
    fi
else
    print_error "❌ lib/firebase_options.dart não encontrado"
fi

echo ""
echo "🔧 VERIFICAÇÃO DE CONFIGURAÇÕES GRADLE:"
echo "======================================="

# Verificar build.gradle.kts principal
if [ -f "android/build.gradle.kts" ]; then
    if grep -q "google-services" android/build.gradle.kts; then
        print_success "✅ Google Services plugin configurado no build.gradle.kts"
    else
        print_error "❌ Google Services plugin não configurado no build.gradle.kts"
    fi
else
    print_error "❌ android/build.gradle.kts não encontrado"
fi

# Verificar build.gradle.kts do app
if [ -f "android/app/build.gradle.kts" ]; then
    if grep -q "com.google.gms.google-services" android/app/build.gradle.kts; then
        print_success "✅ Google Services plugin aplicado no app/build.gradle.kts"
    else
        print_error "❌ Google Services plugin não aplicado no app/build.gradle.kts"
    fi
else
    print_error "❌ android/app/build.gradle.kts não encontrado"
fi

echo ""
echo "📱 VERIFICAÇÃO DE DEPENDÊNCIAS:"
echo "==============================="

# Verificar pubspec.yaml
if grep -q "firebase_core:" pubspec.yaml; then
    print_success "✅ firebase_core configurado"
else
    print_error "❌ firebase_core não configurado"
fi

if grep -q "firebase_auth:" pubspec.yaml; then
    print_success "✅ firebase_auth configurado"
else
    print_error "❌ firebase_auth não configurado"
fi

echo ""
echo "🌐 VERIFICAÇÃO DE CONECTIVIDADE:"
echo "==============================="

# Testar conectividade com Firebase
print_info "Testando conectividade com Firebase..."
if curl -s --connect-timeout 10 https://firebase.googleapis.com > /dev/null; then
    print_success "✅ Conectividade com Firebase OK"
else
    print_error "❌ Problema de conectividade com Firebase"
fi

echo ""
echo "🎯 RESUMO E PRÓXIMOS PASSOS:"
echo "============================="

# Verificar se todos os arquivos estão presentes
if [ -f "android/app/google-services.json" ] && [ -f "ios/Runner/GoogleService-Info.plist" ] && [ -f "lib/firebase_options.dart" ]; then
    print_success "✅ Todos os arquivos de configuração estão presentes"
    
    echo ""
    print_info "🔧 AÇÕES NECESSÁRIAS:"
    echo "1. ✅ Verifique se Authentication está habilitado no Firebase Console"
    echo "2. ✅ Execute: flutter clean && flutter pub get"
    echo "3. ✅ Execute: flutter run"
    echo "4. ✅ Teste o cadastro novamente"
    
    echo ""
    print_info "🔗 LINKS ÚTEIS:"
    echo "• Firebase Console: https://console.firebase.google.com/project/neves-capital"
    echo "• Authentication: https://console.firebase.google.com/project/neves-capital/authentication/providers"
    echo "• Project Settings: https://console.firebase.google.com/project/neves-capital/settings/general"
    
else
    print_error "❌ Arquivos de configuração faltando"
    print_info "Execute: ./setup_firebase.sh para configurar"
fi

print_success "Script de debug concluído! 🔍"

