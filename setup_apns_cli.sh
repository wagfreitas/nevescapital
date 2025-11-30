#!/bin/bash

# Script para configurar APNs no Firebase via CLI
# Requisitos: Firebase CLI instalada e autenticada

set -e

echo "🔥 Configuração de APNs no Firebase via CLI"
echo ""

# Verificar se Firebase CLI está instalada
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI não encontrada!"
    echo ""
    echo "📦 Instale o Firebase CLI:"
    echo "   npm install -g firebase-tools"
    echo ""
    echo "Ou usando curl:"
    echo "   curl -sL https://firebase.tools | bash"
    exit 1
fi

echo "✅ Firebase CLI encontrada: $(firebase --version)"
echo ""

# Verificar se está autenticado
echo "🔐 Verificando autenticação..."
if ! firebase projects:list &> /dev/null; then
    echo "⚠️  Você não está autenticado no Firebase CLI"
    echo ""
    echo "Execute:"
    echo "   firebase login"
    echo ""
    read -p "Deseja fazer login agora? (s/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        firebase login
    else
        echo "❌ Autenticação necessária. Saindo..."
        exit 1
    fi
fi

echo "✅ Autenticado!"
echo ""

# Listar projetos
echo "📋 Projetos disponíveis:"
firebase projects:list
echo ""

# Selecionar projeto
echo "🎯 Selecione o projeto Firebase:"
echo ""
read -p "Digite o Project ID (ou pressione Enter para usar 'pagpagapp'): " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    PROJECT_ID="pagpagapp"
fi

echo ""
echo "Usando projeto: $PROJECT_ID"
firebase use $PROJECT_ID || {
    echo "❌ Projeto não encontrado ou sem acesso: $PROJECT_ID"
    echo ""
    echo "Verifique:"
    echo "1. Se o projeto existe no Firebase Console"
    echo "2. Se você tem permissão de acesso"
    echo "3. Se o nome está correto (case-sensitive)"
    exit 1
}

echo ""
echo "⚠️  IMPORTANTE: Configuração de APNs"
echo ""
echo "O Firebase CLI não suporta upload direto de APNs Key/Certificate."
echo "Você precisa fazer isso via Console ou API REST."
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📋 OPÇÕES DISPONÍVEIS:"
echo ""
echo "OPÇÃO 1: Console Web (Mais Fácil) ✅"
echo "────────────────────────────────────"
echo "1. Acesse: https://console.firebase.google.com/project/pagpagapp/settings/cloudmessaging"
echo "2. Seção 'Apple app configuration'"
echo "3. Faça upload do arquivo .p8"
echo ""
echo "OPÇÃO 2: Firebase Admin SDK (Script Python/Node) 🔧"
echo "──────────────────────────────────────────────────"
echo "Vou gerar um script Node.js para você..."
echo ""

# Criar diretório para scripts
mkdir -p scripts

# Criar script Node.js para upload de APNs
cat > scripts/upload_apns_key.js << 'EOF'
/**
 * Script para fazer upload de APNs Key para Firebase via Admin SDK
 * 
 * Requisitos:
 * - npm install firebase-admin
 * - Service Account JSON do Firebase
 * - APNs Auth Key (.p8)
 * 
 * Uso:
 * node upload_apns_key.js <caminho-para-service-account.json> <caminho-para-apns-key.p8> <key-id> <team-id>
 */

const admin = require('firebase-admin');
const fs = require('fs');

// Verificar argumentos
if (process.argv.length < 6) {
  console.error('❌ Uso: node upload_apns_key.js <service-account.json> <apns-key.p8> <key-id> <team-id>');
  console.error('');
  console.error('Exemplo:');
  console.error('  node upload_apns_key.js ./service-account.json ./AuthKey_ABC123.p8 ABC123 3T4MG5QU7G');
  process.exit(1);
}

const serviceAccountPath = process.argv[2];
const apnsKeyPath = process.argv[3];
const keyId = process.argv[4];
const teamId = process.argv[5];

// Verificar arquivos
if (!fs.existsSync(serviceAccountPath)) {
  console.error(`❌ Service Account não encontrado: ${serviceAccountPath}`);
  process.exit(1);
}

if (!fs.existsSync(apnsKeyPath)) {
  console.error(`❌ APNs Key não encontrado: ${apnsKeyPath}`);
  process.exit(1);
}

console.log('🔥 Configurando APNs no Firebase...');
console.log('');

// Inicializar Admin SDK
const serviceAccount = require(serviceAccountPath);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id
});

// Ler APNs Key
const apnsKeyContent = fs.readFileSync(apnsKeyPath, 'utf8');

console.log('📋 Informações:');
console.log(`   Projeto: ${serviceAccount.project_id}`);
console.log(`   Bundle ID: com.nevescapital.pagpag`);
console.log(`   Key ID: ${keyId}`);
console.log(`   Team ID: ${teamId}`);
console.log('');

// Nota: O Admin SDK não tem método direto para upload de APNs
// É necessário usar a API REST do Firebase
console.log('⚠️  O Firebase Admin SDK não suporta upload de APNs diretamente.');
console.log('');
console.log('Use a API REST do Firebase:');
console.log('');
console.log('curl -X POST \\');
console.log('  https://fcm.googleapis.com/v1/projects/pagpagapp/webPush/config \\');
console.log('  -H "Authorization: Bearer $(gcloud auth print-access-token)" \\');
console.log('  -H "Content-Type: application/json" \\');
console.log('  -d @- <<EOF_JSON');
console.log('{');
console.log('  "apnsConfig": {');
console.log(`    "keyId": "${keyId}",`);
console.log(`    "teamId": "${teamId}",`);
console.log('    "privateKey": "' + apnsKeyContent.replace(/\n/g, '\\n') + '"');
console.log('  }');
console.log('}');
console.log('EOF_JSON');
console.log('');
console.log('Ou use o Console Web: https://console.firebase.google.com/project/pagpagapp/settings/cloudmessaging');

EOF

echo "✅ Script Node.js criado: scripts/upload_apns_key.js"
echo ""
echo "OPÇÃO 3: API REST com gcloud CLI 🚀"
echo "────────────────────────────────────"
echo ""

# Verificar se gcloud está instalado
if command -v gcloud &> /dev/null; then
    echo "✅ gcloud CLI encontrada"
    echo ""
    
    cat > scripts/upload_apns_via_rest.sh << 'EOF'
#!/bin/bash

# Script para fazer upload de APNs via API REST do Firebase
# Requisitos: gcloud CLI instalada e autenticada

set -e

echo "🔥 Upload de APNs Key via API REST"
echo ""

# Verificar argumentos
if [ "$#" -ne 3 ]; then
    echo "❌ Uso: $0 <caminho-para-apns-key.p8> <key-id> <team-id>"
    echo ""
    echo "Exemplo:"
    echo "  $0 ./AuthKey_ABC123.p8 ABC123 3T4MG5QU7G"
    exit 1
fi

APNS_KEY_PATH=$1
KEY_ID=$2
TEAM_ID=$3

# Verificar arquivo
if [ ! -f "$APNS_KEY_PATH" ]; then
    echo "❌ APNs Key não encontrado: $APNS_KEY_PATH"
    exit 1
fi

# Verificar autenticação gcloud
if ! gcloud auth print-access-token &> /dev/null; then
    echo "⚠️  gcloud não autenticado"
    echo "Execute: gcloud auth login"
    exit 1
fi

echo "📋 Configuração:"
echo "   Projeto: pagpagapp"
echo "   Bundle ID: com.nevescapital.pagpag"
echo "   Key ID: $KEY_ID"
echo "   Team ID: $TEAM_ID"
echo ""

# Ler conteúdo da chave (escapar newlines)
APNS_KEY_CONTENT=$(cat "$APNS_KEY_PATH" | sed ':a;N;$!ba;s/\n/\\n/g')

# Obter token
TOKEN=$(gcloud auth print-access-token)

echo "🚀 Enviando configuração para Firebase..."
echo ""

# Fazer upload via API REST
RESPONSE=$(curl -s -X PATCH \
  "https://fcm.googleapis.com/v1/projects/pagpagapp/apnsConfig" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"keyId\": \"$KEY_ID\",
    \"teamId\": \"$TEAM_ID\",
    \"privateKey\": \"$APNS_KEY_CONTENT\"
  }")

if echo "$RESPONSE" | grep -q "error"; then
    echo "❌ Erro ao fazer upload:"
    echo "$RESPONSE" | jq '.'
    exit 1
fi

echo "✅ APNs Key configurado com sucesso!"
echo ""
echo "📋 Resposta:"
echo "$RESPONSE" | jq '.'
echo ""
echo "🎯 Próximos passos:"
echo "1. Habilite Phone Authentication no Firebase Console"
echo "2. Execute: ./fix_firebase_phone_auth.sh"
echo "3. Teste o login por telefone no app"

EOF

    chmod +x scripts/upload_apns_via_rest.sh
    echo "✅ Script REST criado: scripts/upload_apns_via_rest.sh"
    echo ""
    echo "📋 Para usar:"
    echo "   ./scripts/upload_apns_via_rest.sh <caminho-apns-key.p8> <key-id> <team-id>"
    echo ""
    echo "Exemplo:"
    echo "   ./scripts/upload_apns_via_rest.sh ~/Downloads/AuthKey_ABC123.p8 ABC123 3T4MG5QU7G"
    
else
    echo "⚠️  gcloud CLI não encontrada"
    echo ""
    echo "Para instalar:"
    echo "   brew install google-cloud-sdk"
    echo "Ou: https://cloud.google.com/sdk/docs/install"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📝 RESUMO - PASSOS PARA CONFIGURAR APNs:"
echo ""
echo "1️⃣  Obter APNs Authentication Key (.p8):"
echo "   → https://developer.apple.com/account/resources/authkeys/list"
echo "   → Criar chave com 'Apple Push Notifications service'"
echo "   → Baixar arquivo .p8"
echo "   → Anotar Key ID e Team ID"
echo ""
echo "2️⃣  Fazer upload (escolha uma opção):"
echo ""
echo "   OPÇÃO A - Console Web (Recomendado): ✅"
echo "   → https://console.firebase.google.com/project/apppagpag/settings/cloudmessaging"
echo "   → Upload manual do arquivo .p8"
echo ""
echo "   OPÇÃO B - Script REST (se tiver gcloud):"
echo "   → ./scripts/upload_apns_via_rest.sh <file.p8> <key-id> <team-id>"
echo ""
echo "3️⃣  Habilitar Phone Auth:"
echo "   firebase --project=pagpagapp auth:enable phone"
echo ""
echo "4️⃣  Rebuild do app:"
echo "   ./fix_firebase_phone_auth.sh"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "💡 DICA: A maneira mais fácil é usar o Console Web!"
echo ""

# Tentar habilitar Phone Auth
echo "🔐 Tentando habilitar Phone Authentication..."
echo ""

# Verificar se o comando funciona (pode não estar disponível em todas as versões)
if firebase auth:list &> /dev/null; then
    firebase auth:enable phone || echo "⚠️  Comando não disponível. Habilite manualmente no Console."
else
    echo "⚠️  Comando auth:enable não disponível nesta versão do Firebase CLI"
    echo ""
    echo "Habilite manualmente:"
    echo "1. Acesse: https://console.firebase.google.com/project/pagpagapp/authentication/providers"
    echo "2. Clique em 'Phone'"
    echo "3. Ative o switch 'Enable'"
    echo "4. Clique em 'Save'"
fi

echo ""
echo "✅ Configuração preparada!"
echo ""
echo "📋 Próximos passos:"
echo "1. Obtenha o APNs Key (.p8) da Apple Developer"
echo "2. Faça upload via Console Web ou script REST"
echo "3. Execute: ./fix_firebase_phone_auth.sh"
echo "4. Teste o app!"
