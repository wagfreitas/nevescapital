#!/bin/bash

# Habilitar Background Modes no Info.plist
INFO_PLIST="ios/Runner/Info.plist"

echo "📱 Habilitando Background Modes para Phone Auth..."

# Adicionar UIBackgroundModes se não existir
if ! grep -q "UIBackgroundModes" "$INFO_PLIST"; then
  # Procurar o último </dict> antes do </plist>
  /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes array" "$INFO_PLIST"
  /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes:0 string remote-notification" "$INFO_PLIST"
  /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes:1 string fetch" "$INFO_PLIST"
  echo "✅ Background Modes adicionados"
else
  echo "⚠️  UIBackgroundModes já existe, verificando..."
  /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" "$INFO_PLIST"
fi

echo ""
echo "✅ Configuração completa!"
echo "🔧 Agora você precisa:"
echo "1. Abrir https://console.firebase.google.com/project/pagpagapp/authentication/providers"
echo "2. Clicar em 'Phone' e ATIVAR o toggle"
echo "3. Salvar as alterações"

