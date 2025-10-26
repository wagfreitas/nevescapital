import 'package:flutter/material.dart';
import 'package:neves_capital/shared/components/custom_button.dart';
import 'payment_step4_screen.dart';

/// Tela 3: Escolher chave Pix - Conforme wireframe
class PaymentStep3Screen extends StatefulWidget {
  final String nomeEstabelecimento;
  final String ramoAtuacao;
  final int valorCentavos;

  const PaymentStep3Screen({
    Key? key,
    required this.nomeEstabelecimento,
    required this.ramoAtuacao,
    required this.valorCentavos,
  }) : super(key: key);

  @override
  State<PaymentStep3Screen> createState() => _PaymentStep3ScreenState();
}

class _PaymentStep3ScreenState extends State<PaymentStep3Screen> {
  String? _chavePixSelecionada;
  
  // Mock de chaves cadastradas - Em produção, virá do backend
  final List<String> _chavesCadastradas = [
    'Chave Pix Cadastrada 1',
    'Chave Pix Cadastrada 2',
  ];

  void _continuar() {
    if (_chavePixSelecionada == null || _chavePixSelecionada!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma chave PIX'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentStep4Screen(
          nomeEstabelecimento: widget.nomeEstabelecimento,
          ramoAtuacao: widget.ramoAtuacao,
          valorCentavos: widget.valorCentavos,
          chavePix: _chavePixSelecionada!,
          tipoChavePix: 'cadastrada',
        ),
      ),
    );
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
                '3/5',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Título
              const Text(
                'Em qual chave PIX deseja receber a sua venda de hoje?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Botões de chaves cadastradas
              ...List.generate(_chavesCadastradas.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildChavePixButton(_chavesCadastradas[index]),
                );
              }),
              
              const SizedBox(height: 16),
              
              // Botão para cadastrar nova chave
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Navegar para tela de cadastro de chave PIX
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Funcionalidade em desenvolvimento'),
                    ),
                  );
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Cadastre uma Nova Chave Pix'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Theme.of(context).primaryColor),
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
    );
  }

  Widget _buildChavePixButton(String chavePix) {
    final isSelected = _chavePixSelecionada == chavePix;
    
    return InkWell(
      onTap: () {
        setState(() {
          _chavePixSelecionada = chavePix;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                chavePix,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                ),
              ),
            ),
          ],
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
