import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:neves_capital/shared/helpers/phone_helper.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/features/auth/presentation/controllers/registration_lifecycle_observer.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/features/auth/data/services/local_registration_storage.dart';
import 'package:neves_capital/features/auth/data/services/auth_api_service.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'registration_email_screen.dart';

/// Cadastro - Codigo OTP
/// Verifica o codigo de 6 digitos enviado via WhatsApp.
class RegistrationOtpScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;
  final String cpf;
  final String phone;

  const RegistrationOtpScreen({
    super.key,
    this.authController,
    this.themeController,
    required this.cpf,
    required this.phone,
  });

  @override
  State<RegistrationOtpScreen> createState() => _RegistrationOtpScreenState();
}

class _RegistrationOtpScreenState extends State<RegistrationOtpScreen> {
  static const int _otpLength = 6;
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  int _resendCountdown = 30;
  bool _isOtpComplete = false;
  late RegistrationLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();

    _lifecycleObserver = RegistrationLifecycleObserver(
      getCurrentProgress: () => RegistrationProgress(
        cpf: widget.cpf,
        currentStep: 'otp',
        status: RegistrationStatus.inProgress,
        lastUpdated: DateTime.now(),
        phone: widget.phone,
      ),
      shouldSaveProgress: () => ModalRoute.of(context)?.isCurrent ?? false,
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    _otpController.addListener(() {
      final hasFullCode = _otpController.text.trim().length == _otpLength;
      if (hasFullCode != _isOtpComplete) {
        setState(() => _isOtpComplete = hasFullCode);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocusNode.requestFocus();
    });

    _startResendCountdown();
  }

  @override
  void dispose() {
    _lifecycleObserver.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _otpFocusNode.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // =========================================================
  // HANDLERS
  // =========================================================

  void _handleOtpChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits != value) {
      final trimmed = digits.length > _otpLength
          ? digits.substring(0, _otpLength)
          : digits;
      _otpController.value = TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
    }
    setState(() => _errorMessage = null);
  }

  Future<void> _handleVerifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final otpCode = _otpController.text.trim();

      // TODO: Em producao, chamar API de verificacao
      await Future.delayed(const Duration(seconds: 1));
      final success = otpCode.length == _otpLength;

      if (!mounted) return;

      if (!success) {
        setState(() => _errorMessage = 'Código inválido. Tente novamente.');
        return;
      }

      // OTP valido - salvar progresso localmente e avancar
      final existing = await LocalRegistrationStorage.getLocal();
      final savedProgress = (existing ?? RegistrationProgress(
        cpf: widget.cpf,
        currentStep: 'email',
        status: RegistrationStatus.inProgress,
        lastUpdated: DateTime.now(),
      )).copyWith(
        currentStep: 'email',
        lastUpdated: DateTime.now(),
        phone: widget.phone,
      );
      await LocalRegistrationStorage.saveLocal(savedProgress);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationEmailScreen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: widget.cpf,
            phone: widget.phone,
            initialEmail: savedProgress.email,
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBack() async {
    // Carregar progresso existente e fazer merge para nao perder dados de outras telas
    final existing = await LocalRegistrationStorage.getLocal();
    final progress = (existing ?? RegistrationProgress(
      cpf: widget.cpf,
      currentStep: 'otp',
      status: RegistrationStatus.inProgress,
      lastUpdated: DateTime.now(),
    )).copyWith(
      currentStep: 'otp',
      lastUpdated: DateTime.now(),
      phone: widget.phone,
    );
    await LocalRegistrationStorage.saveLocal(progress);

    if (!mounted) return;

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // =========================================================
  // REENVIO DE OTP
  // =========================================================

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String formattedPhone = widget.phone;
      if (!formattedPhone.startsWith('+')) {
        if (!formattedPhone.startsWith('55')) {
          formattedPhone = '55$formattedPhone';
        }
        formattedPhone = '+$formattedPhone';
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (_) {},
        verificationFailed: (FirebaseAuthException e) {
          AppLogger.error('Erro ao reenviar OTP via Firebase: ${e.code}');
          _tryResendViaApi();
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _resendCountdown = 60;
            });
            _startResendCountdown();
          }
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      AppLogger.warning('Firebase Phone Auth falhou, tentando API: $e');
      _tryResendViaApi();
    }
  }

  Future<void> _tryResendViaApi() async {
    try {
      final result = await AuthApiService.sendOtp(widget.phone);

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _isLoading = false;
            _resendCountdown = 60;
          });
          _startResendCountdown();
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = result['message'] ?? 'Erro ao reenviar código';
          });
        }
      }
    } catch (e) {
      AppLogger.error('Erro ao reenviar via API: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao reenviar código. Tente novamente.';
        });
      }
    }
  }

  void _startResendCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() => _resendCountdown--);
        _startResendCountdown();
      }
    });
  }

  // =========================================================
  // BUILD
  // =========================================================

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
          'Digite o código',
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
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Informe o código de verificação recebido no número +55 ${PhoneHelper.formatPhone(widget.phone)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _otpController,
                      focusNode: _otpFocusNode,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      onChanged: _handleOtpChanged,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(_otpLength),
                      ],
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 12,
                      ),
                      decoration: InputDecoration(
                        hintText: '000000',
                        hintStyle: TextStyle(
                          fontSize: 32,
                          color: Colors.white.withValues(alpha: 0.3),
                          letterSpacing: 12,
                        ),
                        counterText: '',
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
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite o código';
                        }
                        if (value.trim().length != _otpLength) {
                          return 'Código deve ter $_otpLength dígitos';
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
                        onPressed: (_isLoading || !_isOtpComplete)
                            ? null
                            : _handleVerifyOtp,
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
                                'Verificar Código',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_resendCountdown > 0)
                      Center(
                        child: Text(
                          'Reenviar código em ${_resendCountdown}s',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      Center(
                        child: TextButton(
                          onPressed: _isLoading ? null : _handleResendOtp,
                          child: const Text(
                            'Reenviar código',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 14,
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
    ),
    );
  }
}
