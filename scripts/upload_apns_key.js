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

