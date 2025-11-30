import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/shared/helpers/phone_helper.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/presentation/screens/cpf_check_screen.dart';
import 'package:neves_capital/features/auth/data/services/auth_api_service.dart';

/// Tela 3 do Login OTP: Insira o código OTP (6 dígitos)
class LoginStep3OtpScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;

  const LoginStep3OtpScreen({
    super.key,
    this.authController,
    this.themeController,
  });

  @override
  State<LoginStep3OtpScreen> createState() => _LoginStep3OtpScreenState();
}

class _LoginStep3OtpScreenState extends State<LoginStep3OtpScreen> {
  static const int _otpLength = 6;
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  String? _phone;
  int _resendCountdown = 0;
  bool _isOtpComplete = false;

  @override
  void initState() {
    super.initState();
    // Receber dados das telas anteriores
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _phone = args?['phone'] as String?;
    });

    // Listener para habilitar/desabilitar botão
    _otpController.addListener(() {
      final hasFullCode = _otpController.text.trim().length == _otpLength;
      if (hasFullCode != _isOtpComplete) {
        setState(() {
          _isOtpComplete = hasFullCode;
        });
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final otpCode = _otpController.text.trim();

      // Recuperar verificationId dos argumentos
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final verificationId = args?['verificationId'] as String?;

      if (verificationId == null) {
        throw Exception('ID de verificação inválido. Reinicie o processo.');
      }

      // 1. Verificar OTP no Firebase
      AppLogger.info('🔐 Verificando OTP no Firebase...');

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Falha na autenticação');
      }

      // 2. Obter Token
      final token = await user.getIdToken();
      AppLogger.info('✅ Autenticado no Firebase! Token obtido.');

      // 3. Verificar Status no Backend
      final result = await AuthApiService.checkUserStatus(token!);

      if (!mounted) return;

      final success = result['success'] as bool? ?? false;
      final status = result['status'] as String?;
      final message = result['message'] as String? ?? '';

      if (success) {
        if (status == 'REQUIRE_CPF_CHECK') {
          // Usuário existe, mas precisa confirmar CPF (2FA)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CpfCheckScreen(
                authController: widget.authController,
                themeController: widget.themeController,
              ),
              settings: RouteSettings(
                arguments: {
                  'token': token,
                },
              ),
            ),
          );
        } else if (status == 'REGISTER') {
          // Usuário não existe, ir para cadastro
          AppLogger.info(
              'Usuário não encontrado. Redirecionando para cadastro...');

          // Navegar para o fluxo de cadastro (UnifiedCpfScreen ou similar)
          // Como o usuário já validou o telefone, podemos passar essa informação
          // Mas o fluxo atual de cadastro começa pedindo CPF.
          // Vamos redirecionar para a tela de CPF unificado, mas talvez devêssemos
          // salvar o estado de que o telefone já foi validado.

          // Por enquanto, vamos apenas redirecionar para a tela de CPF (UnifiedCpfScreen)
          // que é o início do cadastro.
          // TODO: Melhorar UX para não pedir telefone de novo se possível.

          Navigator.pushReplacementNamed(context, '/unified-cpf');
          // Ou usar a rota direta se não tiver rota nomeada:
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UnifiedCpfScreen(...)));
          // Mas como não importei UnifiedCpfScreen aqui, vou usar um SnackBar por enquanto e pedir para implementar a navegação correta.

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Redirecionando para cadastro...')),
          );

          // TODO: Implementar navegação real para cadastro
        } else {
          setState(() {
            _errorMessage = 'Status desconhecido: $status';
          });
        }
      } else {
        setState(() {
          _errorMessage =
              message.isNotEmpty ? message : 'Erro ao verificar status';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e is FirebaseAuthException) {
            if (e.code == 'invalid-verification-code') {
              _errorMessage = 'Código inválido';
            } else {
              _errorMessage = e.message;
            }
          } else {
            _errorMessage = e.toString().replaceAll('Exception: ', '');
          }
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

    // Simular delay da API
    await Future.delayed(const Duration(seconds: 1));

    // MOCK: Reenviar OTP
    AppLogger.debug('MOCK: Reenviando OTP');
    AppLogger.debug('MOCK: Novo código: 123456');

    if (mounted) {
      setState(() {
        _isLoading = false;
        _resendCountdown = 60; // 60 segundos de countdown
      });

      // Iniciar countdown
      _startResendCountdown();
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
        child: LayoutBuilder(
          // Garante rolagem adequada quando o teclado reduz a altura útil.
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
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
                          _phone != null && _phone!.isNotEmpty
                              ? 'Informe o código de verificação recebido no número ${PhoneHelper.maskPhoneLast4(_phone!)}'
                              : 'Informe o código de verificação recebido',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 40),
                        TextFormField(
                          controller: _otpController,
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
                            fillColor: Colors.white.withValues(alpha: 0.1),
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
                                  color: Color(0xFF22C55E), width: 2),
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
                                  color: Color(0xFF22C55E),
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
    );
  }
}
