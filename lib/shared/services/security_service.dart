import 'dart:io';
import 'package:flutter/services.dart';

/// Serviço de Segurança da Plataforma
/// 
/// Implementa MASVS-PLATFORM standards:
/// - MASVS-PLATFORM-1: Previne screenshots de dados sensíveis
/// - MASVS-PLATFORM-2: Previne gravação de tela
/// - MASVS-PLATFORM-3: Limpa dados sensíveis dos logs
class SecurityService {
  static const _channel = MethodChannel('com.nevescapital.pagpag/security');

  /// Habilitar proteção contra screenshots
  /// MASVS-PLATFORM-1: Protege dados sensíveis em telas
  static Future<void> enableScreenshotProtection() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('enableScreenshotProtection');
        print('🔒 Proteção contra screenshots habilitada (Android)');
      } else if (Platform.isIOS) {
        // iOS não permite bloquear screenshots completamente
        // Mas podemos detectar quando ocorrem
        print('ℹ️  iOS não suporta bloqueio de screenshots');
      }
    } catch (e) {
      print('⚠️  Erro ao habilitar proteção contra screenshots: $e');
    }
  }

  /// Desabilitar proteção contra screenshots
  static Future<void> disableScreenshotProtection() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('disableScreenshotProtection');
        print('🔓 Proteção contra screenshots desabilitada (Android)');
      }
    } catch (e) {
      print('⚠️  Erro ao desabilitar proteção contra screenshots: $e');
    }
  }

  /// Marcar janela como segura (Android)
  /// MASVS-PLATFORM-1: FLAG_SECURE
  static Future<void> setWindowSecure(bool secure) async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('setWindowSecure', {'secure': secure});
        print(secure 
          ? '🔒 Janela marcada como segura'
          : '🔓 Janela desmarcada como segura');
      }
    } catch (e) {
      print('⚠️  Erro ao configurar segurança da janela: $e');
    }
  }

  /// Detectar se app está rodando em emulador/root
  /// MASVS-RESILIENCE-1: Detecção de ambiente comprometido
  static Future<bool> isDeviceCompromised() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDeviceCompromised');
      return result ?? false;
    } catch (e) {
      print('⚠️  Erro ao verificar dispositivo: $e');
      return false;
    }
  }

  /// Verificar se debugger está conectado
  /// MASVS-RESILIENCE-2: Detecção de debugging
  static Future<bool> isDebuggerConnected() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDebuggerConnected');
      return result ?? false;
    } catch (e) {
      print('⚠️  Erro ao verificar debugger: $e');
      return false;
    }
  }

  /// Limpar campo de texto sensível da memória
  /// MASVS-STORAGE-1: Limpar dados sensíveis da memória
  static String clearSensitiveString(String value) {
    // Sobrescrever string com zeros
    // Nota: Em Dart, strings são imutáveis, então isso tem efeito limitado
    // Mas é uma boa prática
    return ' ' * value.length;
  }

  /// Sanitizar logs (remover dados sensíveis)
  /// MASVS-CODE-4: Previne vazamento de dados em logs
  static String sanitizeLog(String message) {
    String sanitized = message;

    // Padrões a serem removidos
    final patterns = [
      // CPF: 000.000.000-00
      RegExp(r'\d{3}\.\d{3}\.\d{3}-\d{2}'),
      // Email
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      // Cartão de crédito (16 dígitos)
      RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'),
      // CVV (3-4 dígitos após "cvv" ou "cvc")
      RegExp(r'(cvv|cvc|security\s*code)[\s:]*\d{3,4}', caseSensitive: false),
      // Tokens/Keys (sequências longas de caracteres alfanuméricos)
      RegExp(r'[A-Za-z0-9]{32,}'),
    ];

    for (final pattern in patterns) {
      sanitized = sanitized.replaceAll(pattern, '***REDACTED***');
    }

    return sanitized;
  }

  /// Log seguro (sanitiza automaticamente)
  /// MASVS-STORAGE-1: Não registra dados sensíveis em logs
  static void secureLog(String message, {String level = 'INFO'}) {
    final sanitized = sanitizeLog(message);
    print('[$level] $sanitized');
  }

  /// Inicializar configurações de segurança
  /// MASVS-PLATFORM: Configurações iniciais de segurança
  static Future<void> initialize() async {
    print('🔐 Inicializando configurações de segurança...');
    
    // Habilitar proteção contra screenshots em telas sensíveis
    await enableScreenshotProtection();
    
    // Verificar se dispositivo está comprometido
    final isCompromised = await isDeviceCompromised();
    if (isCompromised) {
      print('⚠️  ALERTA: Dispositivo pode estar comprometido (root/jailbreak)');
      // Em produção, você pode querer bloquear o app ou mostrar um aviso
    }
    
    // Verificar debugger
    final hasDebugger = await isDebuggerConnected();
    if (hasDebugger) {
      print('⚠️  ALERTA: Debugger detectado');
      // Em produção, você pode querer bloquear o app
    }
    
    print('✅ Configurações de segurança inicializadas');
  }
}

