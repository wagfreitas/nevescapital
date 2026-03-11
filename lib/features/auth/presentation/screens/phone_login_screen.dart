import 'package:flutter/material.dart';
import 'package:neves_capital/shared/components/phone_input_field.dart';
import 'package:neves_capital/shared/helpers/phone_helper.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:neves_capital/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/whatsapp_otp_screen.dart';
import 'package:neves_capital/features/auth/data/services/auth_api_service.dart';
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
      if (phone.length < 12) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Telefone inválido. Digite um número válido.';
        });
        return;
      }

      // Formatar para E.164 (+código do país + número)
      final formattedPhone = '+$phone';

      AppLogger.info('🚀 Enviando OTP via WhatsApp');
      AppLogger.info('📱 Telefone limpo: $phone');
      AppLogger.info('📱 Telefone formatado (E.164): $formattedPhone');

      // Enviar OTP via WhatsApp (backend)
      final result = await AuthApiService.sendOtpWhatsApp(phone);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() => _isLoading = false);

        // Navegar para tela de OTP WhatsApp (4 dígitos)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WhatsAppOtpScreen(
              phone: phone,
              formattedPhone: formattedPhone,
              authController: widget.authController,
              themeController: widget.themeController,
            ),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'] as String? ??
              'Erro ao enviar código via WhatsApp. Tente novamente.';
        });
      }
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
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        onBackPressed: () async {
          if (FocusManager.instance.primaryFocus != null) {
            FocusScope.of(context).unfocus();
          }
          if (!context.mounted) return;
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
                          'Digite seu celular para continuar',
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
