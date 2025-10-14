import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Serviço para autenticação biométrica (Face ID / Touch ID)
class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Verifica se a autenticação biométrica está disponível
  static Future<bool> isAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Verifica quais tipos de biometria estão disponíveis
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Realiza autenticação biométrica
  static Future<bool> authenticate({
    String reason = 'Use sua biometria para fazer login',
  }) async {
    try {
      final bool isAvailable = await BiometricService.isAvailable();
      if (!isAvailable) {
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
      );

      return didAuthenticate;
    } on PlatformException {
      // Usuário cancelou ou erro de autenticação
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Verifica se o Face ID está disponível
  static Future<bool> isFaceIdAvailable() async {
    try {
      final List<BiometricType> availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.contains(BiometricType.face);
    } catch (e) {
      return false;
    }
  }

  /// Verifica se o Touch ID está disponível
  static Future<bool> isTouchIdAvailable() async {
    try {
      final List<BiometricType> availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.contains(BiometricType.fingerprint);
    } catch (e) {
      return false;
    }
  }

  /// Obtém o texto apropriado para o botão baseado na biometria disponível
  static Future<String> getBiometricButtonText() async {
    final bool faceIdAvailable = await isFaceIdAvailable();
    final bool touchIdAvailable = await isTouchIdAvailable();

    if (faceIdAvailable) {
      return 'Usar Face ID';
    } else if (touchIdAvailable) {
      return 'Usar Touch ID';
    } else {
      return 'Usar Biometria';
    }
  }

  /// Obtém o ícone apropriado para o botão baseado na biometria disponível
  static Future<String> getBiometricIcon() async {
    final bool faceIdAvailable = await isFaceIdAvailable();
    final bool touchIdAvailable = await isTouchIdAvailable();

    if (faceIdAvailable) {
      return 'face_id'; // Ícone do Face ID
    } else if (touchIdAvailable) {
      return 'fingerprint'; // Ícone do Touch ID
    } else {
      return 'security'; // Ícone genérico
    }
  }
}
