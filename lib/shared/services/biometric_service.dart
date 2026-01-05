import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

/// Serviço para autenticação biométrica (Face ID / Touch ID)
class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Verifica se a autenticação biométrica está disponível
  static Future<bool> isAvailable() async {
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      final bool isAvailable = canCheck && isDeviceSupported && availableBiometrics.isNotEmpty;
      
      AppLogger.debug('Biometria disponível: $isAvailable');
      
      return isAvailable;
    } catch (e) {
      AppLogger.error('Erro ao verificar disponibilidade de biometria', e);
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
      // Verificar disponibilidade
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheck || !isDeviceSupported) {
        AppLogger.warning('Biometria não disponível');
        return false;
      }

      // Verificar quais tipos de biometria estão disponíveis
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      AppLogger.debug('Biometrias disponíveis: ${availableBiometrics.length}');
      
      if (availableBiometrics.isEmpty) {
        AppLogger.warning('Nenhum tipo de biometria disponível');
        return false;
      }

      // Realizar autenticação com parâmetros otimizados para iOS
      // biometricOnly: false permite fallback para senha do dispositivo
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // Permitir fallback para senha do dispositivo
          stickyAuth: false, // Sempre solicitar autenticação (não reutilizar autenticação anterior)
          useErrorDialogs: true, // Mostrar diálogos de erro nativos do iOS
          sensitiveTransaction: false, // Transação não é extremamente sensível
        ),
      );

      AppLogger.debug('Autenticação biométrica: $didAuthenticate');
      return didAuthenticate;
    } on PlatformException catch (e) {
      // Tratamento específico de erros da plataforma
      AppLogger.error('Erro PlatformException na biometria: ${e.code}', e);
      
      if (e.code == 'NotAvailable') {
        AppLogger.warning('Biometria não disponível no dispositivo');
      } else if (e.code == 'NotEnrolled') {
        AppLogger.warning('Biometria não configurada no dispositivo');
      } else if (e.code == 'LockedOut') {
        AppLogger.warning('Biometria bloqueada (muitas tentativas falhadas)');
      } else if (e.code == 'PermanentlyLockedOut') {
        AppLogger.warning('Biometria permanentemente bloqueada');
      } else if (e.code == 'UserCancel') {
        AppLogger.info('Usuário cancelou a autenticação');
      } else if (e.code == 'AuthenticationFailed') {
        AppLogger.warning('Autenticação falhou (Face ID/Touch ID não reconhecido)');
      }
      
      return false;
    } catch (e) {
      AppLogger.error('Erro desconhecido na biometria', e);
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
