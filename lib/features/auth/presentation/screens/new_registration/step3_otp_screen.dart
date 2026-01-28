import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/shared/helpers/phone_helper.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/presentation/controllers/registration_lifecycle_observer.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/features/auth/presentation/helpers/registration_navigation_helper.dart';
import 'package:neves_capital/features/auth/data/services/auth_api_service.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'step4_email_screen.dart';

/// Tela 3 do Cadastro: Insira o código OTP (6 dígitos)
class Step3OtpScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;
  final String cpf;
  final String phone;

  const Step3OtpScreen({
    super.key,
    this.authController,
    this.themeController,
    required this.cpf,
    required this.phone,
  });

  @override
  State<Step3OtpScreen> createState() => _Step3OtpScreenState();
}

class _Step3OtpScreenState extends State<Step3OtpScreen> {
  static const int _otpLength = 6;
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  int _resendCountdown = 0;
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

    // Listener para habilitar/desabilitar botão
    _otpController.addListener(() {
      final hasFullCode = _otpController.text.trim().length == _otpLength;
      if (hasFullCode != _isOtpComplete) {
        setState(() {
          _isOtpComplete = hasFullCode;
        });
      }
    });

    // Abrir teclado automaticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _lifecycleObserver.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _otpFocusNode.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simular delay da API
    await Future.delayed(const Duration(seconds: 1));

    try {
      final otpCode = _otpController.text.trim();

      // MOCK: Simular verificação de OTP
      // Em produção, chamaria: FirestoreService.verifyRegistrationOtp(widget.cpf, widget.phone, otpCode)
      final success = _mockVerifyOtp(otpCode);

      if (!mounted) return;

      if (!success) {
        setState(() {
          _errorMessage = 'Código inválido. Tente novamente.';
        });
      } else {
        // OTP válido - continuar para próxima tela (email)
        AppLogger.info('OTP de cadastro verificado com sucesso!');

        // Criar progresso atual com dados preenchidos
        final currentProgress = RegistrationProgress(
          cpf: widget.cpf,
          currentStep: 'email',
          status: RegistrationStatus.inProgress,
          lastUpdated: DateTime.now(),
          phone: widget.phone,
        );

        // Salvar e buscar progresso completo (garante que dados de outras telas sejam preservados)
        final completeProgress = await RegistrationNavigationHelper.saveAndGetCompleteProgress(
          currentProgress: currentProgress,
        );

        if (!mounted) return;

        // Navegar para próxima tela (Email)
        // Usar dados do progresso completo para restaurar tudo que já foi preenchido
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Step4EmailScreen(
                authController: widget.authController,
                themeController: widget.themeController,
                cpf: widget.cpf,
                phone: widget.phone,
              initialEmail: completeProgress?.email,
              ),
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
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

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      AppLogger.info('🔄 Reenviando código OTP para cadastro');
      AppLogger.debug('📱 Telefone: ${widget.phone.substring(0, 2)}***');

      // Formatar telefone para E.164 (+55...)
      String formattedPhone = widget.phone;
      if (!formattedPhone.startsWith('+')) {
        // Garantir DDI 55 (Brasil)
        if (!formattedPhone.startsWith('55')) {
          formattedPhone = '55$formattedPhone';
        }
        formattedPhone = '+$formattedPhone';
      }

      // Tentar usar Firebase Phone Auth para reenvio
      try {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: formattedPhone,
          verificationCompleted: (PhoneAuthCredential credential) {
            AppLogger.debug('✅ Verificação automática no reenvio de cadastro');
          },
          verificationFailed: (FirebaseAuthException e) {
            AppLogger.error('❌ Erro ao reenviar OTP via Firebase: ${e.code} - ${e.message}');
            // Se Firebase falhar, tentar API alternativa
            _tryResendViaApi();
          },
          codeSent: (String verificationId, int? resendToken) {
            AppLogger.info('✅ Código reenviado com sucesso para cadastro via Firebase!');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _resendCountdown = 60; // 60 segundos de countdown
              });
              _startResendCountdown();
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            AppLogger.debug('⏰ Timeout de auto-retrieval no reenvio de cadastro');
          },
        );
      } catch (firebaseError) {
        // Se Firebase falhar, tentar API alternativa
        AppLogger.warning('Firebase Phone Auth falhou, tentando API alternativa: $firebaseError');
        _tryResendViaApi();
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao reenviar OTP', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao reenviar código: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  // Tentar reenviar via API alternativa
  Future<void> _tryResendViaApi() async {
    try {
      AppLogger.info('🔄 Tentando reenviar OTP via API alternativa');
      final result = await AuthApiService.sendOtp(widget.phone);
      
      if (mounted) {
        if (result['success'] == true) {
          AppLogger.info('✅ Código reenviado via API alternativa');
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
    } catch (apiError) {
      AppLogger.error('❌ Erro ao reenviar via API: $apiError');
      // Fallback: MOCK para desenvolvimento
      AppLogger.warning('⚠️ Usando MOCK para reenvio de OTP (modo desenvolvimento)');
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _resendCountdown = 60;
        });
        _startResendCountdown();
      }
    }
  }

  void _startResendCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
        _startResendCountdown();
      }
    });
  }

  // MOCK: Simula verificação de OTP
  bool _mockVerifyOtp(String otpCode) {
    // Para teste: aceita qualquer código de 6 dígitos
    // Em produção, isso virá da API
    return otpCode.length == _otpLength;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: KeyboardDismissWrapper(
          child: LayoutBuilder(
            // Evita overflow quando o teclado ocupa parte da tela.
            builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SingleChildScrollView(
              reverse: true,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset + 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        const Text(
                          'Digite o código',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Informe o código de verificação recebido no número ${PhoneHelper.formatPhone(widget.phone)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 40),
                        TextFormField(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: _otpLength,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
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
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        ),
      ),
    );
  }
}
