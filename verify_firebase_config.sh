#!/bin/bash

echo "🔍 Verificando configuração completa do Firebase Phone Auth..."
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar se Firebase CLI está instalado
if ! command -v firebase &> /dev/null; then
    echo -e "${YELLOW}⚠️  Firebase CLI não encontrado${NC}"
    echo "Instale com: npm install -g firebase-tools"
    echo ""
else
    echo -e "${GREEN}✅ Firebase CLI instalado${NC}"
    firebase --version
    echo ""
fi

# Verificar se está logado no Firebase
if firebase projects:list &> /dev/null; then
    echo -e "${GREEN}✅ Autenticado no Firebase${NC}"
    CURRENT_PROJECT=$(firebase use 2>/dev/null | grep -oP 'Using \K[^\s]+' || echo "Nenhum")
    echo "Projeto atual: $CURRENT_PROJECT"
    echo ""
else
    echo -e "${RED}❌ Não autenticado no Firebase${NC}"
    echo "Execute: firebase login"
    echo ""
fi

# Verificar arquivos de configuração
echo "📁 Arquivos de configuração:"
echo ""

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${GREEN}✅ GoogleService-Info.plist encontrado${NC}"
    BUNDLE_ID=$(grep -A 1 "CFBundleURLSchemes" ios/Runner/GoogleService-Info.plist | grep -oP '>\K[^<]+' | head -1 || echo "Não encontrado")
    echo "   Bundle ID: $BUNDLE_ID"
else
    echo -e "${RED}❌ GoogleService-Info.plist NÃO encontrado${NC}"
fi

if [ -f "android/app/google-services.json" ]; then
    echo -e "${GREEN}✅ google-services.json encontrado${NC}"
    PACKAGE_NAME=$(grep -oP '"package_name":\s*"\K[^"]+' android/app/google-services.json | head -1 || echo "Não encontrado")
    echo "   Package: $PACKAGE_NAME"
else
    echo -e "${RED}❌ google-services.json NÃO encontrado${NC}"
fi

echo ""

# Verificar Info.plist iOS
echo "🍎 iOS - Configurações:"
if grep -q "remote-notification" ios/Runner/Info.plist; then
    echo -e "${GREEN}✅ UIBackgroundModes com remote-notification${NC}"
else
    echo -e "${RED}❌ UIBackgroundModes SEM remote-notification${NC}"
fi

# Verificar APNs via API do Firebase (se possível)
echo ""
echo "🔐 Verificando APNs no Firebase (via API)..."
echo ""

# Tentar verificar via gcloud ou curl
if command -v gcloud &> /dev/null; then
    TOKEN=$(gcloud auth print-access-token 2>/dev/null)
    if [ ! -z "$TOKEN" ]; then
        APNS_CONFIG=$(curl -s -X GET \
            "https://fcm.googleapis.com/v1/projects/pagpagapp/apnsConfig" \
            -H "Authorization: Bearer $TOKEN" 2>/dev/null)
        
        if echo "$APNS_CONFIG" | grep -q "keyId"; then
            echo -e "${GREEN}✅ APNs configurado no Firebase${NC}"
            echo "$APNS_CONFIG" | grep -oP '"keyId":\s*"\K[^"]+' | head -1 | sed 's/^/   Key ID: /'
        else
            echo -e "${RED}❌ APNs NÃO configurado no Firebase${NC}"
            echo "   Configure em: Firebase Console > Project Settings > Cloud Messaging"
        fi
    else
        echo -e "${YELLOW}⚠️  Não autenticado no gcloud${NC}"
        echo "   Execute: gcloud auth login"
    fi
else
    echo -e "${YELLOW}⚠️  gcloud CLI não encontrado${NC}"
    echo "   Verifique manualmente no Firebase Console"
fi

echo ""
echo "📋 RESUMO - O que verificar manualmente:"
echo ""
echo "1. Firebase Console > Authentication > Sign-in method > Phone"
echo "   [ ] Phone Auth está 'Enabled'?"
echo "   [ ] Número de teste configurado: +5511989630454"
echo ""
echo "2. Firebase Console > Project Settings > Cloud Messaging"
echo "   [ ] APNs authentication key configurado?"
echo "   [ ] Key ID e Team ID preenchidos?"
echo ""
echo "3. Firebase Console > Project Settings > Your apps > iOS"
echo "   [ ] Bundle ID correto: com.nevescapital.pagpag"
echo ""
echo "🔗 Links diretos:"
echo "   Phone Auth: https://console.firebase.google.com/project/pagpagapp/authentication/providers"
echo "   APNs Config: https://console.firebase.google.com/project/pagpagapp/settings/cloudmessaging"
echo ""

