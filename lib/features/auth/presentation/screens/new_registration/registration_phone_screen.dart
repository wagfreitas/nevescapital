import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:neves_capital/shared/components/phone_input_field.dart';
import 'package:neves_capital/shared/helpers/phone_helper.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/presentation/controllers/registration_lifecycle_observer.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/features/auth/data/services/local_registration_storage.dart';
import 'package:neves_capital/features/auth/presentation/screens/unified_cpf_screen.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'registration_otp_screen.dart';

/// Cadastro - Telefone
/// Coleta o numero de celular do usuario para envio do OTP via WhatsApp.
class RegistrationPhoneScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;
  final String cpf;
  final String? initialPhone;

  const RegistrationPhoneScreen({
    super.key,
    this.authController,
    this.themeController,
    required this.cpf,
    this.initialPhone,
  });

  @override
  State<RegistrationPhoneScreen> createState() =>
      _RegistrationPhoneScreenState();
}

class _RegistrationPhoneScreenState extends State<RegistrationPhoneScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  late RegistrationLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();

    _lifecycleObserver = RegistrationLifecycleObserver(
      getCurrentProgress: _buildCurrentProgress,
      shouldSaveProgress: () => ModalRoute.of(context)?.isCurrent ?? false,
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    // Pre-preencher telefone se disponivel
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      final cleaned = PhoneHelper.cleanPhone(widget.initialPhone!);
      if (cleaned.isNotEmpty) {
        _phoneController.text = PhoneHelper.formatPhone(cleaned);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _phoneFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _lifecycleObserver.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _phoneFocusNode.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  RegistrationProgress _buildCurrentProgress() {
    final raw = _phoneController.text.trim();
    String? phone;
    if (raw.isNotEmpty) {
      try {
        phone = PhoneHelper.getPhoneNumbers(raw);
      } catch (_) {}
    }

    return RegistrationProgress(
      cpf: widget.cpf,
      currentStep: 'phone',
      status: RegistrationStatus.inProgress,
      lastUpdated: DateTime.now(),
      phone: phone,
    );
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = PhoneHelper.getPhoneNumbers(_phoneController.text);

      // TODO: Em producao, chamar API para enviar OTP
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // Salvar progresso localmente antes de navegar (merge com dados existentes)
      final existing = await LocalRegistrationStorage.getLocal();
      final progress = (existing ?? RegistrationProgress(
        cpf: widget.cpf,
        currentStep: 'otp',
        status: RegistrationStatus.inProgress,
        lastUpdated: DateTime.now(),
      )).copyWith(
        currentStep: 'otp',
        lastUpdated: DateTime.now(),
        phone: phone,
      );
      await LocalRegistrationStorage.saveLocal(progress);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationOtpScreen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: widget.cpf,
            phone: phone,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBack() async {
    // Carregar progresso existente e fazer merge para nao perder dados de outras telas
    final existing = await LocalRegistrationStorage.getLocal();
    final raw = _phoneController.text.trim();
    // Extrair apenas digitos (nunca falha, diferente de getPhoneNumbers)
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final phone = digits.isNotEmpty ? digits : null;

    // DEBUG: remover depois
    AppLogger.info('DEBUG phone _handleBack:');
    AppLogger.info('  raw: "$raw"');
    AppLogger.info('  digits: "$digits"');
    AppLogger.info('  phone: $phone');
    AppLogger.info('  existing: ${existing != null}');
    AppLogger.info('  existing.phone: ${existing?.phone}');
    final progress = (existing ?? RegistrationProgress(
      cpf: widget.cpf,
      currentStep: 'phone',
      status: RegistrationStatus.inProgress,
      lastUpdated: DateTime.now(),
    )).copyWith(
      currentStep: 'phone',
      lastUpdated: DateTime.now(),
      phone: phone,
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
            initialPhone: widget.initialPhone,
            initialCpf: widget.cpf,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text(
          'Insira seu Celular',
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
                  const Text(
                    'Enviaremos um código de verificação via WhatsApp',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PhoneInputField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    hintText: '(XX) XXXXX-XXXX',
                    autofocus: true,
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
    ),
    );
  }
}
