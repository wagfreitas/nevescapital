import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/shared/components/custom_button.dart';
import 'package:neves_capital/shared/helpers/card_brand_detector.dart';
import 'package:neves_capital/shared/helpers/card_brand_image_loader.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/core/utils/card_validator.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import '../helpers/payment_step_helper.dart';
// import 'package:credit_card_scanner/credit_card_scanner.dart'; // TEMPORARIAMENTE DESABILITADO
import 'payment_step5_screen.dart';

/// Tela 4: Inserir dados do cartão
class PaymentStep4Screen extends StatefulWidget {
  final String nomeEstabelecimento;
  final String ramoAtuacao;
  final int valorCentavos;
  final String chavePix;
  final String tipoChavePix;
  final bool hasAccount;

  const PaymentStep4Screen({
    super.key,
    required this.nomeEstabelecimento,
    required this.ramoAtuacao,
    required this.valorCentavos,
    required this.chavePix,
    required this.tipoChavePix,
    required this.hasAccount,
  });

  @override
  State<PaymentStep4Screen> createState() => _PaymentStep4ScreenState();
}

class _PaymentStep4ScreenState extends State<PaymentStep4Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeTitularController = TextEditingController();
  final _numeroCartaoController = TextEditingController();
  final _cvvController = TextEditingController();
  final _vencimentoController = TextEditingController();
  CardBrand _detectedBrand = CardBrand.unknown;
  bool _submitted = false;
  bool _cardNumberTouched = false;
  final _cardNumberFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Escutar mudanças no número do cartão para detectar a bandeira
    _numeroCartaoController.addListener(_detectCardBrand);
    // Marcar como tocado quando o campo do cartão perde o foco
    _cardNumberFocusNode.addListener(() {
      if (!_cardNumberFocusNode.hasFocus && !_cardNumberTouched) {
        setState(() => _cardNumberTouched = true);
      }
      // Revalidar o campo quando perde o foco
      if (!_cardNumberFocusNode.hasFocus && _cardNumberTouched) {
        _formKey.currentState?.validate();
      }
    });
  }

  @override
  void dispose() {
    _numeroCartaoController.removeListener(_detectCardBrand);
    _cardNumberFocusNode.dispose();
    _nomeTitularController.dispose();
    _numeroCartaoController.dispose();
    _cvvController.dispose();
    _vencimentoController.dispose();
    super.dispose();
  }

  void _detectCardBrand() {
    final cardNumber = _numeroCartaoController.text.replaceAll(' ', '');
    final digitsOnly = cardNumber.replaceAll(RegExp(r'\D'), '');

    // Mostrar bandeira somente a partir do 6º dígito
    if (digitsOnly.length < 6) {
      if (_detectedBrand != CardBrand.unknown) {
        setState(() => _detectedBrand = CardBrand.unknown);
      }
      return;
    }

    final detectedBrand = CardBrandDetector.detectBrand(cardNumber);

    if (detectedBrand != _detectedBrand) {
      setState(() {
        _detectedBrand = detectedBrand;
      });
      AppLogger.debug(
          'Bandeira detectada: ${CardBrandDetector.getBrandName(detectedBrand)}');
    }
  }

  // TEMPORARIAMENTE DESABILITADO - Conflito de dependências com Firebase
  // TODO: Procurar pacote OCR compatível ou implementar solução custom
  /*
  Future<void> _scanCard() async {
    try {
      AppLogger.debug('Iniciando scan de cartão...');
      
      final scanResult = await CreditCardScanner.scanCard();

      if (scanResult != null) {
        AppLogger.info('Cartão escaneado com sucesso!');
        // ... código de preenchimento ...
      }
    } catch (e) {
      AppLogger.error('Erro ao escanear cartão: $e');
    }
  }
  */

  void _continuar() {
    setState(() => _submitted = true);
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentStep5Screen(
            nomeEstabelecimento: widget.nomeEstabelecimento,
            ramoAtuacao: widget.ramoAtuacao,
            valorCentavos: widget.valorCentavos,
            chavePix: widget.chavePix,
            tipoChavePix: widget.tipoChavePix,
            nomeTitular: _nomeTitularController.text,
            numeroCartao: _numeroCartaoController.text.replaceAll(' ', ''),
            cvv: _cvvController.text,
            vencimento: _vencimentoController.text,
            hasAccount: widget.hasAccount,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcular passo atual baseado se tem conta ou não
    final currentStep = PaymentStepHelper.calculateCurrentStep(4, widget.hasAccount);
    final totalSteps = PaymentStepHelper.getTotalSteps(widget.hasAccount);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: GlassAppBar(
        title: const Text(
          'Dados do Cartão',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: PaymentStepHelper.buildProgressIndicator(currentStep, totalSteps),
          ),
        ),
      ),
      body: KeyboardDismissWrapper(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: SingleChildScrollView(
                    clipBehavior: Clip.none,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          // Nome Impresso no Cartão
                          TextFormField(
                  controller: _nomeTitularController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  keyboardAppearance: Brightness.dark,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nome Impresso no Cartão',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    filled: true,
                    fillColor: AppTheme.inputEditableBackgroundColor,
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _submitted ? 'Insira o nome do titular' : null;
                    }
                    if (value.length < 3) {
                      return _submitted ? 'Nome inválido' : null;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Número do Cartão
                TextFormField(
                  controller: _numeroCartaoController,
                  focusNode: _cardNumberFocusNode,
                  keyboardType: TextInputType.number,
                  keyboardAppearance: Brightness.dark,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: Colors.white),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(23), // margem para 19 dígitos + espaços
                    _CardNumberFormatter(), // Limita e agrupa conforme bandeira
                  ],
                  decoration: InputDecoration(
                    labelText: 'Número do Cartão',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    prefixIcon: Icon(Icons.credit_card, color: AppTheme.textSecondary),
                    suffixIcon: _detectedBrand != CardBrand.unknown
                        ? _buildCardBrandIcon(_detectedBrand)
                        : null,
                    filled: true,
                    fillColor: AppTheme.inputEditableBackgroundColor,
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: (value) {
                    // Vazio: só reclama em submit.
                    if (value == null || value.isEmpty) {
                      return _submitted ? 'Insira o número do cartão' : null;
                    }
                    final digits = value.replaceAll(' ', '');
                    final brand = CardBrandDetector.detectBrand(digits);
                    final expected = CardBrandDetector.getExpectedDigits(brand);

                    // Tamanho insuficiente: só reclama em submit.
                    // Enquanto o usuário ainda digita (length < expected),
                    // não polui a tela com erro.
                    if (digits.length < expected) {
                      return _submitted
                          ? 'O número do cartão deve ter $expected dígitos'
                          : null;
                    }

                    // Já completou a digitação: agora sim valida Luhn.
                    if (!CardValidator.isValidLuhn(digits)) {
                      return 'Número do cartão inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // CVV e Data de Vencimento (altura fixa para erro não desalinhar a caixa)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CVV
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 76,
                        child: TextFormField(
                        controller: _cvvController,
                        keyboardType: TextInputType.number,
                        keyboardAppearance: Brightness.dark,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Colors.white),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: InputDecoration(
                          labelText: 'CVV',
                          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          prefixIcon: Icon(Icons.lock, color: AppTheme.textSecondary),
                          filled: true,
                          fillColor: AppTheme.inputEditableBackgroundColor,
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
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return _submitted ? 'Insira o CVV' : null;
                          }
                          final expectedCvv =
                              CardBrandDetector.getCvvLength(_detectedBrand);
                          if (value.length < expectedCvv) {
                            return _submitted ? 'CVV inválido' : null;
                          }
                          return null;
                        },
                      ),
                    ),
                    ),
                    const SizedBox(width: 16),

                    // Data de Vencimento
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 76,
                        child: TextFormField(
                        controller: _vencimentoController,
                        keyboardType: TextInputType.number,
                        keyboardAppearance: Brightness.dark,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(color: Colors.white),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5), // MM/AA = 5 caracteres
                          _ExpiryDateFormatter(),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Data de Vencimento',
                          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                          hintText: 'MM/AA',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          prefixIcon: Icon(Icons.calendar_today, color: AppTheme.textSecondary),
                          filled: true,
                          fillColor: AppTheme.inputEditableBackgroundColor,
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
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return _submitted ? 'Insira a validade' : null;
                          }
                          if (value.length < 5) {
                            return _submitted ? 'Data inválida' : null;
                          }
                          final parts = value.split('/');
                          final month = int.tryParse(parts[0]) ?? 0;
                          if (month < 1 || month > 12) {
                            return 'Mês inválido';
                          }
                          final yearTwoDigits = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
                          final now = DateTime.now();
                          final fullYear = 2000 + (yearTwoDigits % 100);
                          if (fullYear < now.year || (fullYear == now.year && month < now.month)) {
                            return 'Cartão vencido';
                          }
                          return null;
                        },
                      ),
                    ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Aviso de segurança
                const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Seus dados estão protegidos com criptografia',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Avançar',
                onPressed: _continuar,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o ícone da bandeira do cartão para usar como suffixIcon
  Widget _buildCardBrandIcon(CardBrand brand) {
    final imageWidget = CardBrandImageLoader.getBrandImage(brand);
    
    if (imageWidget == null) {
      return _buildCardBrandFallback(brand);
    }
    
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: imageWidget,
    );
  }

  /// Fallback para bandeira quando não há imagem disponível
  Widget _buildCardBrandFallback(CardBrand brand) {
    String brandText;
    
    switch (brand) {
      case CardBrand.visa:
        brandText = 'VISA';
        break;
      case CardBrand.mastercard:
        brandText = 'MC';
        break;
      case CardBrand.elo:
        brandText = 'ELO';
        break;
      case CardBrand.amex:
        brandText = 'AMEX';
        break;
      case CardBrand.hipercard:
        brandText = 'HIPERCARD';
        break;
      case CardBrand.hiper:
        brandText = 'HIPER';
        break;
      case CardBrand.diners:
        brandText = 'DINERS';
        break;
      case CardBrand.discover:
        brandText = 'DISC';
        break;
      case CardBrand.jcb:
        brandText = 'JCB';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Text(
        brandText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

}

/// Formatador para número do cartão.
/// Limita e agrupa conforme a bandeira detectada:
/// Amex (15) → 4-6-5 | Diners (14) → 4-6-4 | Demais (16) → 4-4-4-4.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final brand = CardBrandDetector.detectBrand(digits);
    final maxDigits = CardBrandDetector.getMaxDigits(brand);
    final limited = digits.length > maxDigits
        ? digits.substring(0, maxDigits)
        : digits;
    final groups = CardBrandDetector.getGroupSizes(brand);

    final buffer = StringBuffer();
    int index = 0;
    for (final size in groups) {
      if (index >= limited.length) break;
      if (index > 0) buffer.write(' ');
      final end = (index + size) > limited.length ? limited.length : index + size;
      buffer.write(limited.substring(index, end));
      index = end;
    }
    // Se sobrarem dígitos além dos grupos definidos, acrescenta.
    if (index < limited.length) {
      buffer.write(limited.substring(index));
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatador para data de vencimento (MM/AA)
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 4; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
