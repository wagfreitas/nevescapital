import 'package:flutter/material.dart';
import 'package:neves_capital/shared/components/cpf_input_field.dart';
import 'package:neves_capital/shared/helpers/cpf_helper.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/presentation/screens/login_otp/login_step3_otp_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/step2_phone_screen.dart';
import 'package:neves_capital/features/auth/data/services/registration_service.dart';
import 'package:neves_capital/features/auth/data/services/local_registration_storage.dart';
import 'package:neves_capital/features/auth/presentation/helpers/registration_navigator.dart';

/// Tela Unificada: Insira seu CPF
/// Verifica se o CPF existe e direciona automaticamente para:
/// - Fluxo de LOGIN (com OTP) se CPF já cadastrado
/// - Fluxo de CADASTRO se CPF não cadastrado
class UnifiedCpfScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;

  const UnifiedCpfScreen({
    super.key,
    this.authController,
    this.themeController,
  });

  @override
  State<UnifiedCpfScreen> createState() => _UnifiedCpfScreenState();
}

class _UnifiedCpfScreenState extends State<UnifiedCpfScreen> {
  final TextEditingController _cpfController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cpf = CpfHelper.getCpfNumbers(_cpfController.text);

      // Verificar se CPF já está cadastrado no Firestore
      AppLogger.info('🔍 Verificando existência do CPF no Firebase...');
      AppLogger.debug('CPF (primeiros 3 dígitos): ${cpf.substring(0, 3)}***');

      final result = await FirestoreService.checkCpf(cpf);

      if (!mounted) return;

      // Verificar se a resposta tem sucesso
      final success = result['success'] as bool? ?? false;
      final message = result['message'] as String? ?? '';

      AppLogger.info(
          '📊 Resultado da verificação: success=$success, message=$message');

      if (!success) {
        // Se não teve sucesso na verificação, mostrar mensagem de erro
        setState(() {
          _errorMessage =
              message.isNotEmpty ? message : 'Erro ao verificar CPF';
        });
        return;
      }

      final exists = result['exists'] as bool? ?? false;
      AppLogger.info(
          '✅ CPF ${exists ? "ENCONTRADO" : "NÃO ENCONTRADO"} no Firebase');

      if (exists) {
        // ============================================
        // FLUXO DE LOGIN - CPF já cadastrado
        // ============================================
        AppLogger.debug('CPF cadastrado - iniciando fluxo de LOGIN');

        // Buscar dados do usuário (incluindo telefone)
        final userData = await FirestoreService.getUserByCpf(cpf);

        if (!mounted) return;

        if (userData == null) {
          setState(() {
            _errorMessage = 'Erro ao buscar dados do usuário. Tente novamente.';
          });
          return;
        }

        final phone = userData['phone'] as String?;

        if (phone == null || phone.isEmpty) {
          setState(() {
            _errorMessage =
                'Telefone não cadastrado. Entre em contato com o suporte.';
          });
          return;
        }

        AppLogger.sensitive('Telefone encontrado para login', phone);

        // MOCK: Simular envio de OTP
        // TODO: Em produção, chamar backend para enviar OTP real
        AppLogger.debug('MOCK: OTP enviado para telefone cadastrado');

        // Navegar para tela de OTP (login)
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginStep3OtpScreen(
                authController: widget.authController,
                themeController: widget.themeController,
              ),
              settings: RouteSettings(
                arguments: {
                  'cpf': cpf,
                  'phone': phone,
                },
              ),
            ),
          );
        }
      } else {
        // ============================================
        // FLUXO DE CADASTRO - CPF NÃO cadastrado
        // ============================================
        AppLogger.debug('CPF não cadastrado - verificando cadastro parcial');

        // Verificar se há cadastro abandonado anteriormente
        final registrationProgress = await RegistrationService.getProgress(cpf);

        if (registrationProgress != null &&
            !registrationProgress.isComplete &&
            !registrationProgress.isStale) {
          // Cadastro anteriormente abandonado
          AppLogger.info(
              'Cadastro abandonado encontrado - step: ${registrationProgress.currentStep}');

          if (!mounted) return;

          // Perguntar se quer retomar
          final shouldResume = await RegistrationNavigator.showResumeDialog(
            context,
            registrationProgress.currentStep,
          );

          if (!mounted) return;

          if (shouldResume) {
            // Retomar cadastro de onde parou
            RegistrationNavigator.navigateToStep(
              context: context,
              progress: registrationProgress,
              authController: widget.authController,
              themeController: widget.themeController,
            );
            return;
          } else {
            // Recomeçar do zero - marcar como abandonado e deletar
            await RegistrationService.deleteProgress(cpf);
          }
        }

        // Iniciar novo cadastro
        AppLogger.debug('Iniciando novo cadastro');

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Step2PhoneScreen(
                authController: widget.authController,
                themeController: widget.themeController,
                cpf: cpf,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Erro ao verificar CPF. Verifique sua conexão e tente novamente.';
        });
        AppLogger.error('Erro ao verificar CPF: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildLogo(),
                const SizedBox(height: 40.0),
                _buildTitle(),
                const SizedBox(height: 8.0),
                _buildSubtitle(),
                const SizedBox(height: 40.0),
                if (_errorMessage != null) ...[
                  _buildErrorMessage(),
                  const SizedBox(height: 16.0),
                ],
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/icons/logo_ios_filled.png',
      width: 80,
      height: 80,
      fit: BoxFit.contain,
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Vamos começar',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'Insira seu CPF para continuar',
      style: TextStyle(
        fontSize: 16,
        color: Colors.white70,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CpfInputField(
            controller: _cpfController,
            labelText: 'CPF',
            hintText: '000.000.000-00',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, digite seu CPF';
              }
              if (!CpfHelper.isValidCpf(value)) {
                return 'CPF inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 32.0),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF28CC28),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Continuar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoText(),
        ],
      ),
    );
  }

  Widget _buildInfoText() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF28CC28).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF28CC28).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: const Color(0xFF28CC28).withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Se já tiver cadastro, você será direcionado para login. Caso contrário, faremos seu cadastro.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
