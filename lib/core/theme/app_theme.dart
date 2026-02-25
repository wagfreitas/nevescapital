import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tema da aplicação
class AppTheme {
  // Cores baseadas no Design Concept
  static const Color primaryColor = Color(0xFF28CC28); // Verde dos botões (#28CC28)
  static const Color splashColor = Color(0xFF023E25); // Verde da Splash e MainTab (#023E25)
  static const Color backgroundColor = Color(0xFF122118); // Fundo verde escuro padrão (#122118)
  static const Color surfaceColor = Color(0xFF1A2B1F); // Superfície verde escura
  static const Color cardColor = Color(0xFF1F2A1F); // Cards com tom verde
  static const Color borderColor = Color(0xFF2A3A2A); // Bordas verdes sutis
  static const Color accentColor = Color(0xFF28CC28); // Verde dos botões para acentos
  
  // Cores específicas para inputs (verde mais claro que o fundo)
  static const Color inputBackgroundColor = Color(0xFF1A2B1F); // Verde escuro para inputs
  static const Color inputEditableBackgroundColor = Color(0xFF1A2B1F); // Verde para inputs editáveis (mesmo que surfaceColor)
  
  // Cores comuns
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color successColor = Color(0xFF28CC28);
  static const Color destructiveColor = Color(0xFFEF4444);
  
  // Cores de texto
  static const Color textPrimary = Color(0xFFFFFFFF); // Branco
  static const Color textSecondary = Color(0xFFA1A1AA); // Zinc-400
  static const Color textMuted = Color(0xFF71717A); // Zinc-500
  static const Color textHint = Color(0xFF9CA3AF); // Cinza claro
  
  // Glass effect colors (com tons verdes)
  static const Color glassBackground = Color(0x1A28CC28); // 10% verde dos botões
  static const Color glassBorder = Color(0x3328CC28); // 20% verde dos botões
  
  /// Tema baseado no Design Concept: Gradiente verde escuro → preto com acentos verdes vibrantes
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        onPrimary: backgroundColor,
        onSecondary: backgroundColor,
        onSurface: textPrimary,
        error: errorColor,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackgroundColor, // Verde mais claro que o fundo
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary, 
          fontSize: 32, 
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          color: textPrimary, 
          fontSize: 24, 
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          color: textPrimary, 
          fontSize: 20, 
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: textPrimary, 
          fontSize: 18, 
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary, 
          fontSize: 16, 
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: textMuted, 
          fontSize: 14, 
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textSecondary, 
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: textSecondary, 
          fontSize: 14,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          color: textMuted, 
          fontSize: 12,
          height: 1.3,
        ),
      ),
    );
  }
  
  /// Tema escuro (mesmo que o lightTheme baseado no HTML)
  static ThemeData get darkTheme => lightTheme;
}
