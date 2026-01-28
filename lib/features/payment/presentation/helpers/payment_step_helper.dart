import 'package:flutter/material.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/shared/services/secure_storage_service.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/core/theme/app_theme.dart';

/// Helper para calcular o passo atual na jornada de pagamento
/// baseado se o usuário já tem conta cadastrada ou não
class PaymentStepHelper {
  /// Verifica se o usuário já tem estabelecimento e ramo cadastrados
  static Future<bool> hasUserAccount() async {
    try {
      final cpf = await SecureStorageService.getLastCpf();
      if (cpf == null || cpf.isEmpty) {
        return false;
      }

      final userData = await FirestoreService.getUserByCpf(cpf);
      if (userData == null) {
        return false;
      }

      final storeName = userData['storeName'] as String?;
      final businessType = userData['businessType'] as String?;

      final hasStoreData = storeName != null && 
                          storeName.isNotEmpty && 
                          businessType != null && 
                          businessType.isNotEmpty;

      return hasStoreData;
    } catch (e) {
      AppLogger.error('Erro ao verificar se usuário tem conta', e);
      return false;
    }
  }

  /// Calcula o passo atual baseado na tela e se o usuário tem conta
  /// 
  /// [screenStep] é o número da tela (1, 2, 3, 4, 5)
  /// [hasAccount] indica se o usuário já tem conta cadastrada
  /// 
  /// Retorna o passo visual que deve ser mostrado (1, 2, 3, 4, 5)
  static int calculateCurrentStep(int screenStep, bool hasAccount) {
    if (hasAccount) {
      // Se tem conta, a tela 1 (Estabelecimento) não aparece
      // Tela 2 (Valor da Venda) = Passo 1
      // Tela 3 (Dados Bancários) = Passo 2
      // Tela 4 (Dados do Cartão) = Passo 3
      // Tela 5 (Resumo) = Passo 4
      return screenStep - 1;
    } else {
      // Se não tem conta, todas as telas aparecem
      // Tela 1 (Estabelecimento) = Passo 1
      // Tela 2 (Valor da Venda) = Passo 2
      // Tela 3 (Dados Bancários) = Passo 3
      // Tela 4 (Dados do Cartão) = Passo 4
      // Tela 5 (Resumo) = Passo 5
      return screenStep;
    }
  }

  /// Retorna o total de passos baseado se o usuário tem conta ou não
  static int getTotalSteps(bool hasAccount) {
    return hasAccount ? 4 : 5;
  }

  /// Constrói o indicador de progresso visual
  /// 
  /// [currentStep] é o passo atual (1, 2, 3, 4, 5)
  /// [totalSteps] é o total de passos (4 ou 5)
  static Widget buildProgressIndicator(int currentStep, int totalSteps) {
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

