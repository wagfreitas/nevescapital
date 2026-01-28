import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import '../../core/theme/app_theme.dart';
import '../helpers/phone_helper.dart';
import '../data/country_names_pt.dart';

/// Widget de input com máscara de Telefone e seleção de país
class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onChanged;
  final VoidCallback? onFocusLost;
  final Country? initialCountry;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.readOnly = false,
    this.onChanged,
    this.onFocusLost,
    this.initialCountry,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late TextEditingController _maskedController;
  late FocusNode _focusNode;
  bool _hasValidated = false;
  bool _hasError = false;
  final GlobalKey<FormFieldState> _fieldKey = GlobalKey<FormFieldState>();
  Country _selectedCountry = Country.parse('BR'); // Brasil como padrão

  @override
  void initState() {
    super.initState();
    _maskedController = TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    
    // Define o país inicial
    if (widget.initialCountry != null) {
      _selectedCountry = widget.initialCountry!;
    }

    // Inicializa com valor formatado se já houver
    if (widget.controller.text.isNotEmpty) {
      final phoneNumbers = PhoneHelper.getPhoneNumbers(widget.controller.text);
      // Remove o código do país se presente
      String phoneWithoutCountryCode = phoneNumbers;
      if (phoneNumbers.startsWith(_selectedCountry.phoneCode)) {
        phoneWithoutCountryCode = phoneNumbers.substring(_selectedCountry.phoneCode.length);
      }
      _maskedController.text = _formatPhoneForCountry(phoneWithoutCountryCode, _selectedCountry);
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
    // Só dispose do focusNode se foi criado internamente
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _syncController() {
    // Remove o código do país do controller externo antes de comparar
    final externalPhone = PhoneHelper.getPhoneNumbers(widget.controller.text);
    final maskedPhone = PhoneHelper.getPhoneNumbers(_maskedController.text);
    
    // Se o controller externo tem código do país, remove antes de comparar
    String phoneWithoutCountryCode = externalPhone;
    if (externalPhone.startsWith(_selectedCountry.phoneCode)) {
      phoneWithoutCountryCode = externalPhone.substring(_selectedCountry.phoneCode.length);
    }
    
    if (phoneWithoutCountryCode != maskedPhone) {
      _maskedController.text = _formatPhoneForCountry(phoneWithoutCountryCode, _selectedCountry);
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
        _fieldKey.currentState?.validate();
        // Atualiza estado de erro após validação
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final hasError = _fieldKey.currentState?.hasError ?? false;
            if (hasError != _hasError) {
              setState(() {
                _hasError = hasError;
              });
            }
          }
        });
      }
    }
  }

  void _onTextChanged(String value) {
    // Remove caracteres não numéricos
    final cleanValue = PhoneHelper.cleanPhone(value);

    // Limita baseado no país selecionado
    int maxDigits = _getMaxDigitsForCountry(_selectedCountry);
    final limitedValue =
        cleanValue.length > maxDigits ? cleanValue.substring(0, maxDigits) : cleanValue;

    // Formata o telefone baseado no país (só aplica máscara para Brasil)
    final formattedValue = _formatPhoneForCountry(limitedValue, _selectedCountry);

    // Atualiza o controller mascarado
    if (_maskedController.text != formattedValue) {
      _maskedController.text = formattedValue;
      _maskedController.selection = TextSelection.collapsed(
        offset: formattedValue.length,
      );
    }

    // Atualiza o controller externo com apenas os números (incluindo código do país)
    // Só adiciona o código do país se houver números digitados
    if (limitedValue.isNotEmpty) {
      final fullPhone = '${_selectedCountry.phoneCode}$limitedValue';
      widget.controller.text = fullPhone;
    } else {
      widget.controller.text = '';
    }

    // Chama callback se fornecido
    widget.onChanged?.call();
  }

  int _getMaxDigitsForCountry(Country country) {
    // Retorna o número máximo de dígitos baseado no país
    // Brasil: 11 dígitos (2 DDD + 9 dígitos)
    if (country.countryCode == 'BR') {
      return 11;
    }
    // Outros países: padrão de 15 dígitos
    return 15;
  }

  String _formatPhoneForCountry(String phone, Country country) {
    if (phone.isEmpty) return '';
    
    // Formatação específica para Brasil (com máscara)
    if (country.countryCode == 'BR') {
      if (phone.length <= 2) {
        return '($phone';
      } else if (phone.length <= 7) {
        return '(${phone.substring(0, 2)})${phone.substring(2)}';
      } else if (phone.length <= 11) {
        return '(${phone.substring(0, 2)})${phone.substring(2, 7)}-${phone.substring(7)}';
      } else {
        final limitedPhone = phone.substring(0, 11);
        return '(${limitedPhone.substring(0, 2)})${limitedPhone.substring(2, 7)}-${limitedPhone.substring(7)}';
      }
    }
    
    // Para outros países: retorna apenas os números sem máscara
    return phone;
  }

  /// Retorna o texto de hint/placeholder baseado no país selecionado
  String _getHintTextForCountry(Country country) {
    if (country.countryCode == 'BR') {
      return '(00) 00000-0000';
    }
    // Para outros países: sem máscara
    return 'Digite seu telefone';
  }

  void _showCountryPicker() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _CountryPickerDialog(
        selectedCountry: _selectedCountry,
        onSelect: (Country country) {
          final oldCountry = _selectedCountry;
          setState(() {
            _selectedCountry = country;
          });
          
          // Se o país mudou, limpa o campo e força reconstrução
          if (oldCountry.countryCode != country.countryCode) {
            // Limpa o campo quando muda de país
            _maskedController.clear();
            widget.controller.clear();
            // Força reconstrução do campo
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  // Força rebuild do InputDecoration
                });
              }
            });
          } else {
            // Atualiza o campo com o novo código do país
            _onTextChanged(_maskedController.text.replaceAll(RegExp(r'[^0-9]'), ''));
          }
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  String? _validatePhoneOnFocusLost(String? value) {
    // Só valida se já perdeu o foco pelo menos uma vez
    if (!_hasValidated) {
      return null;
    }

    // Usa o validador personalizado se fornecido
    if (widget.validator != null) {
      final error = widget.validator!(value);
      // Atualiza estado de erro após o frame para evitar mudanças de layout
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _hasError = error != null;
            });
          }
        });
      }
      return error;
    }

    // Validação baseada no país selecionado
    String? error;
    if (_selectedCountry.countryCode == 'BR') {
      // Para Brasil: usa validação específica brasileira
      error = PhoneHelper.validatePhone(value);
    } else {
      // Para outros países: validação genérica (apenas verifica se tem números)
      if (value == null || value.isEmpty) {
        error = 'Telefone é obrigatório';
      } else {
        final cleanValue = PhoneHelper.cleanPhone(value);
        if (cleanValue.isEmpty) {
          error = 'Digite um número de telefone válido';
        } else if (cleanValue.length < 5) {
          error = 'Telefone muito curto';
        }
      }
    }

    // Atualiza estado de erro após o frame para evitar mudanças de layout
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasError = error != null;
          });
        }
      });
    }

    return error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mensagem de erro acima dos campos
          SizedBox(
            height: 24, // Altura fixa para reservar espaço
            child: Builder(
              builder: (context) {
                final errorText = _fieldKey.currentState?.errorText;
                if (errorText != null && errorText.isNotEmpty && _hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
                    child: Text(
                      errorText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        height: 1.4,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Botão de seleção de país
                GestureDetector(
                  onTap: widget.enabled && !widget.readOnly ? _showCountryPicker : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    height: 56, // Altura fixa para evitar mudanças de tamanho
                    decoration: BoxDecoration(
                      color: AppTheme.inputEditableBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12), // Sempre fixo, não muda com erro
                      ),
                    ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCountry.flagEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '+${_selectedCountry.phoneCode}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                ),
                // Campo de texto do telefone
                Expanded(
                child: SizedBox(
                  height: 56, // Altura fixa igual ao seletor de país para manter alinhamento
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: double.infinity,
                      height: 56, // Altura fixa adicional para garantir consistência
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 56,
                          maxHeight: 56, // Altura fixa para evitar mudanças
                        ),
                        child: TextFormField(
                  key: ValueKey('phone_input_${_selectedCountry.countryCode}_${_fieldKey.hashCode}'),
                  controller: _maskedController,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    // Fechar teclado quando usuário pressionar "OK" ou "Done"
                    _focusNode.unfocus();
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  keyboardAppearance: Brightness.dark,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.0, // Altura de linha fixa para alinhamento
                  ),
                    validator: (value) {
                      final error = _validatePhoneOnFocusLost(value);
                      // Atualiza estado de erro após validação
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          final currentHasError = _fieldKey.currentState?.hasError ?? false;
                          if (currentHasError != _hasError) {
                            setState(() {
                              _hasError = currentHasError;
                            });
                          }
                        }
                      });
                      return error;
                    },
                    onChanged: (value) {
                      _onTextChanged(value);
                      // Limpa erro quando usuário começa a digitar
                      if (_hasError && mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            final currentHasError = _fieldKey.currentState?.hasError ?? false;
                            if (!currentHasError && _hasError) {
                              setState(() {
                                _hasError = false;
                              });
                            }
                          }
                        });
                      }
                    },
                    decoration: () {
                      // Recalcula o hintText baseado no país atual - inline para garantir atualização
                      // Se o país não for Brasil, sempre usa o hintText calculado baseado no país
                      // Se for Brasil e widget.hintText estiver definido, usa o widget.hintText
                      final hintText = _selectedCountry.countryCode == 'BR' 
                          ? (widget.hintText ?? _getHintTextForCountry(_selectedCountry))
                          : _getHintTextForCountry(_selectedCountry);
                      
                      return InputDecoration(
                        labelText: widget.labelText,
                        labelStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never, // Nunca flutua para evitar mudanças de layout
                        hintText: hintText,
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 16,
                          height: 1.0, // Altura fixa para evitar mudanças
                        ),
                        filled: true,
                        fillColor: AppTheme.inputEditableBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12.0),
                            bottomRight: Radius.circular(12.0),
                          ),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12.0),
                            bottomRight: Radius.circular(12.0),
                          ),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1, // Largura fixa para evitar mudança de tamanho
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 22, // Padding vertical ajustado para manter altura fixa de 56px
                        ),
                        isDense: true, // Reduz espaçamento interno
                        errorText: null, // Sempre null para evitar espaço reservado para erro
                        errorStyle: const TextStyle(
                          fontSize: 0, // Ocultar erro padrão do TextFormField
                          height: 0,
                        ),
                        errorMaxLines: 1,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12.0),
                            bottomRight: Radius.circular(12.0), // Sempre fixo, não muda com erro
                          ),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor, // Verde quando recebe foco
                            width: 1, // Mesma largura que enabledBorder para evitar mudança de tamanho
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12.0),
                            bottomRight: Radius.circular(12.0), // Sempre fixo, não altera tamanho
                          ),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1, // Mesma largura que enabledBorder para evitar mudança de tamanho
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12.0),
                            bottomRight: Radius.circular(12.0), // Sempre fixo, não altera tamanho
                          ),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1, // Mesma largura que enabledBorder para evitar mudança de tamanho
                          ),
                        ),
                      );
                    }(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog customizado para seleção de país com botão de fechar
class _CountryPickerDialog extends StatefulWidget {
  final Country selectedCountry;
  final Function(Country) onSelect;

  const _CountryPickerDialog({
    required this.selectedCountry,
    required this.onSelect,
  });

  @override
  State<_CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<_CountryPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Country> _filteredCountries = [];
  List<Country> _allCountries = [];

  List<Country> _getAllCountries() {
    // Obter todos os países disponíveis do pacote country_picker
    // O pacote country_picker tem uma lista completa de países
    // Vamos usar showCountryPicker para obter a lista completa
    // Mas como não podemos chamar isso aqui, vamos usar uma lista completa de códigos ISO
    final allCountryCodes = [
      'AD', 'AE', 'AF', 'AG', 'AI', 'AL', 'AM', 'AO', 'AQ', 'AR',
      'AS', 'AT', 'AU', 'AW', 'AX', 'AZ', 'BA', 'BB', 'BD', 'BE',
      'BF', 'BG', 'BH', 'BI', 'BJ', 'BL', 'BM', 'BN', 'BO', 'BQ',
      'BR', 'BS', 'BT', 'BV', 'BW', 'BY', 'BZ', 'CA', 'CC', 'CD',
      'CF', 'CG', 'CH', 'CI', 'CK', 'CL', 'CM', 'CN', 'CO', 'CR',
      'CU', 'CV', 'CW', 'CX', 'CY', 'CZ', 'DE', 'DJ', 'DK', 'DM',
      'DO', 'DZ', 'EC', 'EE', 'EG', 'EH', 'ER', 'ES', 'ET', 'FI',
      'FJ', 'FK', 'FM', 'FO', 'FR', 'GA', 'GB', 'GD', 'GE', 'GF',
      'GG', 'GH', 'GI', 'GL', 'GM', 'GN', 'GP', 'GQ', 'GR', 'GS',
      'GT', 'GU', 'GW', 'GY', 'HK', 'HM', 'HN', 'HR', 'HT', 'HU',
      'ID', 'IE', 'IL', 'IM', 'IN', 'IO', 'IQ', 'IR', 'IS', 'IT',
      'JE', 'JM', 'JO', 'JP', 'KE', 'KG', 'KH', 'KI', 'KM', 'KN',
      'KP', 'KR', 'KW', 'KY', 'KZ', 'LA', 'LB', 'LC', 'LI', 'LK',
      'LR', 'LS', 'LT', 'LU', 'LV', 'LY', 'MA', 'MC', 'MD', 'ME',
      'MF', 'MG', 'MH', 'MK', 'ML', 'MM', 'MN', 'MO', 'MP', 'MQ',
      'MR', 'MS', 'MT', 'MU', 'MV', 'MW', 'MX', 'MY', 'MZ', 'NA',
      'NC', 'NE', 'NF', 'NG', 'NI', 'NL', 'NO', 'NP', 'NR', 'NU',
      'NZ', 'OM', 'PA', 'PE', 'PF', 'PG', 'PH', 'PK', 'PL', 'PM',
      'PN', 'PR', 'PS', 'PT', 'PW', 'PY', 'QA', 'RE', 'RO', 'RS',
      'RU', 'RW', 'SA', 'SB', 'SC', 'SD', 'SE', 'SG', 'SH', 'SI',
      'SJ', 'SK', 'SL', 'SM', 'SN', 'SO', 'SR', 'SS', 'ST', 'SV',
      'SX', 'SY', 'SZ', 'TC', 'TD', 'TF', 'TG', 'TH', 'TJ', 'TK',
      'TL', 'TM', 'TN', 'TO', 'TR', 'TT', 'TV', 'TW', 'TZ', 'UA',
      'UG', 'UM', 'US', 'UY', 'UZ', 'VA', 'VC', 'VE', 'VG', 'VI',
      'VN', 'VU', 'WF', 'WS', 'YE', 'YT', 'ZA', 'ZM', 'ZW',
    ];
    
    // Filtrar apenas países que podem ser parseados (têm código de telefone válido)
    final countries = <Country>[];
    for (final code in allCountryCodes) {
      try {
        final country = Country.parse(code);
        countries.add(country);
      } catch (e) {
        // Ignorar países que não podem ser parseados
        continue;
      }
    }
    return countries;
  }

  @override
  void initState() {
    super.initState();
    // Obter todos os países disponíveis
    _allCountries = _getAllCountries();
    _filteredCountries = _allCountries;
    // Ordenar com Brasil primeiro
    _filteredCountries.sort((a, b) {
      if (a.countryCode == 'BR') return -1;
      if (b.countryCode == 'BR') return 1;
      final nameA = CountryNamesPt.getName(a.countryCode);
      final nameB = CountryNamesPt.getName(b.countryCode);
      return nameA.compareTo(nameB);
    });
    _searchController.addListener(_filterCountries);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCountries);
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = List.from(_allCountries);
      } else {
        _filteredCountries = _allCountries.where((country) {
          final countryNamePt = CountryNamesPt.getName(country.countryCode);
          return countryNamePt.toLowerCase().contains(query) ||
              country.countryCode.toLowerCase().contains(query) ||
              country.phoneCode.contains(query);
        }).toList();
      }
      // Ordenar com Brasil primeiro
      _filteredCountries.sort((a, b) {
        if (a.countryCode == 'BR') return -1;
        if (b.countryCode == 'BR') return 1;
        final nameA = CountryNamesPt.getName(a.countryCode);
        final nameB = CountryNamesPt.getName(b.countryCode);
        return nameA.compareTo(nameB);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header com título e botão de fechar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Selecione o País',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
            ),
            // Campo de busca
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Buscar país...',
                  hintStyle: TextStyle(color: AppTheme.textPrimary.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.inputBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Lista de países
            Flexible(
              child: _filteredCountries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Nenhum país encontrado',
                          style: TextStyle(color: AppTheme.textPrimary.withValues(alpha: 0.5)),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = _filteredCountries[index];
                        final isSelected = country.countryCode == widget.selectedCountry.countryCode;
                        return ListTile(
                          leading: Text(
                            country.flagEmoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            CountryNamesPt.getName(country.countryCode),
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: Text(
                            '+${country.phoneCode}',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                          onTap: () => widget.onSelect(country),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
