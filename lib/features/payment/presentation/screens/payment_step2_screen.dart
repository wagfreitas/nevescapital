import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/shared/components/custom_button.dart';
import 'package:neves_capital/shared/helpers/format_helpers.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import '../helpers/payment_step_helper.dart';
import 'payment_step3_screen.dart';

/// Tela 2: Inserir valor da venda
class PaymentStep2Screen extends StatefulWidget {
  final String nomeEstabelecimento;
  final String ramoAtuacao;
  final bool isFirstSale; // Indica se é a primeira venda (veio da tela 1)

  const PaymentStep2Screen({
    super.key,
    required this.nomeEstabelecimento,
    required this.ramoAtuacao,
    this.isFirstSale = false,
  });

  @override
  State<PaymentStep2Screen> createState() => _PaymentStep2ScreenState();
}

class _PaymentStep2ScreenState extends State<PaymentStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _valorFocusNode = FocusNode();
  double _valorLiquido = 0.0;
  bool _hasAccount = false;
  bool _isLoadingAccount = true;
  bool _isButtonEnabled = false;
  bool _triedSubmitEmpty = false;

  @override
  void initState() {
    super.initState();
    _valorController.addListener(_calcularValorLiquido);
    _checkUserAccount();
  }

  Future<void> _checkUserAccount() async {
    final hasAccount = await PaymentStepHelper.hasUserAccount();
    if (!mounted) return;
    
    setState(() {
      _hasAccount = hasAccount;
      _isLoadingAccount = false;
    });
    // Teclado já aberto ao entrar na tela (Valor da Venda)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && _valorFocusNode.canRequestFocus) {
          _valorFocusNode.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    _valorController.removeListener(_calcularValorLiquido);
    _valorController.dispose();
    _valorFocusNode.dispose();
    super.dispose();
  }

  void _calcularValorLiquido() {
    final valorTexto = _valorController.text
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    final valorCentavos = int.tryParse(valorTexto) ?? 0;
    final valor = valorCentavos / 100;
    
    // Verificar se o valor está dentro do range permitido (R$ 10,00 a R$ 5.000,00)
    final isValid = valorCentavos >= 1000 && valorCentavos <= 500000;
    
    // Limpar erro "inserir valor" quando o usuário começar a digitar
    setState(() {
      _valorLiquido = valor * 0.97; // 97% do valor total
      _isButtonEnabled = isValid;
      if (valorTexto.isNotEmpty) _triedSubmitEmpty = false;
    });
  }

  void _continuar() {
    final valorTexto = _valorController.text
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    if (valorTexto.isEmpty) {
      setState(() => _triedSubmitEmpty = true);
    }
    if (_formKey.currentState?.validate() ?? false) {
      // Remove formatação e converte para centavos (valorTexto já obtido acima se vazio)
      final valorTextoFinal = _valorController.text
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '')
          .trim();
      final valorCentavos = int.tryParse(valorTextoFinal) ?? 0;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentStep3Screen(
            nomeEstabelecimento: widget.nomeEstabelecimento,
            ramoAtuacao: widget.ramoAtuacao,
            valorCentavos: valorCentavos,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final valorLiquidoFormatado = FormatHelpers.formatCurrency(_valorLiquido);
    
    // Se é a primeira venda (veio da tela 1), tratar como se não tivesse conta
    // para fins de numeração dos passos (mostrar 2/5 ao invés de 1/4)
    final shouldTreatAsNoAccount = widget.isFirstSale;
    final effectiveHasAccount = shouldTreatAsNoAccount ? false : _hasAccount;
    
    // Calcular passo atual baseado se tem conta ou não
    final currentStep = PaymentStepHelper.calculateCurrentStep(2, effectiveHasAccount);
    final totalSteps = PaymentStepHelper.getTotalSteps(effectiveHasAccount);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(),
      body: _isLoadingAccount
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        const SizedBox(height: 40),
                        // Título centralizado
                        const Center(
                        child: Text(
                          'Valor da Venda',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Indicador de progresso com barras
                      PaymentStepHelper.buildProgressIndicator(currentStep, totalSteps),
                        const SizedBox(height: 32),

                  // Campo de valor (padronizado)
                  TextFormField(
                    controller: _valorController,
                    focusNode: _valorFocusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _CurrencyInputFormatter(),
                    ],
                    onChanged: (_) => _calcularValorLiquido(),
                    decoration: InputDecoration(
                      labelText: 'Valor da Venda',
                      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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
                        return _triedSubmitEmpty ? 'Por favor, insira o valor da venda' : null;
                      }
                      final valorTexto = value
                          .replaceAll('R\$', '')
                          .replaceAll('.', '')
                          .replaceAll(',', '')
                          .trim();
                      final valorCentavos = int.tryParse(valorTexto) ?? 0;
                      
                      // Valor mínimo: R$ 10,00 (1.000 centavos)
                      if (valorCentavos < 1000) {
                        return 'Valor mínimo: R\$ 10,00';
                      }
                      
                      // Valor máximo: R$ 5.000,00 (500.000 centavos)
                      if (valorCentavos > 500000) {
                        return 'Valor máximo: R\$ 5.000,00';
                      }
                      
                      return null;
                    },
                  ),
                const SizedBox(height: 20),
                
                // Valor líquido calculado
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Você receberá líquido $valorLiquidoFormatado',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                const Spacer(),
                // Botão Avançar
                CustomButton(
                  text: 'Avançar',
                  onPressed: _isButtonEnabled ? _continuar : null,
                ),
                const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

}

/// Formatador para valor monetário (centavos)
/// Limita a 6 dígitos (máximo R$9.999,99)
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove tudo que não é dígito
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Limitar a 6 dígitos (máximo R$9.999,99 = 999999 centavos)
    final limitedDigits = digitsOnly.length > 6 
        ? digitsOnly.substring(0, 6) 
        : digitsOnly;
    
    final intValue = int.parse(limitedDigits);
    final formatted = FormatHelpers.formatCurrency(intValue / 100);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}


