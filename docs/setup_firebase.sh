#!/bin/bash

# 🔥 Script de Configuração Firebase para Neves Capital
# Este script ajuda a configurar o Firebase automaticamente

echo "🔥 Configurando Firebase para Neves Capital..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir com cores
print_status() {
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

# Verificar se Flutter está instalado
if ! command -v flutter &> /dev/null; then
    print_error "Flutter não está instalado. Instale o Flutter primeiro."
    exit 1
fi

print_success "Flutter encontrado: $(flutter --version | head -n1)"

# Verificar se Firebase CLI está instalado
if ! command -v firebase &> /dev/null; then
    print_warning "Firebase CLI não encontrado. Instalando..."
    npm install -g firebase-tools
    if [ $? -eq 0 ]; then
        print_success "Firebase CLI instalado com sucesso"
    else
        print_error "Falha ao instalar Firebase CLI"
        exit 1
    fi
else
    print_success "Firebase CLI encontrado: $(firebase --version)"
fi

# Verificar se está logado no Firebase
if ! firebase projects:list &> /dev/null; then
    print_warning "Você não está logado no Firebase. Fazendo login..."
    firebase login
    if [ $? -eq 0 ]; then
        print_success "Login realizado com sucesso"
    else
        print_error "Falha no login do Firebase"
        exit 1
    fi
else
    print_success "Já está logado no Firebase"
fi

# Criar diretórios necessários
print_status "Criando diretórios necessários..."
mkdir -p android/app
mkdir -p ios/Runner

# Verificar se os arquivos de configuração existem
print_status "Verificando arquivos de configuração..."

if [ ! -f "android/app/google-services.json" ]; then
    print_warning "Arquivo android/app/google-services.json não encontrado"
    print_status "Por favor, baixe este arquivo do Firebase Console e coloque em android/app/"
    echo "1. Vá para https://console.firebase.google.com/"
    echo "2. Selecione seu projeto"
    echo "3. Vá em 'Project Settings' > 'Your apps'"
    echo "4. Clique no app Android"
    echo "5. Baixe o arquivo google-services.json"
    echo "6. Coloque em android/app/google-services.json"
    echo ""
fi

if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
    print_warning "Arquivo ios/Runner/GoogleService-Info.plist não encontrado"
    print_status "Por favor, baixe este arquivo do Firebase Console e coloque em ios/Runner/"
    echo "1. Vá para https://console.firebase.google.com/"
    echo "2. Selecione seu projeto"
    echo "3. Vá em 'Project Settings' > 'Your apps'"
    echo "4. Clique no app iOS"
    echo "5. Baixe o arquivo GoogleService-Info.plist"
    echo "6. Coloque em ios/Runner/GoogleService-Info.plist"
    echo ""
fi

# Verificar dependências do pubspec.yaml
print_status "Verificando dependências do Firebase..."

if ! grep -q "firebase_core:" pubspec.yaml; then
    print_warning "firebase_core não encontrado no pubspec.yaml"
fi

if ! grep -q "firebase_auth:" pubspec.yaml; then
    print_warning "firebase_auth não encontrado no pubspec.yaml"
fi

# Executar flutter pub get
print_status "Executando flutter pub get..."
flutter pub get

if [ $? -eq 0 ]; then
    print_success "Dependências instaladas com sucesso"
else
    print_error "Falha ao instalar dependências"
    exit 1
fi

# Verificar configuração do Android
print_status "Verificando configuração do Android..."

if [ -f "android/app/google-services.json" ]; then
    # Verificar se o plugin está configurado no build.gradle
    if ! grep -q "com.google.gms.google-services" android/app/build.gradle; then
        print_warning "Plugin do Google Services não configurado no Android"
        print_status "Adicione no android/app/build.gradle:"
        echo "apply plugin: 'com.google.gms.google-services'"
    fi
    
    if ! grep -q "google-services" android/build.gradle; then
        print_warning "Classpath do Google Services não configurado"
        print_status "Adicione no android/build.gradle:"
        echo "classpath 'com.google.gms:google-services:4.3.15'"
    fi
fi

# Testar compilação
print_status "Testando compilação..."
flutter analyze

if [ $? -eq 0 ]; then
    print_success "Análise estática passou sem erros"
else
    print_warning "Análise estática encontrou problemas"
fi

# Resumo final
echo ""
echo "🎯 RESUMO DA CONFIGURAÇÃO:"
echo "=========================="

if [ -f "android/app/google-services.json" ]; then
    print_success "✅ Android configurado"
else
    print_error "❌ Android não configurado"
fi

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    print_success "✅ iOS configurado"
else
    print_error "❌ iOS não configurado"
fi

if grep -q "firebase_core:" pubspec.yaml && grep -q "firebase_auth:" pubspec.yaml; then
    print_success "✅ Dependências Firebase instaladas"
else
    print_error "❌ Dependências Firebase faltando"
fi

echo ""
print_status "Próximos passos:"
echo "1. Configure os arquivos de configuração se ainda não fez"
echo "2. Execute: flutter run"
echo "3. Teste o login/cadastro"
echo "4. Configure Cloud Functions para PostgreSQL"

print_success "Script de configuração concluído! 🚀"
