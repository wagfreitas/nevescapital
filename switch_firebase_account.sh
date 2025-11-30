#!/bin/bash

# Script para trocar de conta no Firebase CLI

set -e

echo "🔥 Troca de Conta - Firebase CLI"
echo ""

# Verificar conta atual do Firebase
echo "📋 Conta atual do Firebase CLI:"
firebase login:list
echo ""

# Verificar conta atual do gcloud
echo "📋 Conta atual do gcloud CLI:"
gcloud auth list
echo ""

echo "⚠️  PROBLEMA DETECTADO:"
echo "   Firebase CLI: wagfreitas@gmail.com"
echo "   gcloud CLI:   j.wagner@neves.capital"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Perguntar se deseja trocar
read -p "Deseja fazer logout do Firebase e logar com j.wagner@neves.capital? (s/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Operação cancelada"
    exit 0
fi

echo ""
echo "🚪 Fazendo logout do Firebase CLI..."
firebase logout

echo ""
echo "🔐 Fazendo login com j.wagner@neves.capital..."
echo ""
echo "⚠️  Uma janela do navegador será aberta."
echo "   Certifique-se de selecionar a conta: j.wagner@neves.capital"
echo ""

read -p "Pressione Enter para continuar..." 

firebase login --reauth

echo ""
echo "✅ Login concluído!"
echo ""

# Verificar nova conta
echo "📋 Verificando conta atual:"
firebase login:list
echo ""

echo "📋 Listando projetos disponíveis:"
firebase projects:list
echo ""

echo "✅ Pronto! Agora você pode usar o Firebase CLI com j.wagner@neves.capital"
echo ""
echo "💡 Para configurar APNs, execute:"
echo "   ./setup_apns_cli.sh"
