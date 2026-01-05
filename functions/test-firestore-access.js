#!/usr/bin/env node

/**
 * Script de teste para verificar acesso ao Firestore via Admin SDK
 * Execute: node test-firestore-access.js
 */

const admin = require('firebase-admin');

async function testFirestoreAccess() {
  try {
    console.log('🔧 Inicializando Firebase Admin...');
    
    // Inicializar Admin SDK
    if (!admin.apps.length) {
      admin.initializeApp({
        projectId: 'pagpagapp',
      });
    }
    
    console.log('✅ Firebase Admin inicializado');
    
    const db = admin.firestore();
    console.log('✅ Firestore instance criada');
    
    // Testar leitura de uma collection que não existe (não deve dar erro de permissão)
    console.log('🧪 Testando leitura no Firestore...');
    const testRef = db.collection('users').limit(1);
    const snapshot = await testRef.get();
    
    console.log(`✅ Teste de leitura: OK (${snapshot.size} documentos encontrados)`);
    console.log('✅ Admin SDK tem acesso ao Firestore!');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Erro ao acessar Firestore:', error.message);
    console.error('❌ Código:', error.code);
    console.error('❌ Stack:', error.stack);
    
    if (error.code === 7 || error.message.includes('PERMISSION_DENIED')) {
      console.error('');
      console.error('💡 SOLUÇÃO:');
      console.error('   1. Verifique se você tem permissões IAM no projeto:');
      console.error('      gcloud projects get-iam-policy pagpagapp');
      console.error('');
      console.error('   2. Configure Application Default Credentials:');
      console.error('      gcloud auth application-default login');
      console.error('      gcloud config set project pagpagapp');
      console.error('');
      console.error('   3. Ou use uma service account key JSON:');
      console.error('      export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json');
    }
    
    process.exit(1);
  }
}

testFirestoreAccess();

