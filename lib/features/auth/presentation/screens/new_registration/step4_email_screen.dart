import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:neves_capital/shared/helpers/email_helper.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/presentation/controllers/registration_lifecycle_observer.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'package:neves_capital/features/auth/presentation/screens/unified_cpf_screen.dart';
import 'package:neves_capital/features/auth/presentation/helpers/registration_navigation_helper.dart';
import 'step5_personal_data_1_screen.dart';

/// Tela 4 do Cadastro: Insira seu email
class Step4EmailScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;
  final String cpf;
  final String phone;
  final String? initialEmail;

  const Step4EmailScreen({
    super.key,
    this.authController,
    this.themeController,
    required this.cpf,
    required this.phone,
    this.initialEmail,
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

    // Restaurar email se fornecido
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }

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

    // Abrir teclado automaticamente apenas se não houver email pré-preenchido
    if (widget.initialEmail == null || widget.initialEmail!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _emailFocusNode.requestFocus();
      });
    }
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

      // Criar progresso atual com dados preenchidos
      final currentProgress = RegistrationProgress(
        cpf: widget.cpf,
        currentStep: 'personal1',
        status: RegistrationStatus.inProgress,
        lastUpdated: DateTime.now(),
        phone: widget.phone,
        email: email,
      );

      // Salvar e buscar progresso completo (garante que dados de outras telas sejam preservados)
      final completeProgress = await RegistrationNavigationHelper.saveAndGetCompleteProgress(
        currentProgress: currentProgress,
      );

      if (!mounted) return;

      // Navegar para próxima tela (Informações Pessoais 1/2)
      // Usar dados do progresso completo para restaurar tudo que já foi preenchido
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Step5PersonalData1Screen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: widget.cpf,
            phone: widget.phone,
            email: completeProgress?.email ?? email,
            initialFullName: completeProgress?.fullName,
            initialBirthDate: completeProgress?.birthDate,
            initialMotherName: completeProgress?.motherName,
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
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        onBackPressed: () {
          // Tentar fazer pop primeiro (se houver tela anterior na pilha)
          // Se não houver, navegar explicitamente para a tela de CPF
          // Isso garante que funciona tanto no fluxo normal quanto no "Recomeçar"
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            // Não há tela anterior na pilha (vem do fluxo de "Recomeçar")
            // Navegar explicitamente para a tela de CPF com o CPF restaurado
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UnifiedCpfScreen(
                  authController: widget.authController,
                  themeController: widget.themeController,
                  initialPhone: widget.phone,
                  initialCpf: widget.cpf,
                ),
              ),
            );
          }
        },
      ),
      body: SafeArea(
        child: KeyboardDismissWrapper(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        const Center(
                          child: Text(
                            'Insira seu email',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          autofocus: true,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7)),
                            hintText: 'seu@email.com.br',
                            hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3)),
                            filled: true,
                            fillColor: AppTheme.inputEditableBackgroundColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppTheme.primaryColor, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 2),
                            ),
                            prefixIcon:
                                const Icon(Icons.email, color: Colors.white70),
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
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: AppTheme.backgroundColor,
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
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              AppTheme.backgroundColor),
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
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
