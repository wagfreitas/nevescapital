import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget que adiciona uma barra de ferramentas com botão "OK" acima do teclado numérico
/// Funciona apenas com Flutter, sem necessidade de código nativo
class NumberKeyboardToolbar extends StatelessWidget {
  final Widget child;
  final FocusNode? focusNode;
  final String doneText;
  final Color? toolbarColor;
  final Color? buttonColor;

  const NumberKeyboardToolbar({
    super.key,
    required this.child,
    this.focusNode,
    this.doneText = 'OK',
    this.toolbarColor,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return _KeyboardToolbarWrapper(
      focusNode: focusNode,
      doneText: doneText,
      toolbarColor: toolbarColor ?? const Color(0xFFD1D1D6), // Cor do fundo do teclado numérico iOS (não das teclas)
      buttonColor: buttonColor ?? const Color(0xFF007AFF), // Azul padrão iOS
      child: child,
    );
  }
}

class _KeyboardToolbarWrapper extends StatefulWidget {
  final Widget child;
  final FocusNode? focusNode;
  final String doneText;
  final Color toolbarColor;
  final Color buttonColor;

  const _KeyboardToolbarWrapper({
    required this.child,
    this.focusNode,
    required this.doneText,
    required this.toolbarColor,
    required this.buttonColor,
  });

  @override
  State<_KeyboardToolbarWrapper> createState() => _KeyboardToolbarWrapperState();
}

class _KeyboardToolbarWrapperState extends State<_KeyboardToolbarWrapper> {
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (widget.focusNode?.hasFocus ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showOverlay();
        }
      });
    } else {
      _removeOverlay();
    }
  }
  
  void _updateOverlay() {
    if (_overlayEntry != null && mounted) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          _KeyboardToolbarOverlay(
            focusNode: widget.focusNode,
            doneText: widget.doneText,
            toolbarColor: widget.toolbarColor,
            buttonColor: widget.buttonColor,
            onDismiss: _removeOverlay,
          ),
        ],
      ),
      maintainState: false,
      opaque: false,
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    // Escutar mudanças no MediaQuery para atualizar o overlay quando o teclado aparece/desaparece
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    // Atualizar overlay quando o teclado aparece/desaparece
    if (keyboardHeight > 0 && _overlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _overlayEntry != null) {
          _updateOverlay();
        }
      });
    }
    
    return widget.child;
  }
}

class _KeyboardToolbarOverlay extends StatefulWidget {
  final FocusNode? focusNode;
  final String doneText;
  final Color toolbarColor;
  final Color buttonColor;
  final VoidCallback onDismiss;

  const _KeyboardToolbarOverlay({
    this.focusNode,
    required this.doneText,
    required this.toolbarColor,
    required this.buttonColor,
    required this.onDismiss,
  });

  @override
  State<_KeyboardToolbarOverlay> createState() => _KeyboardToolbarOverlayState();
}

class _KeyboardToolbarOverlayState extends State<_KeyboardToolbarOverlay> {
  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (!(widget.focusNode?.hasFocus ?? false)) {
      widget.onDismiss();
    } else if (mounted) {
      // Forçar rebuild quando o foco muda para atualizar a posição do teclado
      setState(() {});
    }
  }

  void _handleDone() {
    // Fechar o teclado
    if (widget.focusNode != null) {
      widget.focusNode!.unfocus();
    } else {
      FocusScope.of(context).unfocus();
    }
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    // Usar MediaQuery.of(context) diretamente para escutar mudanças
    return MediaQuery.of(context).viewInsets.bottom > 0 &&
            (widget.focusNode?.hasFocus ?? false)
        ? Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).viewInsets.bottom,
            child: Material(
              color: widget.toolbarColor,
              elevation: 0,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: widget.toolbarColor,
                  // Removida a borda superior para integrar melhor com o teclado
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextButton(
                          onPressed: _handleDone,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            widget.doneText,
                            style: TextStyle(
                              color: widget.buttonColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}

/// Widget helper para envolver um TextField numérico com a toolbar
class NumberTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType keyboardType;
  final InputDecoration? decoration;
  final TextStyle? style;
  final bool readOnly;
  final VoidCallback? onChanged;
  final VoidCallback? onFieldSubmitted;
  final String doneText;
  final Color? toolbarColor;
  final Color? buttonColor;

  const NumberTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.validator,
    this.inputFormatters,
    this.keyboardType = TextInputType.number,
    this.decoration,
    this.style,
    this.readOnly = false,
    this.onChanged,
    this.onFieldSubmitted,
    this.doneText = 'OK',
    this.toolbarColor,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFocusNode = focusNode ?? FocusNode();

    return NumberKeyboardToolbar(
      focusNode: effectiveFocusNode,
      doneText: doneText,
      toolbarColor: toolbarColor,
      buttonColor: buttonColor,
      child: TextFormField(
        controller: controller,
        focusNode: effectiveFocusNode,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        readOnly: readOnly,
        style: style,
        decoration: decoration ??
            InputDecoration(
              labelText: labelText,
              hintText: hintText,
            ),
        onChanged: onChanged != null ? (_) => onChanged!() : null,
        onFieldSubmitted: onFieldSubmitted != null ? (_) => onFieldSubmitted!() : null,
      ),
    );
  }
}

