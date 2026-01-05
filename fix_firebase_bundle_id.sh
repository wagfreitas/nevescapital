#!/bin/bash

echo "🔍 Verificando inconsistências de Bundle ID do Firebase..."
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Verificar Bundle ID no Xcode
XCODE_BUNDLE_ID=$(grep -m 1 "PRODUCT_BUNDLE_IDENTIFIER = com\." ios/Runner.xcodeproj/project.pbxproj | grep -v "RunnerTests" | sed 's/.*= //;s/;//' | tr -d ' ')

# 2. Verificar Bundle ID no GoogleService-Info.plist
PLIST_BUNDLE_ID=$(grep -A 1 "BUNDLE_ID" ios/Runner/GoogleService-Info.plist | grep -v "BUNDLE_ID" | sed 's/.*<string>//;s/<\/string>//' | tr -d '\t')

# 3. Verificar Bundle ID no firebase_options.dart
DART_BUNDLE_ID=$(grep "iosBundleId:" lib/firebase_options.dart | sed "s/.*'//;s/'.*//")

echo "📱 Bundle IDs encontrados:"
echo "   Xcode:              $XCODE_BUNDLE_ID"
echo "   GoogleService-Info: $PLIST_BUNDLE_ID"
echo "   firebase_options:   $DART_BUNDLE_ID"
echo ""

# Verificar App IDs
PLIST_APP_ID=$(grep -A 1 "GOOGLE_APP_ID" ios/Runner/GoogleService-Info.plist | grep -v "GOOGLE_APP_ID" | sed 's/.*<string>//;s/<\/string>//' | tr -d '\t')
DART_APP_ID=$(grep "appId:" lib/firebase_options.dart | grep "ios:" | sed "s/.*'//;s/'.*//")

echo "🆔 App IDs encontrados:"
echo "   GoogleService-Info: $PLIST_APP_ID"
echo "   firebase_options:   $DART_APP_ID"
echo ""

# Verificar inconsistências
ISSUES=0

if [ "$XCODE_BUNDLE_ID" != "$PLIST_BUNDLE_ID" ]; then
    echo -e "${RED}❌ INCONSISTÊNCIA: Xcode Bundle ID ($XCODE_BUNDLE_ID) não corresponde ao GoogleService-Info.plist ($PLIST_BUNDLE_ID)${NC}"
    ISSUES=$((ISSUES + 1))
else
    echo -e "${GREEN}✅ Xcode e GoogleService-Info.plist têm o mesmo Bundle ID${NC}"
fi

if [ "$DART_BUNDLE_ID" != "$PLIST_BUNDLE_ID" ]; then
    echo -e "${RED}❌ INCONSISTÊNCIA: firebase_options.dart Bundle ID ($DART_BUNDLE_ID) não corresponde ao GoogleService-Info.plist ($PLIST_BUNDLE_ID)${NC}"
    ISSUES=$((ISSUES + 1))
else
    echo -e "${GREEN}✅ firebase_options.dart e GoogleService-Info.plist têm o mesmo Bundle ID${NC}"
fi

if [ "$DART_APP_ID" != "$PLIST_APP_ID" ]; then
    echo -e "${RED}❌ INCONSISTÊNCIA: firebase_options.dart App ID ($DART_APP_ID) não corresponde ao GoogleService-Info.plist ($PLIST_APP_ID)${NC}"
    ISSUES=$((ISSUES + 1))
else
    echo -e "${GREEN}✅ firebase_options.dart e GoogleService-Info.plist têm o mesmo App ID${NC}"
fi

echo ""

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✅ Tudo está alinhado!${NC}"
    echo ""
    echo "📋 Próximos passos para resolver o 'internal-error':"
    echo "   1. Verifique se APNs está configurado no Firebase Console:"
    echo "      https://console.firebase.google.com/project/pagpagapp/settings/cloudmessaging"
    echo ""
    echo "   2. Verifique se Phone Auth está habilitado:"
    echo "      https://console.firebase.google.com/project/pagpagapp/authentication/providers"
    echo ""
    echo "   3. Verifique se o número de teste está cadastrado (sem espaços/hífens):"
    echo "      Authentication > Sign-in method > Phone > Test phone numbers"
    echo ""
    echo "   4. Teste em dispositivo físico (não emulador)"
else
    echo -e "${YELLOW}⚠️  Encontradas $ISSUES inconsistência(s)${NC}"
    echo ""
    echo "🔧 CORREÇÃO NECESSÁRIA:"
    echo ""
    echo "O Bundle ID correto parece ser: ${GREEN}$PLIST_BUNDLE_ID${NC}"
    echo "(baseado no GoogleService-Info.plist do Firebase)"
    echo ""
    echo "Você precisa:"
    echo "   1. Mudar o Bundle ID no Xcode para: $PLIST_BUNDLE_ID"
    echo "      (Project Settings > General > Bundle Identifier)"
    echo ""
    echo "   2. OU baixar um novo GoogleService-Info.plist do Firebase Console"
    echo "      com o Bundle ID: $XCODE_BUNDLE_ID"
    echo ""
    echo "   3. Depois, execute novamente este script para verificar"
fi

echo ""

