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

  // Campo único que recebe o OTP. A UI mostra 4/6 caixas, mas por baixo é um
  // único TextField — isso é o que o iOS 26 precisa para oferecer o autofill
  // do código do WhatsApp na barra do teclado.
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocus = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  int _resendCountdown = 30;
  int _smsCountdown = 30;
  int _failedAttempts = 0;
  static const int _maxFailedAttempts = 3;

  /// Modo SMS: usa Firebase Phone Auth (6 dígitos) em vez do backend WhatsApp (4 dígitos)
  bool _isSmsMode = false;
  String? _smsVerificationId;

  bool get _isOtpComplete => _otpController.text.length == _otpLength;

  String get _otpCode => _otpController.text;

  @override
  void initState() {
    super.initState();
    _startCountdowns();
    _otpController.addListener(_onOtpChanged);
    _otpFocus.addListener(_onFocusChanged);

    // Auto-focus no campo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _otpFocus.canRequestFocus) {
        _otpFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _otpController.removeListener(_onOtpChanged);
    _otpFocus.removeListener(_onFocusChanged);
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onOtpChanged() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    } else {
      // Redesenha as caixas quando o texto muda.
      setState(() {});
    }
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
        // Navegar para cadastro (push para manter pilha e permitir voltar)
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UnifiedCpfScreen(
                authController: widget.authController,
                themeController: widget.themeController,
                initialPhone: widget.phone,
              ),
            ),
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
          _otpController.clear();
          _otpFocus.requestFocus();
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

  /// Muda a tela para modo SMS: 6 dígitos em vez de 4
  void _switchToSmsMode(String verificationId) {
    setState(() {
      _isSmsMode = true;
      _smsVerificationId = verificationId;
      _otpLength = 6;
      _isLoading = false;
      _errorMessage = null;
    });
    _otpController.clear();

    // Focar no campo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _otpFocus.canRequestFocus) {
        _otpFocus.requestFocus();
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

  /// Campo OTP: um único TextField invisível por baixo (para autofill do iOS 26
  /// e Android) com caixas visuais por cima. A largura/altura das caixas
  /// acompanha `_otpLength` (4 WhatsApp / 6 SMS).
  Widget _buildOtpField() {
    final double boxSize = _isSmsMode ? 48 : 64;
    final double boxMargin = _isSmsMode ? 4 : 8;
    final double totalWidth =
        (boxSize + boxMargin * 2) * _otpLength;
    final String text = _otpController.text;

    return SizedBox(
      width: totalWidth,
      height: boxSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Campo real (transparente, por baixo). Recebe o autofill.
          Positioned.fill(
            child: AutofillGroup(
              child: TextField(
                controller: _otpController,
                focusNode: _otpFocus,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: _otpLength,
                autofillHints: const [AutofillHints.oneTimeCode],
                // Torna o texto real invisível — as caixas acima mostram os dígitos.
                showCursor: false,
                style: const TextStyle(
                  color: Colors.transparent,
                  // Fonte grande para ampliar a área de toque por caractere.
                  fontSize: 1,
                  height: 1,
                ),
                cursorColor: Colors.transparent,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_otpLength),
                ],
                onSubmitted: (_) {
                  if (_isOtpComplete) _handleVerify();
                },
              ),
            ),
          ),
          // Caixas visuais por cima. IgnorePointer para os toques chegarem
          // no TextField de baixo e abrirem o teclado normalmente.
          IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_otpLength, (index) {
                final bool hasDigit = index < text.length;
                final bool isActive = index == text.length && _otpFocus.hasFocus;
                return Container(
                  width: boxSize,
                  height: boxSize,
                  margin: EdgeInsets.symmetric(horizontal: boxMargin),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.inputEditableBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.primaryColor
                          : Colors.white.withValues(alpha: 0.2),
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    hasDigit ? text[index] : '',
                    style: TextStyle(
                      fontSize: _isSmsMode ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
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

              // Caixas de OTP: Stack com campo único (para autofill do iOS 26
              // e Android) por baixo, e caixas visuais por cima.
              _buildOtpField(),
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
