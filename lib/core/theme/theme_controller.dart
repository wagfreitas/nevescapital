import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller para gerenciar o tema da aplicação
class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  
  bool get isLightMode => !isDarkMode;
  
  /// Inicializa o controller carregando o tema salvo
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    
    if (savedTheme != null) {
      switch (savedTheme) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          _themeMode = ThemeMode.system;
          break;
      }
      notifyListeners();
    }
  }
  
  /// Define o tema da aplicação
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    // Salva a preferência
    final prefs = await SharedPreferences.getInstance();
    String themeString;
    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
        themeString = 'system';
        break;
    }
    await prefs.setString(_themeKey, themeString);
  }
  
  /// Alterna entre tema claro e escuro
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.system) {
      await setThemeMode(ThemeMode.light);
    } else if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.system);
    }
  }
  
  /// Força o tema claro
  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }
  
  /// Força o tema escuro
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }
  
  /// Usa o tema do sistema
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }
}
