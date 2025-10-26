import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/shared/components/custom_button.dart';
import 'package:neves_capital/shared/components/custom_text_field.dart';
import 'payment_step5_screen.dart';

/// Tela 4: Inserir dados do cartão
class PaymentStep4Screen extends StatefulWidget {
  final String nomeEstabelecimento;
  final String ramoAtuacao;
  final int valorCentavos;
  final String chavePix;
  final String tipoChavePix;

  const PaymentStep4Screen({
    Key? key,
    required this.nomeEstabelecimento,
    required this.ramoAtuacao,
    required this.valorCentavos,
    required this.chavePix,
    required this.tipoChavePix,
  }) : super(key: key);

  @override
  State<PaymentStep4Screen> createState() => _PaymentStep4ScreenState();
}

class _PaymentStep4ScreenState extends State<PaymentStep4Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeTitularController = TextEditingController();
  final _numeroCartaoController = TextEditingController();
  final _cvvController = TextEditingController();
  final _vencimentoController = TextEditingController();

  @override
  void dispose() {
    _nomeTitularController.dispose();
    _numeroCartaoController.dispose();
    _cvvController.dispose();
    _vencimentoController.dispose();
    super.dispose();
  }

  void _continuar() {
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Título
                const Text(
                  'INSIRA OS DADOS DO CARTÃO:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Nome do Titular
                CustomTextField(
                  controller: _nomeTitularController,
                  hintText: 'Nome do Titular',
                  labelText: 'Nome do Titular',
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Insira o nome do titular';
                    }
                    if (value.length < 3) {
                      return 'Nome inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Número do Cartão
                CustomTextField(
                  controller: _numeroCartaoController,
                  hintText: 'Número do Cartão',
                  labelText: 'Número do Cartão',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    _CardNumberFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Insira o número do cartão';
                    }
                    final digits = value.replaceAll(' ', '');
                    if (digits.length < 13 || digits.length > 16) {
                      return 'Número do cartão inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // CVV e Data de Vencimento
                Row(
                  children: [
                    // CVV
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _cvvController,
                        hintText: 'CVV',
                        labelText: 'CVV',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Insira o CVV';
                          }
                          if (value.length < 3) {
                            return 'CVV inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Data de Vencimento
                    Expanded(
                      flex: 3,
                      child: CustomTextField(
                        controller: _vencimentoController,
                        hintText: 'Data de Vencimento',
                        labelText: 'Data de Vencimento',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          _ExpiryDateFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Insira a validade';
                          }
                          if (value.length != 5) {
                            return 'Data inválida';
                          }
                          final parts = value.split('/');
                          final month = int.tryParse(parts[0]) ?? 0;
                          if (month < 1 || month > 12) {
                            return 'Mês inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
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
                    _buildProgressDot(true),
                    _buildProgressLine(),
                    _buildProgressDot(true),
                  ],
                ),
                
                const SizedBox(height: 20),
                
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

/// Formatador para número do cartão (adiciona espaços)
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
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


