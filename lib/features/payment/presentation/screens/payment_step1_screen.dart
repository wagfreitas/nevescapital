import 'package:flutter/material.dart';
import 'package:neves_capital/shared/components/custom_button.dart';
import 'package:neves_capital/shared/components/custom_text_field.dart';
import 'payment_step2_screen.dart';

/// Tela 1: Inserir nome do estabelecimento e ramo de atuação
class PaymentStep1Screen extends StatefulWidget {
  const PaymentStep1Screen({Key? key}) : super(key: key);

  @override
  State<PaymentStep1Screen> createState() => _PaymentStep1ScreenState();
}

class _PaymentStep1ScreenState extends State<PaymentStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeEstabelecimentoController = TextEditingController();
  String? _ramoAtuacao;

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
            ramoAtuacao: _ramoAtuacao ?? '',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                '1/5',
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
                  'Seu Logo da Daniel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Campo de nome do estabelecimento
                CustomTextField(
                  controller: _nomeEstabelecimentoController,
                  hintText: 'Nome do Estabelecimento',
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
                const SizedBox(height: 20),

                // Campo de ramo de atuação (dropdown)
                DropdownButtonFormField<String>(
                  value: _ramoAtuacao,
                  decoration: const InputDecoration(
                    labelText: 'Selected option',
                    hintText: 'Selected option',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'varejo', child: Text('Varejo')),
                    DropdownMenuItem(value: 'atacado', child: Text('Atacado')),
                    DropdownMenuItem(value: 'servicos', child: Text('Serviços')),
                    DropdownMenuItem(value: 'restaurante', child: Text('Restaurante')),
                    DropdownMenuItem(value: 'farmacia', child: Text('Farmácia')),
                    DropdownMenuItem(value: 'posto', child: Text('Posto de Combustível')),
                    DropdownMenuItem(value: 'outros', child: Text('Outros')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _ramoAtuacao = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione o ramo de atuação';
                    }
                    return null;
                  },
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
                    _buildProgressDot(false),
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
                  'Essa tela deverá aparecer apenas na primeira venda do usuário',
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


