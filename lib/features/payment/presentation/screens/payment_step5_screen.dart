import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/shared/components/custom_button.dart';
import 'package:neves_capital/shared/components/custom_loading.dart';
import 'package:neves_capital/shared/helpers/format_helpers.dart';
import 'package:neves_capital/features/payment/data/services/pagarme_service.dart';
import 'payment_result_screen.dart';

/// Tela 5: Resumo da operação
class PaymentStep5Screen extends StatefulWidget {
  final String nomeEstabelecimento;
  final String ramoAtuacao;
  final int valorCentavos;
  final String chavePix;
  final String tipoChavePix;
  final String nomeTitular;
  final String numeroCartao;
  final String cvv;
  final String vencimento;

  const PaymentStep5Screen({
    Key? key,
    required this.nomeEstabelecimento,
    required this.ramoAtuacao,
    required this.valorCentavos,
    required this.chavePix,
    required this.tipoChavePix,
    required this.nomeTitular,
    required this.numeroCartao,
    required this.cvv,
    required this.vencimento,
  }) : super(key: key);

  @override
  State<PaymentStep5Screen> createState() => _PaymentStep5ScreenState();
}

class _PaymentStep5ScreenState extends State<PaymentStep5Screen> {
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
                            
                            // Ramo de Atuação
                            _buildInfoRow(
                              'Ramo de Atuação',
                              _getRamoAtuacaoText(widget.ramoAtuacao),
                            ),
                            const SizedBox(height: 16),
                            
                            // Chave Pix
                            _buildInfoRow(
                              'Chave Pix',
                              widget.chavePix,
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
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 24 : 16,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? Theme.of(context).primaryColor : Colors.white,
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

  String _getRamoAtuacaoText(String ramo) {
    switch (ramo) {
      case 'varejo':
        return 'Varejo';
      case 'atacado':
        return 'Atacado';
      case 'servicos':
        return 'Serviços';
      case 'restaurante':
        return 'Restaurante';
      case 'farmacia':
        return 'Farmácia';
      case 'posto':
        return 'Posto de Combustível';
      case 'outros':
        return 'Outros';
      default:
        return ramo;
    }
  }
}
