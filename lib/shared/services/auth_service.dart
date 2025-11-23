import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Serviço para gerenciar autenticação Firebase
class AuthService {
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  /// Usuário atual logado
  static firebase_auth.User? get currentUser => _auth.currentUser;

  /// Stream do estado de autenticação
  static Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  /// Criar conta no Firebase
  static Future<firebase_auth.UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Enviar email de verificação
      await credential.user?.sendEmailVerification();

      return credential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Fazer login com email e senha
  static Future<firebase_auth.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Fazer login com custom token (usado após validação OTP)
  static Future<firebase_auth.UserCredential> signInWithCustomToken({
    required String token,
  }) async {
    try {
      final credential = await _auth.signInWithCustomToken(token);
      return credential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Fazer logout
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Redefinir senha
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Verificar se email está verificado
  static bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Reenviar email de verificação
  static Future<void> sendEmailVerification() async {
    await currentUser?.sendEmailVerification();
  }

  /// Atualizar perfil do usuário
  static Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    await currentUser?.updateDisplayName(displayName);
    await currentUser?.updatePhotoURL(photoURL);
  }

  /// Atualizar email do usuário
  /// Nota: Pode requerer reautenticação dependendo das configurações do Firebase
  static Future<void> updateEmail(String newEmail) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('Usuário não autenticado');
    }
    
    try {
      // Usar dynamic para evitar conflito de tipos com User do domínio
      // O método updateEmail existe no User do Firebase Auth versão 6.1.0
      final userDynamic = firebaseUser as dynamic;
      await userDynamic.updateEmail(newEmail);
      await firebaseUser.sendEmailVerification();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Se não for FirebaseAuthException, pode ser problema de tipo ou reautenticação necessária
      throw Exception('Erro ao atualizar email. Pode ser necessário reautenticar: $e');
    }
  }

  /// Tratar exceções do Firebase Auth
  static String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'email-already-in-use':
        return 'Email já está em uso';
      case 'weak-password':
        return 'Senha muito fraca';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Usuário desabilitado';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde';
      case 'operation-not-allowed':
        return 'Operação não permitida';
      case 'requires-recent-login':
        return 'Requer login recente';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }
}
