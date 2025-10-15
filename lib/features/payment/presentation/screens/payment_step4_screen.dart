import 'package:flutter/material.dart';
import 'package:neves_capital/shared/components/custom_button.dart';
import 'package:neves_capital/shared/components/custom_loading.dart';
import 'package:neves_capital/shared/helpers/format_helpers.dart';
import 'package:neves_capital/features/payment/data/services/pagarme_service.dart';
import 'payment_result_screen.dart';

/// Tela 4: Resumo e confirmação da venda
class PaymentStep4Screen extends StatefulWidget {
  final String nomeEstabelecimento;
  final int valorCentavos;
  final String nomeTitular;
  final String numeroCartao;
  final String cvv;
  final String vencimento;

  const PaymentStep4Screen({
    Key? key,
    required this.nomeEstabelecimento,
    required this.valorCentavos,
    required this.nomeTitular,
    required this.numeroCartao,
    required this.cvv,
    required this.vencimento,
  }) : super(key: key);

  @override
  State<PaymentStep4Screen> createState() => _PaymentStep4ScreenState();
}

class _PaymentStep4ScreenState extends State<PaymentStep4Screen> {
  bool _isProcessing = false;

  Future<void> _concluirVenda() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final pagarmeService = PagarmeService();
      
      // Processar pagamento
      final resultado = await pagarmeService.processarPagamentoCartao(
        nomeEstabelecimento: widget.nomeEstabelecimento,
        valorCentavos: widget.valorCentavos,
        nomeTitular: widget.nomeTitular,
        numeroCartao: widget.numeroCartao,
        cvv: widget.cvv,
        vencimento: widget.vencimento,
      );

      if (!mounted) return;

      // Navegar para tela de resultado
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentResultScreen(
            sucesso: resultado['success'] ?? false,
            mensagem: resultado['message'] ?? 'Erro desconhecido',
            transactionId: resultado['transactionId'],
            valorCentavos: widget.valorCentavos,
            nomeEstabelecimento: widget.nomeEstabelecimento,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar pagamento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final valorFormatado = FormatHelpers.formatCurrency(widget.valorCentavos / 100);
    final numeroCartaoMascarado = _mascararCartao(widget.numeroCartao);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fazer uma Venda'),
        centerTitle: true,
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomLoading(),
                  SizedBox(height: 24),
                  Text(
                    'Processando pagamento...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aguarde enquanto validamos os dados',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Título
                    const Text(
                      'RESUMO DA OPERAÇÃO',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Card de resumo
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Valor da Venda
                            _buildInfoRow(
                              'Valor da Venda',
                              valorFormatado,
                              isHighlight: true,
                            ),
                            const Divider(height: 32),
                            
                            // Nome do Estabelecimento
                            _buildInfoRow(
                              'Estabelecimento',
                              widget.nomeEstabelecimento,
                            ),
                            const SizedBox(height: 16),
                            
                            // Dados do Cartão
                            _buildInfoRow(
                              'Titular do Cartão',
                              widget.nomeTitular,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildInfoRow(
                              'Cartão',
                              numeroCartaoMascarado,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const Spacer(),

                    // Botão Concluir Venda
                    CustomButton(
                      text: 'Concluir Venda',
                      onPressed: _concluirVenda,
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
                    
                    // Aviso
                    const Text(
                      'Ao concluir, o pagamento será processado imediatamente',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 24 : 16,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? Theme.of(context).primaryColor : Colors.black87,
          ),
        ),
      ],
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

  String _mascararCartao(String numeroCartao) {
    if (numeroCartao.length < 4) return numeroCartao;
    final ultimos4 = numeroCartao.substring(numeroCartao.length - 4);
    return '**** **** **** $ultimos4';
  }
}

