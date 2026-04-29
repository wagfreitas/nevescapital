import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/custom_button.dart';

/// Tela de conclusão da venda
class SaleCompletionScreen extends StatelessWidget {
  final bool pixSuccess;
  final String? pixMessage;

  const SaleCompletionScreen({
    super.key,
    this.pixSuccess = true,
    this.pixMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                pixSuccess ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                size: 100,
                color: pixSuccess ? AppTheme.primaryColor : Colors.orange,
              ),
              const SizedBox(height: 32),
              Text(
                pixSuccess
                    ? 'Parabéns! Você concluiu mais uma venda com a PagPag!'
                    : 'Venda registrada, mas houve um problema no envio do PIX.',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              if (pixMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (pixSuccess ? AppTheme.primaryColor : Colors.orange)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pixSuccess ? Icons.pix : Icons.info_outline,
                        color: pixSuccess ? AppTheme.primaryColor : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pixMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            color: pixSuccess ? AppTheme.primaryColor : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 60),
              CustomButton(
                text: 'Fechar',
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
