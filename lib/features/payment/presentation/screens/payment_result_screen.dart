import 'package:flutter/material.dart';
import 'package:neves_capital/shared/components/custom_button.dart';
import 'package:neves_capital/shared/helpers/format_helpers.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

/// Tela 5: Resultado do pagamento
class PaymentResultScreen extends StatelessWidget {
  final bool sucesso;
  final String mensagem;
  final String? transactionId;
  final int valorCentavos;
  final String nomeEstabelecimento;

  const PaymentResultScreen({
    super.key,
    required this.sucesso,
    required this.mensagem,
    this.transactionId,
    required this.valorCentavos,
    required this.nomeEstabelecimento,
  });

  @override
  Widget build(BuildContext context) {
    final valorFormatado = FormatHelpers.formatCurrency(valorCentavos / 100);
    
    // Debug: Log do valor
    AppLogger.debug('PaymentResultScreen - valorCentavos: $valorCentavos');
    AppLogger.debug('PaymentResultScreen - valorFormatado: $valorFormatado');

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text(
          'Resultado da Venda',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[900],
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Ícone de sucesso/erro
                Icon(
                  sucesso ? Icons.check_circle : Icons.error,
                  size: 100,
                  color: sucesso ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 24),
                
                // Título
                Text(
                  sucesso ? 'Pagamento Aprovado!' : 'Pagamento Recusado',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: sucesso ? Colors.green : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Mensagem
                Text(
                  mensagem,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Card com detalhes
                Card(
                  elevation: 2,
                  color: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RESUMO DA OPERAÇÃO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                        const Divider(height: 24, color: Colors.grey),
                        
                        _buildInfoRow('Valor', valorFormatado),
                        const SizedBox(height: 12),
                        
                        _buildInfoRow('Estabelecimento', nomeEstabelecimento),
                        
                        if (transactionId != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow('ID da Transação', transactionId!),
                        ],
                        
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Data/Hora',
                          FormatHelpers.formatDateTime(DateTime.now()),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Botões
                if (sucesso) ...[
                  CustomButton(
                    text: 'Compartilhar Comprovante',
                    onPressed: () {
                      // TODO: Implementar compartilhamento
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidade em desenvolvimento'),
                        ),
                      );
                    },
                    isOutlined: true,
                  ),
                  const SizedBox(height: 16),
                ],
                
                CustomButton(
                  text: sucesso ? 'Nova Venda' : 'Tentar Novamente',
                  onPressed: () {
                    // Voltar para o início
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
                
                const SizedBox(height: 16),
                
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Voltar ao Início'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}