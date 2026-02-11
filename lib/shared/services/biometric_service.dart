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

  /// Realiza autenticação biométrica ou com senha do dispositivo
  static Future<bool> authenticate({
    String reason = 'Use sua biometria para fazer login',
    bool allowDevicePassword = true, // Permitir usar senha do dispositivo mesmo sem biometria
  }) async {
    try {
      // Verificar disponibilidade
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      // Verificar quais tipos de biometria estão disponíveis
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      AppLogger.debug('Biometrias disponíveis: ${availableBiometrics.length}');
      AppLogger.debug('canCheck: $canCheck, isDeviceSupported: $isDeviceSupported');
      
      // IMPORTANTE: Mesmo sem biometria disponível, tentar autenticação se allowDevicePassword = true
      // O iOS/Android mostrará a opção de senha do dispositivo quando biometricOnly = false
      if ((!canCheck || !isDeviceSupported || availableBiometrics.isEmpty) && !allowDevicePassword) {
        AppLogger.warning('Biometria não disponível e senha do dispositivo não permitida');
        return false;
      }

      // Se não há biometria disponível mas allowDevicePassword = true, forçar biometricOnly = false
      // Isso garante que o Android mostre o prompt de senha mesmo sem biometria
      final bool hasBiometrics = availableBiometrics.isNotEmpty;
      
      // IMPORTANTE: No iOS, quando allowDevicePassword = true, sempre usar biometricOnly = false
      // para que o sistema ofereça imediatamente a opção de senha quando o Face ID falhar
      // No Android, se não há biometria e allowDevicePassword = true, sempre usar biometricOnly = false
      // Se allowDevicePassword = true, sempre permitir fallback para senha (biometricOnly = false)
      // Isso garante que no iOS a opção de senha apareça imediatamente após falha do Face ID
      final bool finalBiometricOnly = (hasBiometrics && !allowDevicePassword) ? true : false;
      
      // Realizar autenticação com parâmetros otimizados
      // biometricOnly: controla se permite fallback para senha do dispositivo
      AppLogger.info('Tentando autenticação (biometricOnly: $finalBiometricOnly, hasBiometrics: $hasBiometrics, allowDevicePassword: $allowDevicePassword)...');
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: finalBiometricOnly, // Se não há biometria, sempre false para mostrar senha
          stickyAuth: false, // Sempre solicitar autenticação
          useErrorDialogs: true, // Mostrar diálogos de erro nativos
          sensitiveTransaction: false,
        ),
      );

      AppLogger.debug('Resultado da autenticação: $didAuthenticate');
      return didAuthenticate;
    } on PlatformException catch (e) {
      // Tratamento específico de erros da plataforma
      AppLogger.error('Erro PlatformException na biometria: ${e.code}', e);
      
      if (e.code == 'NotAvailable') {
        AppLogger.warning('Biometria não disponível no dispositivo');
        // Se permitir senha do dispositivo, tentar novamente com fallback
        if (allowDevicePassword) {
          AppLogger.info('Biometria não disponível, mas permitindo senha do dispositivo - tentando novamente...');
          try {
            final bool didAuthenticate = await _localAuth.authenticate(
              localizedReason: reason,
              options: const AuthenticationOptions(
                biometricOnly: false, // Permitir senha
                stickyAuth: false,
                useErrorDialogs: false,
                sensitiveTransaction: false,
              ),
            );
            AppLogger.info('Resultado da segunda tentativa: $didAuthenticate');
            return didAuthenticate;
          } catch (retryError) {
            AppLogger.error('Erro ao tentar autenticação com senha do dispositivo', retryError);
            return false;
          }
        }
        // Se não permitir senha, retornar false
        return false;
      } else if (e.code == 'NotEnrolled') {
        AppLogger.warning('Biometria não configurada no dispositivo');
        // Se permitir senha do dispositivo, tentar novamente
        if (allowDevicePassword) {
          AppLogger.info('Biometria não configurada, mas permitindo senha do dispositivo - tentando novamente...');
          try {
            final bool didAuthenticate = await _localAuth.authenticate(
              localizedReason: reason,
              options: const AuthenticationOptions(
                biometricOnly: false,
                stickyAuth: false,
                useErrorDialogs: false,
                sensitiveTransaction: false,
              ),
            );
            return didAuthenticate;
          } catch (retryError) {
            AppLogger.error('Erro ao tentar autenticação com senha', retryError);
            return false;
          }
        }
        // Se não permitir senha, retornar false
        return false;
      } else if (e.code == 'LockedOut') {
        AppLogger.warning('Biometria bloqueada (muitas tentativas falhadas)');
      } else if (e.code == 'PermanentlyLockedOut') {
        AppLogger.warning('Biometria permanentemente bloqueada');
      } else if (e.code == 'UserCancel') {
        AppLogger.info('Usuário cancelou a autenticação');
      } else if (e.code == 'AuthenticationFailed') {
        AppLogger.warning('Autenticação falhou (Face ID/Touch ID não reconhecido)');
        // Se permitir senha do dispositivo e a biometria falhou, tentar novamente com fallback para senha
        // Isso garante que no iOS a opção de senha apareça imediatamente após falha do Face ID
        if (allowDevicePassword) {
          AppLogger.info('Biometria falhou, mas permitindo senha do dispositivo - tentando novamente com fallback...');
          try {
            final bool didAuthenticate = await _localAuth.authenticate(
              localizedReason: reason,
              options: const AuthenticationOptions(
                biometricOnly: false, // Permitir senha imediatamente
                stickyAuth: false,
                useErrorDialogs: false, // Não mostrar diálogo de erro, já que vamos mostrar senha
                sensitiveTransaction: false,
              ),
            );
            AppLogger.info('Resultado da tentativa com fallback para senha: $didAuthenticate');
            return didAuthenticate;
          } catch (retryError) {
            AppLogger.error('Erro ao tentar autenticação com senha do dispositivo após falha biométrica', retryError);
            return false;
          }
        }
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
      // No iOS será "Face ID", no Android será "Reconhecimento Facial"
      return 'Usar Biometria Facial';
    } else if (touchIdAvailable) {
      // No iOS será "Touch ID", no Android será "Impressão Digital"
      return 'Usar Biometria';
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
