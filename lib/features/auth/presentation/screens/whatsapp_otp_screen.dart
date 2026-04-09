import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:neves_capital/shared/helpers/phone_helper.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/data/services/auth_api_service.dart';
import 'package:neves_capital/features/auth/presentation/screens/unified_cpf_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:neves_capital/features/home/presentation/screens/main_tab_screen.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';

/// Tela de verificação OTP via WhatsApp (4 dígitos)
class WhatsAppOtpScreen extends StatefulWidget {
  final String phone; // Telefone limpo (apenas dígitos, com código do país)
  final String formattedPhone; // Telefone formatado E.164 (+55...)
  final AuthController? authController;
  final ThemeController? themeController;

  const WhatsAppOtpScreen({
    super.key,
    required this.phone,
    required this.formattedPhone,
    this.authController,
    this.themeController,
  });

  @override
  State<WhatsAppOtpScreen> createState() => _WhatsAppOtpScreenState();
}

class _WhatsAppOtpScreenState extends State<WhatsAppOtpScreen> {
  int _otpLength = 4;

  List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;
  int _resendCountdown = 30;
  int _smsCountdown = 30;
  int _failedAttempts = 0;
  static const int _maxFailedAttempts = 3;

  /// Modo SMS: usa Firebase Phone Auth (6 dígitos) em vez do backend WhatsApp (4 dígitos)
  bool _isSmsMode = false;
  String? _smsVerificationId;

  bool get _isOtpComplete =>
      _controllers.every((c) => c.text.length == 1);

  String get _otpCode => _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _startCountdowns();

    // Auto-focus no primeiro campo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes[0].canRequestFocus) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdowns() {
    _startResendCountdown();
    _startSmsCountdown();
  }

  void _startResendCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() => _resendCountdown--);
        _startResendCountdown();
      }
    });
  }

  void _startSmsCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _smsCountdown > 0) {
        setState(() => _smsCountdown--);
        _startSmsCountdown();
      }
    });
  }

  void _onDigitChanged(int index, String value) {
    // Detectar PASTE: se o valor colado tem múltiplos dígitos
    if (value.length > 1) {
      _pasteCode(value);
      return;
    }

    // Backspace detectado via onChanged (campo ficou vazio)
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      setState(() => _errorMessage = null);
      return;
    }

    if (value.length == 1 && index < _otpLength - 1) {
      // Avançar para o próximo campo
      _focusNodes[index + 1].requestFocus();
    }

    setState(() {
      _errorMessage = null;
    });
  }

  /// Cola o código completo nos campos (suporte a paste do WhatsApp)
  void _pasteCode(String code) {
    final digits = code.replaceAll(RegExp(r'\D'), '');
    for (int i = 0; i < _otpLength; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    // Focar no último campo preenchido ou no último
    final focusIndex = (digits.length >= _otpLength) ? _otpLength - 1 : digits.length;
    if (focusIndex < _otpLength) {
      _focusNodes[focusIndex].requestFocus();
    }
    setState(() {
      _errorMessage = null;
    });
  }

  /// Limpa todos os campos e foca no primeiro
  void _clearAllFields() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {
      _errorMessage = null;
    });
  }

  Future<void> _handleVerify() async {
    if (!_isOtpComplete) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = _otpCode;

      // Modo SMS: verificar via Firebase Phone Auth
      if (_isSmsMode && _smsVerificationId != null) {
        await _verifySmsCode(code);
        return;
      }

      // Modo WhatsApp: verificar via backend
      AppLogger.info('🔐 Verificando OTP WhatsApp: $code');

      final result =
          await AuthApiService.verifyOtpLogin(widget.phone, code);

      if (!mounted) return;

      final success = result['success'] as bool? ?? false;
      final status = result['status'] as String?;

      if (!success) {
        _failedAttempts++;
        if (_failedAttempts >= _maxFailedAttempts) {
          _redirectToOnboarding();
          return;
        }
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'] as String? ??
              'Código inválido. Tentativas restantes: ${_maxFailedAttempts - _failedAttempts}';
        });
        return;
      }

      // Resetar tentativas
      _failedAttempts = 0;

      if (status == 'LOGGED_IN') {
        final customToken = result['customToken'] as String?;
        final userId = result['userId'] as String?;

        if (customToken != null) {
          // Fazer login com Custom Token
          AppLogger.info('🔑 Fazendo login com Custom Token...');
          await FirebaseAuth.instance.signInWithCustomToken(customToken);
        }

        if (userId != null && widget.authController != null) {
          // Buscar CPF do usuário para login
          final userData = await FirestoreService.getUserByDocumentId(userId);
          final cpf = userData?['cpf'] as String?;

          if (cpf != null) {
            final loginSuccess =
                await widget.authController!.loginWithOtpDirect(
              cpf: cpf,
              userId: userId,
            );

            if (!loginSuccess) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage =
                      widget.authController?.errorMessage ?? 'Erro ao fazer login';
                });
              }
              return;
            }
          }
        }

        // Navegar para Dashboard
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MainTabScreen(
                authController: widget.authController ?? AuthController(),
                themeController: widget.themeController ?? ThemeController(),
              ),
            ),
            (route) => false,
          );
        }
      } else if (status == 'REGISTER') {
        // Navegar para cadastro
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => UnifiedCpfScreen(
                authController: widget.authController,
                themeController: widget.themeController,
                initialPhone: widget.phone,
              ),
            ),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Status desconhecido: $status';
        });
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao verificar OTP: $e');
      if (mounted) {
        _failedAttempts++;
        if (_failedAttempts >= _maxFailedAttempts) {
          _redirectToOnboarding();
          return;
        }
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Erro ao verificar código. Tentativas restantes: ${_maxFailedAttempts - _failedAttempts}';
        });
      }
    }
  }

  Future<void> _handleResend() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthApiService.sendOtpWhatsApp(widget.phone);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _resendCountdown = 30;
        });
        _startResendCountdown();

        if (result['success'] == true) {
          // Limpar campos
          for (final c in _controllers) {
            c.clear();
          }
          _focusNodes[0].requestFocus();
        } else {
          _errorMessage = result['message'] as String? ?? 'Erro ao reenviar código';
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao reenviar código';
        });
      }
    }
  }

  Future<void> _handleSmsFallback() async {
    if (_smsCountdown > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      AppLogger.info('📱 Fallback SMS: Enviando OTP via Firebase Phone Auth');

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) {
          AppLogger.debug('✅ Verificação automática no fallback SMS');
        },
        verificationFailed: (FirebaseAuthException e) {
          AppLogger.error('❌ Erro no fallback SMS: ${e.code}');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = e.code == 'too-many-requests'
                  ? 'Muitas tentativas. Aguarde alguns minutos.'
                  : 'Erro ao enviar SMS: ${e.message ?? e.code}';
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          AppLogger.info('✅ SMS enviado com sucesso!');
          if (!mounted) return;

          // Mudar para modo SMS na mesma tela (6 dígitos)
          _switchToSmsMode(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          AppLogger.debug('⏰ Timeout de auto-retrieval no fallback SMS');
        },
      );
    } catch (e) {
      AppLogger.error('❌ Erro no fallback SMS: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao enviar SMS. Tente novamente.';
        });
      }
    }
  }

  /// Muda a tela para modo SMS: 6 campos em vez de 4
  void _switchToSmsMode(String verificationId) {
    // Limpar controllers antigos
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }

    setState(() {
      _isSmsMode = true;
      _smsVerificationId = verificationId;
      _otpLength = 6;
      _isLoading = false;
      _errorMessage = null;
      _controllers = List.generate(6, (_) => TextEditingController());
      _focusNodes = List.generate(6, (_) => FocusNode());
    });

    // Focar no primeiro campo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes[0].canRequestFocus) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  /// Verifica o código SMS via Firebase Phone Auth
  Future<void> _verifySmsCode(String code) async {
    try {
      AppLogger.info('🔐 Verificando código SMS via Firebase...');

      final credential = PhoneAuthProvider.credential(
        verificationId: _smsVerificationId!,
        smsCode: code,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (!mounted) return;

      if (user != null) {
        AppLogger.info('✅ SMS verificado com sucesso! UID: ${user.uid}');

        // Buscar dados do usuário no Firestore
        final userId = user.uid;
        final userData = await FirestoreService.getUserByDocumentId(userId);
        final cpf = userData?['cpf'] as String?;

        if (cpf != null && widget.authController != null) {
          final loginSuccess = await widget.authController!.loginWithOtpDirect(
            cpf: cpf,
            userId: userId,
          );

          if (!loginSuccess && mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = widget.authController?.errorMessage ?? 'Erro ao fazer login';
            });
            return;
          }
        }

        // Navegar para Dashboard
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MainTabScreen(
                authController: widget.authController ?? AuthController(),
                themeController: widget.themeController ?? ThemeController(),
              ),
            ),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Erro ao verificar SMS: ${e.code}');
      if (!mounted) return;

      _failedAttempts++;
      if (_failedAttempts >= _maxFailedAttempts) {
        _redirectToOnboarding();
        return;
      }

      String errorMsg;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMsg = 'Código inválido. Tentativas restantes: ${_maxFailedAttempts - _failedAttempts}';
          break;
        case 'session-expired':
          errorMsg = 'Sessão expirada. Solicite um novo código.';
          break;
        default:
          errorMsg = 'Erro ao verificar código: ${e.message ?? e.code}';
      }

      setState(() {
        _isLoading = false;
        _errorMessage = errorMsg;
      });
    } catch (e) {
      AppLogger.error('❌ Erro inesperado ao verificar SMS: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao verificar código. Tente novamente.';
        });
      }
    }
  }

  void _redirectToOnboarding() {
    if (!mounted) return;
    AppLogger.info('Redirecionando para Onboarding após falhas no OTP');
    widget.authController?.logout();
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => OnboardingScreen(
          authController: widget.authController ?? AuthController(),
          themeController: widget.themeController,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final formattedDisplay = PhoneHelper.formatPhone(widget.phone);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(top: topPadding + 8, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Botão voltar
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: LiquidBackButton(
                    onPressed: () {
                      if (mounted) Navigator.of(context).maybePop();
                    },
                  ),
                ),
              ),

              // Título
              const Text(
                'Digite o Código',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtítulo
              Text(
                _isSmsMode
                    ? 'Informe o código de verificação que enviamos por SMS para +55 $formattedDisplay'
                    : 'Informe o código de verificação que enviamos para o WhatsApp do número +55 $formattedDisplay',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // 4 caixas de OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_otpLength, (index) {
                  return Container(
                    width: _isSmsMode ? 48 : 64,
                    height: _isSmsMode ? 48 : 64,
                    margin: EdgeInsets.symmetric(horizontal: _isSmsMode ? 4 : 8),
                    child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: index == 0 ? _otpLength : 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onDigitChanged(index, value),
                        style: TextStyle(
                          fontSize: _isSmsMode ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
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
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Mensagem de erro
              if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
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
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botão Verificar Código
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      (_isLoading || !_isOtpComplete) ? null : _handleVerify,
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
              const SizedBox(height: 24),

              // Reenviar Código
              Center(
                child: _resendCountdown > 0
                    ? Text(
                        'Reenviar Código ${_resendCountdown}s',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      )
                    : TextButton(
                        onPressed: _isLoading ? null : _handleResend,
                        child: const Text(
                          'Reenviar Código',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),

              // Fallback SMS
              Center(
                child: _smsCountdown > 0
                    ? Text(
                        'Prefere receber por SMS? Clique Aqui ${_smsCountdown}s',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      )
                    : TextButton(
                        onPressed: _isLoading ? null : _handleSmsFallback,
                        child: const Text(
                          'Prefere receber por SMS? Clique Aqui',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
