import 'package:flutter/material.dart';
import 'package:neves_capital/shared/components/cpf_input_field.dart';
import 'package:neves_capital/shared/helpers/cpf_helper.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/step2_phone_screen.dart';
import 'package:neves_capital/features/auth/data/services/registration_service.dart';
import 'package:neves_capital/features/auth/presentation/helpers/registration_navigator.dart';
import 'package:neves_capital/features/auth/data/services/auth_api_service.dart';

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
  void initState() {
    super.initState();
    // Limpar mensagem de erro quando o usuário começar a digitar
    _cpfController.addListener(() {
      if (_errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    // Validar o formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validação adicional do CPF antes de prosseguir
    final cpf = CpfHelper.getCpfNumbers(_cpfController.text);

    if (!CpfHelper.isValidCpf(cpf)) {
      setState(() {
        _errorMessage = 'CPF inválido. Por favor, verifique o número digitado.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verificar se CPF existe no banco
      AppLogger.info('🚀 Verificando CPF: ${cpf.substring(0, 3)}***');

      final result = await AuthApiService.checkCpf(cpf);

      if (!mounted) return;

      final success = result['success'] as bool? ?? false;
      final exists = result['exists'] as bool? ?? false;

      if (success && exists) {
        // ============================================
        // CPF EXISTE: Fluxo de Login (Phone Auth)
        // ============================================
        AppLogger.info(
            '✅ CPF encontrado - Redirecionando para login via telefone');

        // TODO: Implementar navegação para tela de Phone Login
        // Por enquanto, mostrar mensagem
        if (mounted) {
          setState(() {
            _errorMessage =
                'Login via telefone ainda não implementado. Em breve!';
          });
        }
      } else if (success && !exists) {
        // ============================================
        // CPF NÃO EXISTE: Fluxo de Cadastro
        // ============================================
        AppLogger.info('👤 CPF não encontrado - Redirecionando para cadastro');

        // Verificar se há cadastro abandonado
        final registrationProgress = await RegistrationService.getProgress(cpf);

        if (registrationProgress != null &&
            !registrationProgress.isComplete &&
            !registrationProgress.isStale) {
          if (!mounted) return;

          final shouldResume = await RegistrationNavigator.showResumeDialog(
            context,
            registrationProgress.currentStep,
          );

          if (!mounted) return;

          if (shouldResume) {
            RegistrationNavigator.navigateToStep(
              context: context,
              progress: registrationProgress,
              authController: widget.authController,
              themeController: widget.themeController,
            );
            return;
          } else {
            await RegistrationService.deleteProgress(cpf);
          }
        }

        // Novo cadastro
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
      } else {
        // Erro ao verificar CPF
        setState(() {
          _errorMessage = 'Erro ao verificar CPF. Tente novamente.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro de conexão. Verifique sua internet.';
        });
        AppLogger.error('Erro no _handleNext: $e');
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
        color: Colors.red.withValues(alpha: 0.1),
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

              final cpfNumbers = CpfHelper.getCpfNumbers(value);

              if (cpfNumbers.length != 11) {
                return 'CPF deve ter 11 dígitos';
              }

              if (!CpfHelper.isValidCpf(value)) {
                return 'CPF inválido. Verifique os dígitos.';
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
        ],
      ),
    );
  }
}
