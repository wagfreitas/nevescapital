import 'package:flutter/material.dart';

/// Wrapper que permite fechar o teclado ao tocar fora dos campos
/// Versão simplificada sem dependência de pacotes externos
class KeyboardDismissWrapper extends StatelessWidget {
  final Widget child;
  final List<FocusNode> focusNodes;
  final String doneText;

  const KeyboardDismissWrapper({
    super.key,
    required this.child,
    this.focusNodes = const <FocusNode>[],
    this.doneText = 'OK',
  });

  @override
  Widget build(BuildContext context) {
    // Envolver com GestureDetector para fechar teclado ao tocar fora
    return GestureDetector(
      onTap: () {
        // Fechar teclado ao tocar em qualquer lugar
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent, // Permite que toques passem, mas captura áreas vazias
      child: child,
    );
  }
}

/// Widget simplificado que envolve um único campo de texto
class KeyboardDismissField extends StatelessWidget {
  final Widget child;
  final FocusNode focusNode;
  final String doneText;

  const KeyboardDismissField({
    super.key,
    required this.child,
    required this.focusNode,
    this.doneText = 'OK',
  });

  @override
  Widget build(BuildContext context) {
    // Envolver com GestureDetector para fechar teclado ao tocar fora
    return GestureDetector(
      onTap: () {
        // Fechar teclado ao tocar em qualquer lugar
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent, // Permite que toques passem, mas captura áreas vazias
      child: child,
    );
  }
}
