#!/bin/bash

# 🔥 Script para configurar Firebase com projeto apppagpag
# Este script baixa as configurações corretas do Firebase

echo "🔥 Configurando Firebase com projeto apppagpag..."

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Verificar se Firebase CLI está instalado
if ! command -v firebase &> /dev/null; then
    print_error "Firebase CLI não está instalado"
    print_info "Instalando Firebase CLI..."
    npm install -g firebase-tools
fi

# Verificar se está logado
if ! firebase projects:list &> /dev/null; then
    print_warning "Não está logado no Firebase"
    print_info "Fazendo login..."
    firebase login --no-localhost
fi

print_info "Configurando projeto apppagpag..."

# Baixar configurações do projeto
print_info "Baixando google-services.json..."
firebase apps:sdkconfig android --project=apppagpag > android/app/google-services.json

print_info "Baixando GoogleService-Info.plist..."
firebase apps:sdkconfig ios --project=apppagpag > ios/Runner/GoogleService-Info.plist

# Verificar se os arquivos foram criados
if [ -f "android/app/google-services.json" ]; then
    print_success "✅ google-services.json baixado"
else
    print_error "❌ Erro ao baixar google-services.json"
fi

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    print_success "✅ GoogleService-Info.plist baixado"
else
    print_error "❌ Erro ao baixar GoogleService-Info.plist"
fi

# Gerar firebase_options.dart
print_info "Gerando firebase_options.dart..."
firebase apps:sdkconfig flutter --project=apppagpag > lib/firebase_options.dart

if [ -f "lib/firebase_options.dart" ]; then
    print_success "✅ firebase_options.dart gerado"
else
    print_error "❌ Erro ao gerar firebase_options.dart"
fi

print_success "Configuração concluída! 🚀"
print_info "Próximos passos:"
echo "1. ✅ Execute: flutter clean && flutter pub get"
echo "2. ✅ Execute: flutter run"
echo "3. ✅ Habilite Authentication no Console: https://console.firebase.google.com/project/apppagpag/authentication/providers"
echo "4. ✅ Teste o cadastro"

