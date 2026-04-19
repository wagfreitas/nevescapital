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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      // opaque: false para nao bloquear swipe-back do iOS
      behavior: HitTestBehavior.translucent,
      // Nao usar onHorizontalDragDown/onPanDown para nao interferir no swipe-back
      excludeFromSemantics: true,
      child: child,
    );
  }
}

/// Widget simplificado que envolve um unico campo de texto
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      child: child,
    );
  }
}
