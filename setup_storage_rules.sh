#!/bin/bash

# Script para configurar as regras do Firebase Storage
# Execute este script após configurar o Firebase no projeto

echo "🔥 Configurando regras do Firebase Storage..."

cat > storage.rules << 'EOF'
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Permite upload de documentos KYC durante o cadastro (sem autenticação)
    // mas com validação de tamanho e tipo de arquivo
    match /users/{userId}/kyc/{document} {
      // Leitura apenas para usuário autenticado dono dos documentos
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Escrita permitida durante cadastro (sem auth) ou para usuário autenticado
      allow write: if (request.auth == null || request.auth.uid == userId)
                   && request.resource.size < 5 * 1024 * 1024  // Max 5MB
                   && request.resource.contentType.matches('image/.*');
      
      // Exclusão apenas para usuário autenticado
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // Bloquear todo o resto
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
EOF

echo "✅ Arquivo storage.rules criado com sucesso!"
echo ""
echo "📋 Próximos passos:"
echo "1. Acesse o Firebase Console:"
echo "   https://console.firebase.google.com"
echo ""
echo "2. Selecione seu projeto e vá em Storage > Rules"
echo ""
echo "3. Cole as regras do arquivo storage.rules e clique em 'Publicar'"
echo ""
echo "⚠️  IMPORTANTE: As regras permitem upload durante o cadastro (sem autenticação)"
echo "   mas com validação de tamanho (5MB) e tipo (apenas imagens)"
echo ""
echo "Ou use Firebase CLI:"
echo "   firebase login"
echo "   firebase init storage"
echo "   firebase deploy --only storage"
