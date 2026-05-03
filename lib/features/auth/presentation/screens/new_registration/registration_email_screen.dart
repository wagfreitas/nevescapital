import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:neves_capital/shared/helpers/email_helper.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/features/auth/data/services/local_registration_storage.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'package:neves_capital/features/auth/presentation/screens/unified_cpf_screen.dart';
import 'registration_personal_data_screen.dart';

/// Cadastro - Email
/// Coleta o email do usuario.
class RegistrationEmailScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;
  final String cpf;
  final String phone;
  final String? initialEmail;

  const RegistrationEmailScreen({
    super.key,
    this.authController,
    this.themeController,
    required this.cpf,
    required this.phone,
    this.initialEmail,
  });

  @override
  State<RegistrationEmailScreen> createState() =>
      _RegistrationEmailScreenState();
}

class _RegistrationEmailScreenState extends State<RegistrationEmailScreen> {
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }

    if (widget.initialEmail == null || widget.initialEmail!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _emailFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _saveBeforePop();
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

      // Salvar progresso localmente (merge com dados existentes)
      final existing = await LocalRegistrationStorage.getLocal();
      final savedProgress = (existing ?? RegistrationProgress(
        cpf: widget.cpf,
        currentStep: 'personal1',
        status: RegistrationStatus.inProgress,
        lastUpdated: DateTime.now(),
      )).copyWith(
        currentStep: 'personal1',
        lastUpdated: DateTime.now(),
        phone: widget.phone,
        email: email,
      );
      await LocalRegistrationStorage.saveLocal(savedProgress);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationPersonalDataScreen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: widget.cpf,
            phone: widget.phone,
            email: savedProgress.email ?? email,
            initialFullName: savedProgress.fullName,
            initialBirthDate: savedProgress.birthDate,
            initialMotherName: savedProgress.motherName,
          ),
        ),
      );
    } catch (e) {
      AppLogger.error('Erro ao continuar cadastro: $e');
      if (mounted) {
        setState(() =>
            _errorMessage = 'Erro ao continuar cadastro. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _saveBeforePop() {
    final email = _emailController.text.isNotEmpty
        ? EmailHelper.cleanEmail(_emailController.text)
        : null;
    LocalRegistrationStorage.getLocal().then((existing) {
      final keepStep = RegistrationProgress.furthestStep(
        existing?.currentStep ?? 'email', 'email',
      );
      final progress = (existing ?? RegistrationProgress(
        cpf: widget.cpf,
        currentStep: keepStep,
        status: RegistrationStatus.inProgress,
        lastUpdated: DateTime.now(),
      )).copyWith(
        currentStep: keepStep,
        lastUpdated: DateTime.now(),
        phone: widget.phone,
        email: email,
      );
      LocalRegistrationStorage.saveLocal(progress);
    });
  }

  Future<void> _handleBack() async {
    final existing = await LocalRegistrationStorage.getLocal();
    final email = _emailController.text.isNotEmpty
        ? EmailHelper.cleanEmail(_emailController.text)
        : null;
    final keepStep = RegistrationProgress.furthestStep(
      existing?.currentStep ?? 'email', 'email',
    );
    final progress = (existing ?? RegistrationProgress(
      cpf: widget.cpf,
      currentStep: keepStep,
      status: RegistrationStatus.inProgress,
      lastUpdated: DateTime.now(),
    )).copyWith(
      currentStep: keepStep,
      lastUpdated: DateTime.now(),
      phone: widget.phone,
      email: email,
    );
    await LocalRegistrationStorage.saveLocal(progress);

    if (!mounted) return;

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text(
          'Email',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        onBackPressed: _handleBack,
      ),
      body: SafeArea(
        top: false,
        child: KeyboardDismissWrapper(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: EdgeInsets.fromLTRB(
              24.0,
              MediaQuery.of(context).padding.top + kToolbarHeight + 40,
              24.0,
              MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle:
                          TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      hintText: 'seu@email.com.br',
                      hintStyle:
                          TextStyle(color: Colors.white.withValues(alpha: 0.3)),
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
                                valueColor: AlwaysStoppedAnimation<Color>(
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
