import 'package:flutter/material.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/registration_phone_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/registration_otp_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/registration_email_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/registration_personal_data_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/registration_address_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/registration_additional_info_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/step7_selfie_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/step8_document_screen.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

class RegistrationNavigator {
  static const List<String> _stepOrder = [
    'phone', 'otp', 'email', 'personal1', 'address', 'personal2',
    'selfie', 'document',
  ];

  /// Primeiro step que o swipe-back pode alcançar ao retomar um cadastro.
  /// `phone` e `otp` ficam de fora porque são autenticação, não entrada de dados.
  static const String _firstResumableStep = 'email';

  /// Navega para a tela correspondente ao passo atual do cadastro.
  ///
  /// Quando [replaceRoute] = true (retomada de cadastro abandonado), empilha
  /// TODA a sequência de telas (`phone → otp → ... → currentStep`) na pilha
  /// do Navigator. As telas intermediárias são empurradas com transição
  /// instantânea (sem animação) — só a tela final anima. Assim:
  ///   - O usuário só "vê" a tela alvo aparecendo (UX limpa).
  ///   - Mas o gesto de swipe-back (iOS) e o botão de voltar (Android)
  ///     navegam por toda a sequência, com cada tela já populada via
  ///     constructor (dados vindos do `LocalRegistrationStorage`).
  static void navigateToStep({
    required BuildContext context,
    required RegistrationProgress progress,
    AuthController? authController,
    ThemeController? themeController,
    bool replaceRoute = true,
  }) {
    AppLogger.debug('Navegando para step: ${progress.currentStep}');

    if (progress.currentStep == 'selfie' && progress.selfiePath != null) {
      navigateToStep(
        context: context,
        progress: progress.copyWith(currentStep: 'document'),
        authController: authController,
        themeController: themeController,
        replaceRoute: replaceRoute,
      );
      return;
    }

    final targetScreen = _buildScreen(
      step: progress.currentStep,
      progress: progress,
      authController: authController,
      themeController: themeController,
    );

    if (targetScreen == null) {
      AppLogger.error(
          'Não foi possível navegar: dados incompletos para o step ${progress.currentStep}');
      final fallback = RegistrationPhoneScreen(
        authController: authController,
        themeController: themeController,
        cpf: progress.cpf,
      );
      if (replaceRoute) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => fallback));
      } else {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => fallback));
      }
      return;
    }

    if (!replaceRoute) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => targetScreen));
      return;
    }

    // === Empilhar a sequência (a partir de _firstResumableStep) ===
    final navigator = Navigator.of(context);
    final targetIdx = _stepOrder.indexOf(progress.currentStep);
    final startIdx = _stepOrder.indexOf(_firstResumableStep);

    // Constrói as telas desde _firstResumableStep até a tela alvo (inclusive).
    // Se o usuário ainda está em phone/otp (antes do startIdx), empilha só
    // a tela alvo (não tem o que pré-popular).
    final List<Widget> screensInOrder = [];
    final from = targetIdx < startIdx ? targetIdx : startIdx;
    for (var i = from; i <= targetIdx; i++) {
      final isTarget = i == targetIdx;
      // Para garantir que a tela alvo seja exatamente a esperada (mesmo
      // se _buildScreen rejeitar por validação), reusamos o targetScreen.
      final screen = isTarget
          ? targetScreen
          : _buildScreen(
              step: _stepOrder[i],
              progress: progress,
              authController: authController,
              themeController: themeController,
            );
      if (screen != null) screensInOrder.add(screen);
    }

    if (screensInOrder.isEmpty) {
      // Fallback: empurra só a tela alvo
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => targetScreen),
      );
      return;
    }

    // 1) Substitui a rota atual pela PRIMEIRA tela da sequência (sem animação).
    navigator.pushReplacement(
      _InstantMaterialPageRoute(builder: (_) => screensInOrder.first),
    );

    // 2) Empurra as intermediárias (sem animação).
    for (var i = 1; i < screensInOrder.length - 1; i++) {
      final screen = screensInOrder[i];
      navigator.push(
        _InstantMaterialPageRoute(builder: (_) => screen),
      );
    }

    // 3) Empurra a tela alvo COM animação normal — única que o usuário "vê".
    if (screensInOrder.length > 1) {
      navigator.push(
        MaterialPageRoute(builder: (_) => screensInOrder.last),
      );
    }
  }

  static Widget? _buildScreen({
    required String step,
    required RegistrationProgress progress,
    AuthController? authController,
    ThemeController? themeController,
  }) {
    switch (step) {
      case 'phone':
        return RegistrationPhoneScreen(
          authController: authController,
          themeController: themeController,
          cpf: progress.cpf,
          initialPhone: progress.phone,
        );

      case 'otp':
        if (progress.phone == null) return null;
        return RegistrationOtpScreen(
          authController: authController,
          themeController: themeController,
          cpf: progress.cpf,
          phone: progress.phone!,
        );

      case 'email':
        if (progress.phone == null) return null;
        return RegistrationEmailScreen(
          authController: authController,
          themeController: themeController,
          cpf: progress.cpf,
          phone: progress.phone!,
          initialEmail: progress.email,
        );

      case 'personal1':
        if (progress.phone == null || progress.email == null) return null;
        return RegistrationPersonalDataScreen(
          authController: authController,
          themeController: themeController,
          cpf: progress.cpf,
          phone: progress.phone!,
          email: progress.email!,
          initialFullName: progress.fullName,
          initialBirthDate: progress.birthDate,
          initialMotherName: progress.motherName,
        );

      case 'address':
        if (progress.phone == null ||
            progress.email == null ||
            progress.fullName == null ||
            progress.birthDate == null ||
            progress.motherName == null) {
          return null;
        }
        return RegistrationAddressScreen(
          authController: authController,
          themeController: themeController,
          cpf: progress.cpf,
          phone: progress.phone!,
          email: progress.email!,
          fullName: progress.fullName!,
          birthDate: progress.birthDate!,
          motherName: progress.motherName!,
          initialCep: progress.cep,
          initialStreet: progress.street,
          initialNumber: progress.number,
          initialComplement: progress.complement,
          initialNeighborhood: progress.neighborhood,
          initialCity: progress.city,
          initialState: progress.state,
        );

      case 'personal2':
        if (progress.phone == null ||
            progress.email == null ||
            progress.fullName == null ||
            progress.birthDate == null ||
            progress.motherName == null ||
            progress.cep == null ||
            progress.street == null ||
            progress.number == null ||
            progress.neighborhood == null ||
            progress.city == null ||
            progress.state == null) {
          return null;
        }
        return RegistrationAdditionalInfoScreen(
          authController: authController,
          themeController: themeController,
          cpf: progress.cpf,
          phone: progress.phone!,
          email: progress.email!,
          fullName: progress.fullName!,
          birthDate: progress.birthDate!,
          motherName: progress.motherName!,
          cep: progress.cep!,
          street: progress.street!,
          number: progress.number!,
          complement: progress.complement ?? '',
          neighborhood: progress.neighborhood!,
          city: progress.city!,
          state: progress.state!,
          initialIsPep: progress.isPep,
          initialOccupation: progress.occupation,
          initialIncomeRange: progress.incomeRange,
        );

      case 'selfie':
        if (progress.phone == null ||
            progress.email == null ||
            progress.fullName == null ||
            progress.birthDate == null ||
            progress.motherName == null ||
            progress.cep == null ||
            progress.street == null ||
            progress.number == null ||
            progress.neighborhood == null ||
            progress.city == null ||
            progress.state == null ||
            progress.occupation == null ||
            progress.incomeRange == null) {
          return null;
        }
        return Step7SelfieScreen(
          authController: authController,
          themeController: themeController,
          cpf: progress.cpf,
          phone: progress.phone!,
          email: progress.email!,
          fullName: progress.fullName!,
          birthDate: progress.birthDate!,
          motherName: progress.motherName!,
          cep: progress.cep!,
          street: progress.street!,
          number: progress.number!,
          complement: progress.complement ?? '',
          neighborhood: progress.neighborhood!,
          city: progress.city!,
          state: progress.state!,
          isPep: progress.isPep ?? false,
          occupation: progress.occupation!,
          incomeRange: progress.incomeRange!,
        );

      case 'document':
        if (progress.phone == null ||
            progress.email == null ||
            progress.fullName == null ||
            progress.birthDate == null ||
            progress.motherName == null ||
            progress.cep == null ||
            progress.street == null ||
            progress.number == null ||
            progress.neighborhood == null ||
            progress.city == null ||
            progress.state == null ||
            progress.occupation == null ||
            progress.incomeRange == null ||
            progress.selfiePath == null) {
          return null;
        }
        return Step8DocumentScreen(
          authController: authController,
          themeController: themeController,
          cpf: progress.cpf,
          phone: progress.phone!,
          email: progress.email!,
          fullName: progress.fullName!,
          birthDate: progress.birthDate!,
          motherName: progress.motherName!,
          cep: progress.cep!,
          street: progress.street!,
          number: progress.number!,
          complement: progress.complement ?? '',
          neighborhood: progress.neighborhood!,
          city: progress.city!,
          state: progress.state!,
          isPep: progress.isPep ?? false,
          occupation: progress.occupation!,
          incomeRange: progress.incomeRange!,
          selfiePath: progress.selfiePath!,
          initialFrontDocumentPath: progress.documentFrontPath,
          initialBackDocumentPath: progress.documentBackPath,
          initialDocumentType: progress.documentType,
        );

      default:
        AppLogger.warning('Step desconhecido: $step');
        return RegistrationPhoneScreen(
          authController: authController,
          themeController: themeController,
          cpf: progress.cpf,
          initialPhone: progress.phone,
        );
    }
  }

  /// Mostra dialog perguntando se o usuário quer retomar o cadastro
  static Future<bool> showResumeDialog(
      BuildContext context, String currentStep) async {
    final stepNames = {
      'phone': 'telefone',
      'otp': 'verificação de código',
      'email': 'e-mail',
      'personal1': 'dados pessoais',
      'address': 'endereço',
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
        ) ??
        false;
  }
}

/// PageRoute que empurra sem animação (entrada instantânea), mas mantém
/// a animação reversa normal — preserva o swipe-back do iOS e o botão
/// voltar do Android com transição suave de saída.
class _InstantMaterialPageRoute<T> extends MaterialPageRoute<T> {
  _InstantMaterialPageRoute({required super.builder});

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);
}
