import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/shared/components/custom_button.dart';
import 'package:neves_capital/shared/components/custom_text_field.dart';
import 'package:neves_capital/shared/helpers/format_helpers.dart';
import 'payment_step3_screen.dart';

/// Tela 2: Inserir valor da venda
class PaymentStep2Screen extends StatefulWidget {
  final String nomeEstabelecimento;
  final String ramoAtuacao;

  const PaymentStep2Screen({
    Key? key,
    required this.nomeEstabelecimento,
    required this.ramoAtuacao,
  }) : super(key: key);

  @override
  State<PaymentStep2Screen> createState() => _PaymentStep2ScreenState();
}

class _PaymentStep2ScreenState extends State<PaymentStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  double _valorLiquido = 0.0;

  @override
  void initState() {
    super.initState();
    _valorController.addListener(_calcularValorLiquido);
  }

  @override
  void dispose() {
    _valorController.removeListener(_calcularValorLiquido);
    _valorController.dispose();
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
    
    // Aplicar taxa de desconto (exemplo: 3%)
    setState(() {
      _valorLiquido = valor * 0.97; // 97% do valor total
    });
  }

  void _continuar() {
    if (_formKey.currentState?.validate() ?? false) {
      // Remove formatação e converte para centavos
      final valorTexto = _valorController.text
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '')
          .trim();
      final valorCentavos = int.tryParse(valorTexto) ?? 0;

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
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '2/5',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título
                const Text(
                  'VALOR DA VENDA',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Campo de valor
                CustomTextField(
                  controller: _valorController,
                  hintText: 'R\$ 0,00',
                  labelText: 'Valor da Venda',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _CurrencyInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o valor da venda';
                    }
                    final valorTexto = value
                        .replaceAll('R\$', '')
                        .replaceAll('.', '')
                        .replaceAll(',', '')
                        .trim();
                    final valorCentavos = int.tryParse(valorTexto) ?? 0;
                    
                    if (valorCentavos < 100) {
                      return 'Valor mínimo: R\$ 1,00';
                    }
                    return null;
                  },
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
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
                      Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Você receberá líquido $valorLiquidoFormatado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),

                // Botão Avançar
                CustomButton(
                  text: 'Avançar',
                  onPressed: _continuar,
                ),
                
                const SizedBox(height: 20),
                
                // Indicador de progresso
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressDot(true),
                    _buildProgressLine(),
                    _buildProgressDot(true),
                    _buildProgressLine(),
                    _buildProgressDot(false),
                    _buildProgressLine(),
                    _buildProgressDot(false),
                    _buildProgressLine(),
                    _buildProgressDot(false),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'O valor líquido deverá ser calculado automaticamente com uma taxa de desconto definida em sistema',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDot(bool isActive) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Theme.of(context).primaryColor : Colors.grey[300],
      ),
    );
  }

  Widget _buildProgressLine() {
    return Container(
      width: 40,
      height: 2,
      color: Colors.grey[300],
    );
  }
}

/// Formatador para valor monetário (centavos)
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

    final intValue = int.parse(digitsOnly);
    final formatted = FormatHelpers.formatCurrency(intValue / 100);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}


