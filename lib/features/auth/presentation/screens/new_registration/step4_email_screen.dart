import 'package:flutter/material.dart';
import 'package:neves_capital/shared/helpers/email_helper.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/presentation/controllers/registration_lifecycle_observer.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'step5_personal_data_1_screen.dart';

/// Tela 4 do Cadastro: Insira seu email
class Step4EmailScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;
  final String cpf;
  final String phone;

  const Step4EmailScreen({
    super.key,
    this.authController,
    this.themeController,
    required this.cpf,
    required this.phone,
  });

  @override
  State<Step4EmailScreen> createState() => _Step4EmailScreenState();
}

class _Step4EmailScreenState extends State<Step4EmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  late RegistrationLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();

    _lifecycleObserver = RegistrationLifecycleObserver(
      getCurrentProgress: () => RegistrationProgress(
        cpf: widget.cpf,
        currentStep: 'email',
        status: RegistrationStatus.inProgress,
        lastUpdated: DateTime.now(),
        phone: widget.phone,
        email: _emailController.text.isNotEmpty
            ? EmailHelper.cleanEmail(_emailController.text)
            : null,
      ),
      shouldSaveProgress: () => ModalRoute.of(context)?.isCurrent ?? false,
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    // Abrir teclado automaticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emailFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _lifecycleObserver.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _emailFocusNode.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = EmailHelper.cleanEmail(_emailController.text);

      // NÃO cria usuário aqui - apenas continua o fluxo de cadastro
      // O usuário será criado em 'users' APENAS na tela final (step8)
      // Durante o cadastro, tudo fica em 'registration_progress' (local + Firestore)
      AppLogger.debug('Email validado - continuando fluxo de cadastro');
      AppLogger.sensitive('Email', email);

      if (!mounted) {
        AppLogger.warning(
            'Step4EmailScreen: Widget não está montado, abortando navegação');
        return;
      }

      AppLogger.debug(
          'Step4EmailScreen: Navegando para Step5PersonalData1Screen...');

      // Salvar progresso LOCALMENTE antes de navegar
      AppLogger.debug(
          'Salvando progresso antes de navegar para Dados Pessoais');
      await _lifecycleObserver.saveNow(localOnly: true);

      // Navegar para próxima tela (Informações Pessoais 1/2)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Step5PersonalData1Screen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: widget.cpf,
            phone: widget.phone,
            email: email,
          ),
        ),
      );

      AppLogger.debug('Step4EmailScreen: Navegação iniciada');
    } catch (e, stackTrace) {
      AppLogger.error('Step4EmailScreen: Erro ao continuar cadastro: $e');
      AppLogger.debug('Step4EmailScreen: StackTrace: $stackTrace');

      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao continuar cadastro. Tente novamente.';
        });
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Insira seu email',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Precisamos do seu email para completar o cadastro',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'seu@email.com',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF22C55E), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.email, color: Colors.white70),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Digite seu email';
                    }
                    if (!EmailHelper.isValidEmail(value)) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: const Color(0xFF122118),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF122118)),
                            ),
                          )
                        : const Text(
                            'Avançar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
