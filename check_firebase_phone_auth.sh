#!/bin/bash

echo "🔍 Verificando configuração do Firebase Phone Auth para produção..."
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar SHA-1 do Android (para produção)
echo "📱 ANDROID - SHA-1 Fingerprint:"
echo ""

# Debug keystore
if [ -f ~/.android/debug.keystore ]; then
    echo "🔑 Debug Keystore SHA-1:"
    keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep -A 1 "SHA1:" | head -2
    echo ""
fi

# Release keystore (se existir)
if [ -f android/app/release.keystore ] || [ -f android/keystore.jks ]; then
    echo "🔑 Release Keystore SHA-1:"
    echo "Execute manualmente:"
    echo "  keytool -list -v -keystore android/app/release.keystore -alias <seu-alias>"
    echo ""
else
    echo -e "${YELLOW}⚠️  Release keystore não encontrado${NC}"
    echo "Para produção, você precisa:"
    echo "  1. Criar um keystore de release"
    echo "  2. Obter o SHA-1 do keystore de release"
    echo "  3. Adicionar no Firebase Console > Project Settings > Your apps > Android"
    echo ""
fi

# 2. Verificar iOS - APNs
echo "🍎 iOS - APNs Configuration:"
echo ""

# Verificar se Info.plist tem remote-notification
if grep -q "remote-notification" ios/Runner/Info.plist; then
    echo -e "${GREEN}✅ UIBackgroundModes com remote-notification configurado${NC}"
else
    echo -e "${RED}❌ UIBackgroundModes sem remote-notification${NC}"
fi

echo ""
echo "📋 CHECKLIST PARA PRODUÇÃO:"
echo ""
echo "ANDROID:"
echo "  [ ] SHA-1 do debug keystore adicionado no Firebase Console"
echo "  [ ] SHA-1 do release keystore adicionado no Firebase Console"
echo "  [ ] Firebase Console > Project Settings > Your apps > Android > SHA certificate fingerprints"
echo ""
echo "iOS:"
echo "  [ ] APNs Authentication Key (.p8) obtido da Apple Developer"
echo "  [ ] APNs Key enviado para Firebase Console"
echo "  [ ] Firebase Console > Project Settings > Cloud Messaging > APNs authentication key"
echo "  [ ] Key ID e Team ID configurados"
echo ""
echo "GERAL:"
echo "  [ ] Phone Auth habilitado: Firebase Console > Authentication > Sign-in method > Phone > Enable"
echo "  [ ] Número de teste configurado (se necessário): +5511989630454"
echo ""
echo "🔗 Links úteis:"
echo "  Firebase Console: https://console.firebase.google.com/project/pagpagapp"
echo "  Authentication: https://console.firebase.google.com/project/pagpagapp/authentication/providers"
echo "  Project Settings: https://console.firebase.google.com/project/pagpagapp/settings/general"
echo "  Cloud Messaging (APNs): https://console.firebase.google.com/project/pagpagapp/settings/cloudmessaging"
echo ""

