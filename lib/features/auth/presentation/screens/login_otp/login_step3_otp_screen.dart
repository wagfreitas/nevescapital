import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/shared/helpers/phone_helper.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'biometric_setup_screen.dart';

/// Tela 3 do Login OTP: Insira o código OTP (4 dígitos)
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
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  String? _cpf;
  String? _phone;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    // Receber dados das telas anteriores
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _cpf = args?['cpf'] as String?;
      _phone = args?['phone'] as String?;
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

    // Simular delay da API
    await Future.delayed(const Duration(seconds: 2));

    try {
      final otpCode = _otpController.text.trim();
      
      // MOCK: Simular verificação de OTP
      // Em produção, chamaria: DatabaseService.verifyLoginOtp(_cpf!, _phone!, otpCode)
      // E depois: AuthController.loginWithOtp() com o custom token recebido
      final success = _mockVerifyOtp(otpCode);

      if (!mounted) return;

      if (!success) {
        setState(() {
          _errorMessage = 'Código inválido. Tente novamente.';
        });
      } else {
        // OTP válido (primeiro fator) - navegar para segundo fator (biometria)
        // O login só será completado após validar a biometria também
        AppLogger.info('OTP: Primeiro fator verificado com sucesso');
        AppLogger.debug('Próximo passo: Segundo fator (Biometria Facial)');
        
        // Navegar para tela de segundo fator (biometria)
        if (mounted && widget.authController != null && _cpf != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BiometricSetupScreen(
                authController: widget.authController!,
                themeController: widget.themeController,
                cpf: _cpf!,
              ),
            ),
          );
        }
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

  // MOCK: Simula verificação de OTP
  bool _mockVerifyOtp(String otpCode) {
    // Para teste: aceita qualquer código de 4 dígitos
    // Em produção, isso virá da API
    return otpCode.length == 4;
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
                  maxLength: 4,
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
                    hintText: '0000',
                    hintStyle: TextStyle(
                      fontSize: 32,
                      color: Colors.white.withOpacity(0.3),
                      letterSpacing: 12,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Digite o código';
                    }
                    if (value.trim().length != 4) {
                      return 'Código deve ter 4 dígitos';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
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
                    onPressed: _isLoading ? null : _handleVerifyOtp,
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
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF122118)),
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
                        color: Colors.white.withOpacity(0.5),
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
  }
}

