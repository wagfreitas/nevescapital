import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de texto customizado da aplicação
class CustomTextField extends StatelessWidget {
  final String? label;
  final String? labelText;
  final String? hint;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final TextStyle? style;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final void Function()? onSubmitted;
  final bool readOnly;
  
  const CustomTextField({
    super.key,
    this.label,
    this.labelText,
    this.hint,
    this.hintText,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
    this.onTap,
    this.focusNode,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.style,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
    this.readOnly = false,
  });
  
  @override
  Widget build(BuildContext context) {
    // Usar labelText ou label (compatibilidade)
    final effectiveLabel = labelText ?? label;
    // Usar hintText ou hint (compatibilidade)
    final effectiveHint = hintText ?? hint;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label como texto separado
        if (effectiveLabel != null) ...[
          Text(
            effectiveLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Campo de texto
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          readOnly: readOnly,
          onChanged: onChanged,
          onTap: onTap,
          focusNode: focusNode,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          textAlign: textAlign,
          style: style,
          autofocus: autofocus,
          textInputAction: textInputAction ?? (maxLines == 1 ? TextInputAction.done : TextInputAction.newline),
          onFieldSubmitted: onSubmitted != null 
              ? (_) => onSubmitted!() 
              : (maxLines == 1 
                  ? (_) {
                      // Fechar teclado quando usuário pressionar "OK" ou "Done"
                      FocusScope.of(context).unfocus();
                    }
                  : null),
          decoration: InputDecoration(
            hintText: effectiveHint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade500, width: 2),
            ),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade100,
          ),
        ),
      ],
    );
  }
}
