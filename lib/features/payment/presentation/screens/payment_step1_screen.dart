import 'package:flutter/material.dart';
import 'package:neves_capital/shared/components/custom_button.dart';
import 'package:neves_capital/shared/components/custom_text_field.dart';
import 'payment_step2_screen.dart';

/// Tela 1: Inserir nome do estabelecimento
class PaymentStep1Screen extends StatefulWidget {
  const PaymentStep1Screen({Key? key}) : super(key: key);

  @override
  State<PaymentStep1Screen> createState() => _PaymentStep1ScreenState();
}

class _PaymentStep1ScreenState extends State<PaymentStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeEstabelecimentoController = TextEditingController();

  @override
  void dispose() {
    _nomeEstabelecimentoController.dispose();
    super.dispose();
  }

  void _continuar() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentStep2Screen(
            nomeEstabelecimento: _nomeEstabelecimentoController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fazer uma Venda'),
        centerTitle: true,
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
                  'INSIRA O NOME DO ESTABELECIMENTO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Campo de texto
                CustomTextField(
                  controller: _nomeEstabelecimentoController,
                  hintText: 'Ex: Loja do Daniel',
                  labelText: 'Nome do Estabelecimento',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o nome do estabelecimento';
                    }
                    if (value.length < 3) {
                      return 'Nome deve ter pelo menos 3 caracteres';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
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
                    _buildProgressDot(false),
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

