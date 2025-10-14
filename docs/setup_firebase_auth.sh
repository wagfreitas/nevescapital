#!/bin/bash

# 🔥 Script para habilitar Authentication no Firebase Console
# Este script abre o Firebase Console na seção de Authentication

echo "🔥 Abrindo Firebase Console para configurar Authentication..."

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# URL do Firebase Console para o projeto neves-capital
FIREBASE_CONSOLE_URL="https://console.firebase.google.com/project/neves-capital/authentication/providers"

print_info "Abrindo Firebase Console..."
print_info "URL: $FIREBASE_CONSOLE_URL"

# Tentar abrir no navegador
if command -v open &> /dev/null; then
    # macOS
    open "$FIREBASE_CONSOLE_URL"
    print_success "Firebase Console aberto no navegador padrão"
elif command -v xdg-open &> /dev/null; then
    # Linux
    xdg-open "$FIREBASE_CONSOLE_URL"
    print_success "Firebase Console aberto no navegador padrão"
elif command -v start &> /dev/null; then
    # Windows
    start "$FIREBASE_CONSOLE_URL"
    print_success "Firebase Console aberto no navegador padrão"
else
    print_warning "Não foi possível abrir automaticamente o navegador"
    print_info "Por favor, abra manualmente: $FIREBASE_CONSOLE_URL"
fi

echo ""
echo "📋 PASSOS PARA CONFIGURAR AUTHENTICATION:"
echo "=========================================="
echo "1. ✅ Clique em 'Get started' se for a primeira vez"
echo "2. ✅ Vá na aba 'Sign-in method'"
echo "3. ✅ Clique em 'Email/Password'"
echo "4. ✅ Habilite 'Email/Password'"
echo "5. ✅ Clique em 'Save'"
echo ""
echo "🔐 CONFIGURAÇÕES RECOMENDADAS:"
echo "=============================="
echo "✅ Email/Password: Habilitado"
echo "✅ Email link (passwordless sign-in): Opcional"
echo "✅ User actions: Habilitado"
echo ""
echo "📱 PRÓXIMOS PASSOS:"
echo "==================="
echo "1. ✅ Configure Authentication no Console"
echo "2. ✅ Execute: flutter run"
echo "3. ✅ Teste o cadastro/login"
echo "4. ✅ Configure Cloud Functions para PostgreSQL"

print_success "Script concluído! Configure Authentication no Console 🚀"

