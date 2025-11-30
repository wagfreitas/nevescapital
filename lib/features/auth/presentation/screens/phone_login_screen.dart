import 'package:flutter/material.dart';
import 'package:neves_capital/shared/components/phone_input_field.dart';
import 'package:neves_capital/shared/helpers/phone_helper.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/presentation/screens/login_otp/login_step3_otp_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Tela de Login via Telefone (Phone-First)
class PhoneLoginScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;

  const PhoneLoginScreen({
    super.key,
    this.authController,
    this.themeController,
  });

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // 🎭 MODO FAKE OTP PARA DESENVOLVIMENTO
  static const bool _useFakeOtp = true;
  static const String _fakeVerificationId = 'fake-verification-id-123';

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obter telefone limpo (apenas números, com DDI 55 se não tiver)
      String phone = PhoneHelper.getPhoneNumbers(_phoneController.text);

      // Garantir DDI 55
      if (!phone.startsWith('55')) {
        phone = '55$phone';
      }

      // Formatar para E.164 (+55...)
      final formattedPhone = '+$phone';

      AppLogger.info(
          '🚀 Iniciando login Firebase para telefone: $formattedPhone');

      // 🎭 MODO FAKE: Simular envio de OTP
      if (_useFakeOtp) {
        AppLogger.info('🎭 MODO FAKE OTP ATIVADO - Código: 123456');

        // Simular delay de rede
        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        // Navegar para tela de OTP com dados fake
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginStep3OtpScreen(
              authController: widget.authController,
              themeController: widget.themeController,
            ),
            settings: RouteSettings(
              arguments: {
                'phone': phone,
                'verificationId': _fakeVerificationId,
                'maskedPhone': PhoneHelper.maskPhoneLast4(phone),
                'isFakeMode': true,
              },
            ),
          ),
        );
        return;
      }

      // MODO REAL: Firebase Phone Auth
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval ou Instant validation (Android)
          AppLogger.info('✅ Verificação automática concluída!');
          // Em alguns casos, o Android faz o login automático.
          // Vamos passar a credencial para a próxima tela ou logar direto.
          // Por simplicidade, vamos deixar o usuário ir para a tela de OTP
          // e lá ele vai detectar que já está logado ou usar o código.
          // Mas o ideal é tratar aqui.

          // Vamos logar direto aqui se possível
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (!mounted) return;
            // Se logou, vai para a próxima tela (que vai verificar o status do usuário)
            // Mas como a arquitetura pede OTP screen, vamos navegar para lá
            // passando a credencial ou indicando sucesso.

            // Simplificação: Vamos deixar o fluxo seguir para codeSent na maioria dos casos,
            // mas se cair aqui, vamos navegar para a tela de OTP com um flag de "auto-verified"
            // ou simplesmente deixar o usuário digitar o código (que pode não chegar se já validou).

            // Melhor abordagem: Navegar para tela de OTP passando a credencial
            // A tela de OTP vai detectar que tem credencial e logar.
          } catch (e) {
            AppLogger.error('Erro no auto-sign-in: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          AppLogger.error('❌ Falha na verificação: ${e.code} - ${e.message}');
          if (mounted) {
            setState(() {
              _isLoading = false;
              if (e.code == 'invalid-phone-number') {
                _errorMessage = 'Número de telefone inválido.';
              } else if (e.code == 'too-many-requests') {
                _errorMessage = 'Muitas tentativas. Aguarde alguns minutos.';
              } else if (e.code == 'internal-error') {
                _errorMessage =
                    'Erro interno. Use um dispositivo real ou configure número de teste no Firebase Console.';
              } else {
                _errorMessage = 'Erro: ${e.message}';
              }
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          AppLogger.info('✅ Código enviado. VerificationId: $verificationId');

          if (!mounted) return;

          setState(() {
            _isLoading = false;
          });

          // Navegar para tela de OTP
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginStep3OtpScreen(
                authController: widget.authController,
                themeController: widget.themeController,
              ),
              settings: RouteSettings(
                arguments: {
                  'phone': phone,
                  'verificationId': verificationId,
                  'maskedPhone': PhoneHelper.maskPhoneLast4(phone),
                },
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          AppLogger.debug(
              '⏰ Timeout de auto-retrieval. VerificationId: $verificationId');
          // Não precisa fazer nada específico aqui, o usuário ainda pode digitar o código
        },
      );

      // Nota: O loading continua até o callback codeSent ou verificationFailed ser chamado
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro inesperado: $e';
        });
      }
    }
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Image.asset(
                'assets/icons/logo_ios_filled.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 40),
              const Text(
                'Bem-vindo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Digite seu celular para entrar ou criar uma conta',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (_errorMessage != null) ...[
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
                          style:
                              const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Form(
                key: _formKey,
                child: PhoneInputField(
                  controller: _phoneController,
                  labelText: 'Celular',
                  hintText: '(00) 00000-0000',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite seu celular';
                    }
                    if (!PhoneHelper.isValidPhone(value)) {
                      return 'Celular inválido';
                    }
                    return null;
                  },
                ),
              ),
              // 🎯 BOTÃO DE AUTO-FILL (MODO DEBUG)
              if (_useFakeOtp) ...[
                TextButton.icon(
                  onPressed: () {
                    _phoneController.text = '11989630454';
                  },
                  icon: const Icon(Icons.flash_on, color: Colors.orange),
                  label: const Text(
                    'Auto-preencher teste',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28CC28),
                    foregroundColor: Colors.white,
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
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Continuar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
