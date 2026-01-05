import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Serviço para controlar a action bar nativa do teclado iOS.
///
/// Este serviço comunica-se com o código Swift nativo (KeyboardDoneAccessory)
/// para adicionar uma barra de ferramentas customizada acima do teclado.
///
/// A action bar é ativada automaticamente no iOS e pode ser configurada
/// com cores e texto personalizados.
class KeyboardAccessoryService {
  KeyboardAccessoryService._();

  static final KeyboardAccessoryService _instance = KeyboardAccessoryService._();
  static KeyboardAccessoryService get instance => _instance;

  static const _channel = MethodChannel('com.nevescapital.pagpag/keyboard_accessory');

  bool _initialized = false;
  VoidCallback? _onDonePressed;

  /// Verifica se estamos no iOS (não web)
  bool get isSupported => !kIsWeb && Platform.isIOS;

  /// Inicializa o serviço e configura o listener para eventos do botão Done
  Future<void> initialize() async {
    if (_initialized || !isSupported) return;

    _channel.setMethodCallHandler(_handleMethodCall);
    _initialized = true;
  }

  /// Handler para chamadas vindas do código nativo
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDonePressed':
        _onDonePressed?.call();
        break;
    }
  }

  /// Define um callback para quando o botão Done for pressionado
  void setOnDonePressed(VoidCallback? callback) {
    _onDonePressed = callback;
  }

  /// Ativa a action bar nativa globalmente
  Future<bool> enable() async {
    if (!isSupported) return false;

    try {
      final result = await _channel.invokeMethod<bool>('enable');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[KeyboardAccessoryService] Erro ao ativar: ${e.message}');
      return false;
    }
  }

  /// Desativa a action bar nativa
  Future<bool> disable() async {
    if (!isSupported) return false;

    try {
      final result = await _channel.invokeMethod<bool>('disable');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[KeyboardAccessoryService] Erro ao desativar: ${e.message}');
      return false;
    }
  }

  /// Verifica se a action bar está habilitada
  Future<bool> isEnabled() async {
    if (!isSupported) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isEnabled');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[KeyboardAccessoryService] Erro ao verificar status: ${e.message}');
      return false;
    }
  }

  /// Configura a aparência da action bar
  ///
  /// - [buttonText]: Texto do botão (padrão: "OK")
  /// - [buttonColor]: Cor do texto do botão em hex (padrão: "#007AFF" - azul iOS)
  /// - [toolbarColor]: Cor de fundo da toolbar em hex (padrão: cinza do sistema)
  /// - [toolbarHeight]: Altura da toolbar (padrão: 44.0)
  Future<bool> configure({
    String? buttonText,
    String? buttonColor,
    String? toolbarColor,
    double? toolbarHeight,
  }) async {
    if (!isSupported) return false;

    try {
      final args = <String, dynamic>{};

      if (buttonText != null) args['buttonText'] = buttonText;
      if (buttonColor != null) args['buttonColor'] = buttonColor;
      if (toolbarColor != null) args['toolbarColor'] = toolbarColor;
      if (toolbarHeight != null) args['toolbarHeight'] = toolbarHeight;

      if (args.isEmpty) return true;

      final result = await _channel.invokeMethod<bool>('configure', args);
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[KeyboardAccessoryService] Erro ao configurar: ${e.message}');
      return false;
    }
  }

  /// Configura a action bar com o tema do aplicativo PagPag
  ///
  /// Usa as cores do tema:
  /// - Botão: Azul iOS (#007AFF)
  /// - Toolbar: Verde escuro do app (#122118) ou cinza padrão do iOS
  Future<bool> configureWithAppTheme({bool useDarkToolbar = false}) async {
    return configure(
      buttonText: 'OK',
      buttonColor: '#007AFF', // Azul iOS padrão
      toolbarColor: useDarkToolbar ? '#122118' : null, // Verde escuro do app ou padrão
    );
  }
}
