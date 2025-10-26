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

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fazer uma Venda',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
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
                  'INSIRA O VALOR DA VENDA',
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
                const SizedBox(height: 40),

                // Botão Continuar
                CustomButton(
                  text: 'Continuar',
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
                  ],
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


