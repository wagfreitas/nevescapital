import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:neves_capital/shared/components/phone_input_field.dart';
import 'package:neves_capital/shared/helpers/phone_helper.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/features/auth/presentation/screens/login_otp/login_step3_otp_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';

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
  final FocusNode _phoneFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }


  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obter telefone limpo (já inclui código do país do PhoneInputField)
      String phone = PhoneHelper.getPhoneNumbers(_phoneController.text);

      // Validar se o telefone tem pelo menos o código do país + 10 dígitos
      if (phone.length < 12) { // Mínimo: código do país (2-3 dígitos) + 10 dígitos
        setState(() {
          _isLoading = false;
          _errorMessage = 'Telefone inválido. Digite um número válido.';
        });
        return;
      }

      // Formatar para E.164 (+código do país + número)
      final formattedPhone = '+$phone';

      AppLogger.info('🚀 Iniciando login Firebase');
      AppLogger.info('📱 Telefone original: ${_phoneController.text}');
      AppLogger.info('📱 Telefone limpo: $phone');
      AppLogger.info('📱 Telefone formatado (E.164): $formattedPhone');
      AppLogger.info('📱 Comprimento: ${formattedPhone.length} caracteres');

      // Firebase Phone Auth
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
          
          if (mounted) {
            setState(() {
              _isLoading = false;
              if (e.code == 'invalid-phone-number') {
                _errorMessage = 'Número de telefone inválido. Verifique o formato.';
              } else if (e.code == 'too-many-requests') {
                _errorMessage = 'Muitas tentativas. Aguarde alguns minutos.';
              } else if (e.code == 'internal-error') {
                // Erro interno pode ter várias causas
                // Detectar plataforma para dar instruções específicas
                final isIOS = !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || Platform.isIOS);
                
                // Mensagem focada na solução real para produção
                _errorMessage = 'Erro de configuração do Firebase (internal-error).\n\n'
                    '🔧 AÇÃO NECESSÁRIA:\n\n'
                    '${isIOS ? "1. Configure APNs no Firebase Console:" : "1. Configure SHA-1 no Firebase Console:"}\n'
                    '   ${isIOS ? "Project Settings > Cloud Messaging > APNs authentication key" : "Project Settings > Your apps > Android > SHA certificate fingerprints"}\n'
                    '   ${isIOS ? "Faça upload do arquivo .p8 da Apple Developer" : "SHA-1 Debug: 33:2A:B5:0C:B5:9B:A9:C1:F2:8D:02:13:AE:01:67:56:AE:11:CB:16"}\n\n'
                    '2. Verifique Phone Auth habilitado:\n'
                    '   Authentication > Sign-in method > Phone > Enable';
              } else if (e.code == 'missing-phone-number') {
                _errorMessage = 'Número de telefone não fornecido.';
              } else if (e.code == 'quota-exceeded') {
                _errorMessage = 'Limite de SMS excedido. Tente mais tarde.';
              } else if (e.code == 'user-disabled') {
                _errorMessage = 'Conta desabilitada. Contate o suporte.';
              } else if (e.code == 'operation-not-allowed') {
                _errorMessage = 'Autenticação por telefone não habilitada.';
              } else {
                _errorMessage = 'Erro: ${e.message ?? e.code}';
              }
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          AppLogger.info('✅ Código enviado. VerificationId: $verificationId');
          AppLogger.debug('📱 ResendToken: ${resendToken != null ? "disponível" : "não disponível"}');

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
                  'formattedPhone': formattedPhone, // Telefone formatado E.164 para reenvio
                  'verificationId': verificationId,
                  'resendToken': resendToken, // Token para reenvio
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
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            // Evita crash: não dar pop enquanto teclado está aberto.
            if (FocusManager.instance.primaryFocus != null) {
              FocusScope.of(context).unfocus();
            }
            if (!context.mounted) return;
            // Voltar para a tela de onboarding
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OnboardingScreen(
                  authController: widget.authController ?? AuthController(),
                  themeController: widget.themeController,
                ),
              ),
            );
          },
        ),
      ),
      body: KeyboardDismissWrapper(
        focusNodes: [_phoneFocusNode],
        doneText: 'OK',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(top: 40.0, bottom: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/PagPag_icon.png',
                          width: 120,
                          height: 120,
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
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 14),
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
                            focusNode: _phoneFocusNode,
                            labelText: 'Celular',
                            hintText: '(00) 00000-0000',
                            autofocus: true,
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
                        // Espaço extra entre input e botão - aumenta quando teclado está aberto
                        SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 80 : 40),
                      ],
                    ),
                  ),
                ),
                // Padding adicional quando teclado está aberto
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 0),
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
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
