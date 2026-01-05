import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';

/// Botão customizado da aplicação seguindo o Design System
/// 
/// **Padrão de texto:**
/// - Texto capitalizado (primeira letra de cada palavra maiúscula)
/// - Sempre no infinitivo (verbo no infinitivo)
/// 
/// **Exemplos corretos:**
/// - "Salvar Alterações"
/// - "Confirmar"
/// - "Retornar"
/// - "Alterar"
/// - "Finalizar Cadastro"
/// 
/// **Exemplos incorretos:**
/// - "Salvando" (não infinitivo)
/// - "CONFIRMAR" (tudo maiúsculo)
/// - "confirmar" (tudo minúsculo)
class CustomButton extends StatelessWidget {
  final String text; // Texto do botão (deve estar no infinitivo)
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double? height;
  final bool capitalizeText; // Se true, capitaliza primeira letra de cada palavra (padrão)
  
  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
    this.height,
    this.capitalizeText = true, // Padrão: capitaliza primeira letra
  });
  
  @override
  Widget build(BuildContext context) {
    // Texto já deve vir no infinitivo e capitalizado (ex: "Salvar Alterações")
    // Apenas garantimos que está capitalizado se necessário
    final effectiveText = capitalizeText ? DesignSystem.formatButtonText(text) : text;
    final effectiveHeight = height ?? DesignSystem.buttonHeight;
    
    return SizedBox(
      width: width ?? double.infinity,
      height: effectiveHeight,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor ?? DesignSystem.buttonSecondaryForeground,
                side: BorderSide(
                  color: backgroundColor ?? DesignSystem.buttonSecondaryBorder,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadius),
                ),
                padding: DesignSystem.buttonPadding,
                elevation: 0,
              ),
              child: _buildButtonContent(effectiveText, effectiveHeight),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor ?? DesignSystem.buttonPrimaryBackground,
                foregroundColor: textColor ?? DesignSystem.buttonPrimaryForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignSystem.buttonBorderRadius),
                ),
                padding: DesignSystem.buttonPadding,
                elevation: 0,
              ),
              child: _buildButtonContent(effectiveText, effectiveHeight),
            ),
    );
  }
  
  Widget _buildButtonContent(String displayText, double buttonHeight) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            textColor ?? DesignSystem.buttonPrimaryForeground,
          ),
        ),
      );
    }
    
    final textStyle = buttonHeight <= DesignSystem.buttonHeightSmall
        ? DesignSystem.buttonTextStyleSmall
        : DesignSystem.buttonTextStyle;
    
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            displayText,
            style: textStyle,
          ),
        ],
      );
    }
    
    return Text(
      displayText,
      style: textStyle,
    );
  }
}
