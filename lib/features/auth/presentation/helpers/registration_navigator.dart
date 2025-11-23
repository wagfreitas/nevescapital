import 'package:flutter/material.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/step2_phone_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/step3_otp_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/step4_email_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/step5_personal_data_1_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/step6_personal_data_2_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/step7_selfie_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/step8_document_screen.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

/// Helper para navegar para a tela correta baseado no progresso do cadastro
class RegistrationNavigator {
  /// Navega para a tela correspondente ao passo atual do cadastro
  static void navigateToStep({
    required BuildContext context,
    required RegistrationProgress progress,
    AuthController? authController,
    ThemeController? themeController,
  }) {
    AppLogger.debug('Navegando para step: ${progress.currentStep}');

    Widget? targetScreen;

    switch (progress.currentStep) {
      case 'phone':
        targetScreen = Step2PhoneScreen(
          authController: authController,
          themeController: themeController,
          cpf: progress.cpf,
        );
        break;

      case 'otp':
        if (progress.phone != null) {
          targetScreen = Step3OtpScreen(
            authController: authController,
            themeController: themeController,
            cpf: progress.cpf,
            phone: progress.phone!,
          );
        }
        break;

      case 'email':
        if (progress.phone != null) {
          targetScreen = Step4EmailScreen(
            authController: authController,
            themeController: themeController,
            cpf: progress.cpf,
            phone: progress.phone!,
          );
        }
        break;

      case 'personal1':
        if (progress.phone != null && progress.email != null) {
          targetScreen = Step5PersonalData1Screen(
            authController: authController,
            themeController: themeController,
            cpf: progress.cpf,
            phone: progress.phone!,
            email: progress.email!,
          );
        }
        break;

      case 'personal2':
        if (progress.phone != null && 
            progress.email != null && 
            progress.fullName != null &&
            progress.birthDate != null &&
            progress.motherName != null) {
          targetScreen = Step6PersonalData2Screen(
            authController: authController,
            themeController: themeController,
            cpf: progress.cpf,
            phone: progress.phone!,
            email: progress.email!,
            fullName: progress.fullName!,
            birthDate: progress.birthDate!,
            motherName: progress.motherName!,
          );
        }
        break;

      case 'selfie':
        if (progress.phone != null && 
            progress.email != null && 
            progress.fullName != null &&
            progress.birthDate != null &&
            progress.motherName != null &&
            progress.occupation != null &&
            progress.incomeRange != null) {
          targetScreen = Step7SelfieScreen(
            authController: authController,
            themeController: themeController,
            cpf: progress.cpf,
            phone: progress.phone!,
            email: progress.email!,
            fullName: progress.fullName!,
            birthDate: progress.birthDate!,
            motherName: progress.motherName!,
            isPep: progress.isPep ?? false,
            occupation: progress.occupation!,
            incomeRange: progress.incomeRange!,
          );
        }
        break;

      case 'document':
        if (progress.phone != null && 
            progress.email != null && 
            progress.fullName != null &&
            progress.birthDate != null &&
            progress.motherName != null &&
            progress.occupation != null &&
            progress.incomeRange != null &&
            progress.selfiePath != null) {
          targetScreen = Step8DocumentScreen(
            authController: authController,
            themeController: themeController,
            cpf: progress.cpf,
            phone: progress.phone!,
            email: progress.email!,
            fullName: progress.fullName!,
            birthDate: progress.birthDate!,
            motherName: progress.motherName!,
            isPep: progress.isPep ?? false,
            occupation: progress.occupation!,
            incomeRange: progress.incomeRange!,
            selfiePath: progress.selfiePath!,
          );
        }
        break;

      default:
        AppLogger.warning('Step desconhecido: ${progress.currentStep}');
        // Fallback para tela de telefone
        targetScreen = Step2PhoneScreen(
          authController: authController,
          themeController: themeController,
          cpf: progress.cpf,
        );
    }

    if (targetScreen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen!),
      );
    } else {
      AppLogger.error('Não foi possível navegar: dados incompletos para o step ${progress.currentStep}');
      // Fallback para início do cadastro
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Step2PhoneScreen(
            authController: authController,
            themeController: themeController,
            cpf: progress.cpf,
          ),
        ),
      );
    }
  }

  /// Mostra dialog perguntando se o usuário quer retomar o cadastro
  static Future<bool> showResumeDialog(BuildContext context, String currentStep) async {
    final stepNames = {
      'phone': 'telefone',
      'otp': 'verificação de código',
      'email': 'e-mail',
      'personal1': 'dados pessoais',
      'personal2': 'informações adicionais',
      'selfie': 'selfie',
      'document': 'documentos',
    };

    final stepName = stepNames[currentStep] ?? 'cadastro';

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2F25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF28CC28), size: 28),
            SizedBox(width: 12),
            Text(
              'Cadastro Iniciado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Identificamos que você começou seu cadastro anteriormente e parou na etapa de $stepName.\n\nDeseja continuar de onde parou?',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Recomeçar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF28CC28),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    ) ?? false;
  }
}
