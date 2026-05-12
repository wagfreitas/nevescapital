import 'package:flutter/material.dart';
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

class _WhatsAppOtpScreenState extends State<WhatsAppOtpScreen>
    with WidgetsBindingObserver {
  static const int _whatsappOtpLength = 4;
  static const int _smsOtpLength = 6;
  int get _otpLength => _usingSmsVerify ? _smsOtpLength : _whatsappOtpLength;

  /// Flag pra detectar volta do background. Vira true quando o app sai
  /// (paused/hidden/inactive); ao voltar (resumed), redireciona pra CPF.
  bool _wasBackgrounded = false;

  // ZWSP "fantasma" em cada caixa pra detectar backspace em caixa vazia.
  // Se o controller cai pra string vazia, é porque o backspace apagou o ZWSP →
  // sabemos que veio um backspace, mesmo na caixa vazia.
  static const String _zwsp = '​';

  // Lista de controllers/focus, um por caixa.
  late List<TextEditingController> _boxControllers;
  late List<FocusNode> _boxFocuses;
  // _boxFilled[i] = true se a caixa i tem um dígito real (não só ZWSP).
  // Usado pra distinguir backspace em caixa cheia vs vazia.
  late List<bool> _boxFilled;

  bool _isLoading = false;
  String? _errorMessage;
  int _resendCountdown = 30;
  int _smsCountdown = 30;
  int _failedAttempts = 0;
  static const int _maxFailedAttempts = 3;

  /// true quando o último envio foi por SMS (Twilio Verify);
  /// muda o endpoint de verificação para check-otp-verify.
  bool _usingSmsVerify = false;

  String _digitOf(int index) {
    final t = _boxControllers[index].text.replaceAll(_zwsp, '');
    return t.isEmpty ? '' : t;
  }

  bool get _isOtpComplete =>
      List.generate(_otpLength, _digitOf).every((d) => d.isNotEmpty);

  String get _otpCode =>
      List.generate(_otpLength, _digitOf).join();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initBoxes(_otpLength);
    _startCountdowns();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _boxFocuses[0].canRequestFocus) {
        _boxFocuses[0].requestFocus();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      _wasBackgrounded = true;
    } else if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      _redirectToCpfScreen();
    }
  }

  /// Quando o usuário volta do background pra tela de OTP, redireciona pro
  /// início do fluxo (UnifiedCpfScreen). O OTP pode ter expirado e o melhor
  /// é reiniciar a identificação por CPF — daí o app decide login ou cadastro.
  void _redirectToCpfScreen() {
    if (!mounted) return;
    AppLogger.info(
        'OTP: app voltou do background — redirecionando pra UnifiedCpfScreen');
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

  void _initBoxes(int length) {
    _boxControllers = List.generate(length, (_) {
      final c = TextEditingController(text: _zwsp);
      c.selection = const TextSelection.collapsed(offset: 1);
      return c;
    });
    _boxFocuses = List.generate(
        length, (_) => FocusNode()..addListener(_onAnyFocusChanged));
    _boxFilled = List.filled(length, false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final c in _boxControllers) {
      c.dispose();
    }
    for (final f in _boxFocuses) {
      f
        ..removeListener(_onAnyFocusChanged)
        ..dispose();
    }
    super.dispose();
  }

  void _onAnyFocusChanged() {
    if (mounted) setState(() {});
  }

  /// Reset visual de todas as caixas pro estado "vazio" (ZWSP).
  /// Se o tamanho mudou (ex: WhatsApp→SMS), recria controllers e focus nodes.
  void _resetBoxes() {
    if (_boxControllers.length != _otpLength) {
      _disposeBoxes();
      _initBoxes(_otpLength);
      return;
    }
    for (int i = 0; i < _boxControllers.length; i++) {
      _boxControllers[i].text = _zwsp;
      _boxControllers[i].selection =
          const TextSelection.collapsed(offset: 1);
      _boxFilled[i] = false;
    }
  }

  void _disposeBoxes() {
    for (final c in _boxControllers) {
      c.dispose();
    }
    for (final f in _boxFocuses) {
      f
        ..removeListener(_onAnyFocusChanged)
        ..dispose();
    }
  }

  /// Distribui um código colado/autofill nas caixas (pad com vazios se for menor).
  void _distributeCode(String digits) {
    for (int i = 0; i < _otpLength; i++) {
      final ch = i < digits.length ? digits[i] : '';
      _boxControllers[i].text = ch.isEmpty ? _zwsp : ch;
      _boxControllers[i].selection = TextSelection.collapsed(
        offset: _boxControllers[i].text.length,
      );
      _boxFilled[i] = ch.isNotEmpty;
    }
    final focusIdx =
        digits.length >= _otpLength ? _otpLength - 1 : digits.length;
    if (focusIdx < _otpLength) {
      _boxFocuses[focusIdx].requestFocus();
    }
    if (digits.length >= _otpLength && !_isLoading) {
      _handleVerify();
    }
  }

  /// Lida com mudanças em uma caixa específica.
  ///
  /// Convenção: cada caixa tem ZWSP como conteúdo "vazio" e o dígito real
  /// quando preenchida (sem ZWSP). Isso permite distinguir backspace em caixa
  /// vazia (text vai pra '') de digitação (text vai pra `<digit>` ou
  /// `<zwsp><digit>`).
  void _onBoxChanged(int index, String value) {
    final cleanDigits = value.replaceAll(_zwsp, '').replaceAll(RegExp(r'\D'), '');

    // Autofill / paste: vários dígitos chegaram de uma vez na primeira caixa.
    if (cleanDigits.length > 1) {
      _distributeCode(cleanDigits);
      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      } else {
        setState(() {});
      }
      return;
    }

    if (value.isEmpty) {
      // Backspace foi pressionado. Distingue dois casos pelo estado anterior:
      //   (a) Caixa estava CHEIA → apaga só ela, foco vai pra anterior, NÃO
      //       toca em nenhuma outra (atende req do usuário).
      //   (b) Caixa estava VAZIA → só pula foco pra anterior. NÃO apaga a
      //       anterior nesse passo (o usuário pode dar backspace de novo).
      final wasFilled = _boxFilled[index];

      // Restaura ZWSP pra próxima detecção.
      _boxControllers[index].text = _zwsp;
      _boxControllers[index].selection =
          const TextSelection.collapsed(offset: 1);
      _boxFilled[index] = false;

      if (wasFilled) {
        // Caso (a): apaga só esta caixa, foco pra anterior se houver.
        if (index > 0) {
          _boxFocuses[index - 1].requestFocus();
        }
      } else {
        // Caso (b): só pula foco pra anterior.
        if (index > 0) {
          _boxFocuses[index - 1].requestFocus();
        }
      }

      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      } else {
        setState(() {});
      }
      return;
    }

    // Houve digitação. Pega só o último dígito (substituição) e normaliza.
    if (cleanDigits.isEmpty) {
      // Algo não-numérico foi tentado. Restaura ZWSP.
      _boxControllers[index].text = _zwsp;
      _boxControllers[index].selection =
          const TextSelection.collapsed(offset: 1);
      return;
    }
    final digit = cleanDigits[cleanDigits.length - 1];
    _boxControllers[index].text = digit;
    _boxControllers[index].selection = const TextSelection.collapsed(offset: 1);
    _boxFilled[index] = true;

    // Avança foco se não for a última.
    if (index < _otpLength - 1) {
      _boxFocuses[index + 1].requestFocus();
    } else {
      _boxFocuses[index].unfocus();
    }

    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    } else {
      setState(() {});
    }

    // Se completou, dispara verificação automaticamente.
    if (_isOtpComplete && !_isLoading) {
      _handleVerify();
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

      if (_usingSmsVerify) {
        await _handleVerifySms(code);
      } else {
        await _handleVerifyWhatsApp(code);
      }
    } catch (e) {
      AppLogger.error('Erro ao verificar OTP: $e');
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

  /// Verificação via Twilio Verify (canal SMS).
  /// Após sucesso, navega para UnifiedCpfScreen que decide login ou cadastro.
  Future<void> _handleVerifySms(String code) async {
    AppLogger.info('Verificando OTP via Twilio Verify (SMS)');

    final result =
        await AuthApiService.checkVerifyOtp(widget.phone, code);

    if (!mounted) return;

    final success = result['success'] as bool? ?? false;

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

    _failedAttempts = 0;

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
  }

  /// Verificação padrão via WhatsApp (simpleOtpService + user lookup).
  Future<void> _handleVerifyWhatsApp(String code) async {
    AppLogger.info('Verificando OTP via WhatsApp');

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

    _failedAttempts = 0;

    if (status == 'LOGGED_IN') {
      final customToken = result['customToken'] as String?;
      final userId = result['userId'] as String?;

      if (customToken != null) {
        AppLogger.info('Fazendo login com Custom Token...');
        await FirebaseAuth.instance.signInWithCustomToken(customToken);
      }

      if (userId != null && widget.authController != null) {
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
        _isLoading = false;
        _resendCountdown = 30;
        _usingSmsVerify = false;
        _resetBoxes();
        setState(() {});
        _startResendCountdown();

        if (result['success'] == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _boxFocuses[0].requestFocus();
          });
        } else {
          _errorMessage =
              result['message'] as String? ?? 'Erro ao reenviar código';
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

  /// Envia OTP via SMS usando Twilio Verify Service.
  /// Marca [_usingSmsVerify] = true para que a verificação use check-otp-verify.
  Future<void> _handleSmsFallback() async {
    if (_smsCountdown > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      AppLogger.info('Solicitando OTP via SMS (Twilio Verify)');

      final result =
          await AuthApiService.sendVerifyOtp(widget.phone, 'sms');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _smsCountdown = 30;
        _resendCountdown = 30;
      });
      _startSmsCountdown();
      _startResendCountdown();

      if (result['success'] == true) {
        _usingSmsVerify = true;
        _resetBoxes();
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _boxFocuses[0].requestFocus();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Código enviado por SMS!'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
      } else {
        setState(() {
          _errorMessage =
              result['message'] as String? ?? 'Erro ao enviar SMS';
        });
      }
    } catch (e) {
      AppLogger.error('Erro ao enviar SMS via Verify: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao enviar SMS. Tente novamente.';
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

  Widget _buildOtpField() {
    final double boxSize = _otpLength <= 4 ? 64 : 48;
    final double boxMargin = _otpLength <= 4 ? 8 : 6;

    return AutofillGroup(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_otpLength, (index) {
          final bool isFocused = _boxFocuses[index].hasFocus;

          return Container(
            width: boxSize,
            height: boxSize,
            margin: EdgeInsets.symmetric(horizontal: boxMargin),
            // clipBehavior + ClipRRect garantem que o TextField interno
            // respeite as bordas arredondadas do container.
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppTheme.inputEditableBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFocused
                    ? AppTheme.primaryColor
                    : Colors.white.withValues(alpha: 0.2),
                width: isFocused ? 2 : 1,
              ),
            ),
            child: Center(
              child: TextField(
                controller: _boxControllers[index],
                focusNode: _boxFocuses[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                // Autofill hint só na primeira caixa — quando iOS preenche, o
                // _onBoxChanged detecta vários dígitos e distribui entre as outras.
                autofillHints:
                    index == 0 ? const [AutofillHints.oneTimeCode] : null,
                maxLength: 2, // ZWSP + dígito; permite paste maior.
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  // height 1.0 → linha de texto sem espaço extra acima/abaixo,
                  // o Center fica responsável pelo centralizado.
                  height: 1.0,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  // isCollapsed: campo fica exatamente da altura do texto,
                  // sem padding interno do Material — o Center centraliza.
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
                onChanged: (value) => _onBoxChanged(index, value),
              ),
            ),
          );
        }),
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
                _usingSmsVerify
                    ? 'Informe o código de verificação enviado por SMS para o número +55 $formattedDisplay'
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
                        'Não recebi, enviar por SMS ${_smsCountdown}s',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      )
                    : TextButton(
                        onPressed: _isLoading ? null : _handleSmsFallback,
                        child: const Text(
                          'Não recebi, enviar por SMS',
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

