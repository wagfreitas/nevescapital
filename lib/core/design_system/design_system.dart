import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Design System da aplicação Pag Pag
/// 
/// Define padrões consistentes para botões, cards, espaçamentos e outros elementos
class DesignSystem {
  // ============================================
  // BOTÕES
  // ============================================
  
  /// Altura padrão dos botões
  static const double buttonHeight = 56.0;
  
  /// Altura dos botões pequenos
  static const double buttonHeightSmall = 48.0;
  
  /// Border radius padrão dos botões
  static const double buttonBorderRadius = 12.0;
  
  /// Estilo padrão do texto dos botões
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  /// Estilo do texto dos botões pequenos
  static const TextStyle buttonTextStyleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  /// Cores padrão dos botões primários
  static const Color buttonPrimaryBackground = AppTheme.primaryColor;
  static const Color buttonPrimaryForeground = AppTheme.backgroundColor;
  
  /// Cores padrão dos botões secundários (outlined)
  static const Color buttonSecondaryForeground = AppTheme.textPrimary;
  static const Color buttonSecondaryBorder = AppTheme.borderColor;
  
  /// Padding padrão dos botões
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 16,
  );
  
  // ============================================
  // CARDS
  // ============================================
  
  /// Border radius padrão dos cards
  static const double cardBorderRadius = 12.0;
  
  /// Padding padrão dos cards
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  
  // ============================================
  // ESPAÇAMENTOS
  // ============================================
  
  /// Espaçamentos padrão
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 40.0;
  
  // ============================================
  // BORDER RADIUS
  // ============================================
  
  static const double radiusSM = 4.0;
  static const double radiusMD = 8.0;
  static const double radiusLG = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusRound = 25.0;
  
  // ============================================
  // HELPERS
  // ============================================
  
  /// Formata texto do botão (capitaliza primeira letra de cada palavra)
  /// Padrão: Primeira letra de cada palavra maiúscula, resto minúsculas
  /// Exemplo: "Salvar Alterações", "Confirmar", "Retornar", "Alterar"
  static String formatButtonText(String text) {
    if (text.isEmpty) return text;
    
    // Divide por espaços e capitaliza cada palavra
    final words = text.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).toList();
    
    return capitalizedWords.join(' ');
  }
}

