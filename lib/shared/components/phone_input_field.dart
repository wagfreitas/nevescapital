import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../helpers/phone_helper.dart';

/// Widget de input com máscara de Telefone
class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final String? Function(String?)? validator;
  final bool enabled;
  final VoidCallback? onChanged;
  final VoidCallback? onFocusLost;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.validator,
    this.enabled = true,
    this.onChanged,
    this.onFocusLost,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late TextEditingController _maskedController;
  late FocusNode _focusNode;
  bool _hasValidated = false;
  final GlobalKey<FormFieldState> _fieldKey = GlobalKey<FormFieldState>();

  @override
  void initState() {
    super.initState();
    _maskedController = TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    // Inicializa com valor formatado se já houver
    if (widget.controller.text.isNotEmpty) {
      _maskedController.text = PhoneHelper.formatPhone(widget.controller.text);
    }

    // Listener para sincronizar com o controller externo
    widget.controller.addListener(_syncController);

    // Listener para detectar perda de foco
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncController);
    _focusNode.removeListener(_onFocusChanged);
    _maskedController.dispose();
    // Só dispose do focusNode se foi criado internamente
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _syncController() {
    if (widget.controller.text !=
        PhoneHelper.getPhoneNumbers(_maskedController.text)) {
      _maskedController.text = PhoneHelper.formatPhone(widget.controller.text);
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Campo perdeu o foco
      if (!_hasValidated) {
        _hasValidated = true;
      }

      widget.onFocusLost?.call();

      // Força a validação do campo específico
      if (mounted) {
        final isValid =
            PhoneHelper.validatePhone(_maskedController.text) == null;
        if (isValid) {
          // Se válido, limpa o erro
          _fieldKey.currentState?.validate();
          setState(() {
            // Força rebuild para limpar erro visual
          });
        } else {
          // Se inválido, mostra erro
          _fieldKey.currentState?.validate();
        }
      }
    }
  }

  void _onTextChanged(String value) {
    // Remove caracteres não numéricos
    final cleanValue = PhoneHelper.cleanPhone(value);

    // Limita a 11 dígitos
    final limitedValue =
        cleanValue.length > 11 ? cleanValue.substring(0, 11) : cleanValue;

    // Formata o telefone
    final formattedValue = PhoneHelper.formatPhone(limitedValue);

    // Atualiza o controller mascarado
    if (_maskedController.text != formattedValue) {
      _maskedController.text = formattedValue;
      _maskedController.selection = TextSelection.collapsed(
        offset: formattedValue.length,
      );
    }

    // Atualiza o controller externo com apenas os números
    widget.controller.text = limitedValue;

    // Chama callback se fornecido
    widget.onChanged?.call();
  }

  String? _validatePhoneOnFocusLost(String? value) {
    // Só valida se já perdeu o foco pelo menos uma vez
    if (!_hasValidated) {
      return null;
    }

    // Usa o validador personalizado se fornecido, senão usa o padrão
    if (widget.validator != null) {
      return widget.validator!(value);
    }

    return PhoneHelper.validatePhone(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: TextFormField(
            key: _fieldKey,
            controller: _maskedController,
            focusNode: _focusNode,
            enabled: widget.enabled,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(
                  15), // (xx)xxxxx-xxxx = 15 caracteres
            ],
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
            ),
            validator: _validatePhoneOnFocusLost,
            onChanged: _onTextChanged,
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Digite seu telefone',
              hintStyle: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 16,
              ),
              prefixIcon: const Icon(
                Icons.phone_outlined,
                color: Colors.white,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.white),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.white),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: AppTheme.errorColor,
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: AppTheme.errorColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
