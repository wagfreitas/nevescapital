import 'package:firebase_auth/firebase_auth.dart';

/// Serviço para gerenciar autenticação Firebase
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Usuário atual logado
  static User? get currentUser => _auth.currentUser;

  /// Stream do estado de autenticação
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Criar conta no Firebase
  static Future<UserCredential> createUserWithEmailAndPassword({
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
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Fazer login com email e senha
  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
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
    } on FirebaseAuthException catch (e) {
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

  /// Tratar exceções do Firebase Auth
  static String _handleAuthException(FirebaseAuthException e) {
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
