import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';

/// Indicador de progresso da jornada de cadastro (3 passos:
/// Dados Cadastrais, Endereço, Informações Pessoais / Documento).
/// Usado na [GlassAppBar.bottom] das telas step5, step6, step7 e step8.
class RegistrationProgressIndicator extends StatelessWidget {
  /// Passo atual (1, 2 ou 3). No step8 pode ser 3 (todos preenchidos).
  final int currentStep;

  /// Total de passos (sempre 3 nas telas com indicador).
  final int totalSteps;

  const RegistrationProgressIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  /// Widget para usar no [PreferredSizeWidget] da AppBar (bottom).
  static PreferredSizeWidget preferredSize(int currentStep, {int totalSteps = 3}) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: RegistrationProgressIndicator(
          currentStep: currentStep,
          totalSteps: totalSteps,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(totalSteps, (index) {
          final stepNumber = index + 1;
          final isActive = stepNumber <= currentStep;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primaryColor
                      : Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (index < totalSteps - 1) const SizedBox(width: 8),
            ],
          );
        }),
      ),
    );
  }
}
