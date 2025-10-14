// 🔥 Configuração Firebase - Arquivo de Exemplo
// Substitua os valores pelos seus dados reais do Firebase Console

class FirebaseConfig {
  // Configurações do Android
  static const Map<String, String> android = {
    'apiKey': 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    'appId': '1:123456789:android:abcdef1234567890',
    'messagingSenderId': '123456789',
    'projectId': 'seu-projeto-firebase',
    'storageBucket': 'seu-projeto-firebase.appspot.com',
  };

  // Configurações do iOS
  static const Map<String, String> ios = {
    'apiKey': 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    'appId': '1:123456789:ios:abcdef1234567890',
    'messagingSenderId': '123456789',
    'projectId': 'seu-projeto-firebase',
    'storageBucket': 'seu-projeto-firebase.appspot.com',
  };

  // Configurações do Web
  static const Map<String, String> web = {
    'apiKey': 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    'appId': '1:123456789:web:abcdef1234567890',
    'messagingSenderId': '123456789',
    'projectId': 'seu-projeto-firebase',
    'authDomain': 'seu-projeto-firebase.firebaseapp.com',
    'storageBucket': 'seu-projeto-firebase.appspot.com',
  };

  // Configurações gerais
  static const String projectId = 'seu-projeto-firebase';
  static const String authDomain = 'seu-projeto-firebase.firebaseapp.com';
  static const String storageBucket = 'seu-projeto-firebase.appspot.com';
}

// 📝 Como obter essas informações:
// 1. Vá para https://console.firebase.google.com/
// 2. Selecione seu projeto
// 3. Vá em "Project Settings" (ícone de engrenagem)
// 4. Na aba "General", role para baixo até "Your apps"
// 5. Clique no app desejado (Android/iOS/Web)
// 6. Copie os valores dos campos correspondentes

// 🔐 IMPORTANTE: 
// - Nunca commite este arquivo com dados reais
// - Use variáveis de ambiente em produção
// - Mantenha suas chaves API seguras
