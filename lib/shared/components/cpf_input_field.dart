import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../helpers/cpf_helper.dart';

/// Widget de input com máscara de CPF
class CpfInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool autofocus;
  final VoidCallback? onChanged;
  final VoidCallback? onFocusLost;

  const CpfInputField({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onFocusLost,
  });

  @override
  State<CpfInputField> createState() => _CpfInputFieldState();
}

class _CpfInputFieldState extends State<CpfInputField> {
  late TextEditingController _maskedController;
  late FocusNode _focusNode;
  bool _hasValidated = false;
  final GlobalKey<FormFieldState> _fieldKey = GlobalKey<FormFieldState>();

  @override
  void initState() {
    super.initState();
    _maskedController = TextEditingController();
    _focusNode = FocusNode();
    
    // Inicializa com valor formatado se já houver
    if (widget.controller.text.isNotEmpty) {
      _maskedController.text = CpfHelper.formatCpf(widget.controller.text);
    }
    
    // Listener para sincronizar com o controller externo
    widget.controller.addListener(_syncController);
    
    // Listener para detectar perda de foco
    _focusNode.addListener(_onFocusChanged);
    
    // Solicitar foco após o primeiro frame se autofocus estiver ativado
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncController);
    _focusNode.removeListener(_onFocusChanged);
    _maskedController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncController() {
    if (widget.controller.text != CpfHelper.getCpfNumbers(_maskedController.text)) {
      _maskedController.text = CpfHelper.formatCpf(widget.controller.text);
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
        final isValid = CpfHelper.validateCpf(_maskedController.text) == null;
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
    final cleanValue = CpfHelper.cleanCpf(value);
    
    // Limita a 11 dígitos
    final limitedValue = cleanValue.length > 11 
        ? cleanValue.substring(0, 11) 
        : cleanValue;
    
    // Formata o CPF
    final formattedValue = CpfHelper.formatCpf(limitedValue);
    
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

  String? _validateCpfOnFocusLost(String? value) {
    // Só valida se já perdeu o foco pelo menos uma vez
    if (!_hasValidated) {
      return null;
    }
    
    // Usa o validador personalizado se fornecido, senão usa o padrão
    if (widget.validator != null) {
      return widget.validator!(value);
    }
    
    return CpfHelper.validateCpf(value);
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
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              // Fechar teclado quando usuário pressionar "OK" ou "Done"
              _focusNode.unfocus();
            },
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(14), // xxx.xxx.xxx-xx = 14 caracteres
            ],
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
            ),
            validator: _validateCpfOnFocusLost,
            onChanged: _onTextChanged,
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Digite seu CPF',
              hintStyle: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 16,
              ),
              prefixIcon: const Icon(
                Icons.person_outline,
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
