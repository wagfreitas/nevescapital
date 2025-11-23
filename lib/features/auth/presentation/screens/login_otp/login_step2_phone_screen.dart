import 'package:flutter/material.dart';
import 'package:neves_capital/shared/components/phone_input_field.dart';
import 'package:neves_capital/shared/helpers/phone_helper.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'login_step3_otp_screen.dart';

/// Tela 2 do Login OTP: Insira seu telefone
class LoginStep2PhoneScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;

  const LoginStep2PhoneScreen({
    super.key,
    this.authController,
    this.themeController,
  });

  @override
  State<LoginStep2PhoneScreen> createState() => _LoginStep2PhoneScreenState();
}

class _LoginStep2PhoneScreenState extends State<LoginStep2PhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  String? _cpf;

  @override
  void initState() {
    super.initState();
    // Receber CPF da tela anterior
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _cpf = args?['cpf'] as String?;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simular delay da API
    await Future.delayed(const Duration(seconds: 2));

    try {
      final phone = PhoneHelper.getPhoneNumbers(_phoneController.text);
      
      // MOCK: Simular envio de OTP
      // Em produção, chamaria: DatabaseService.requestLoginOtp(_cpf!, phone)
      final success = _mockRequestOtp(_cpf ?? '', phone);

      if (!mounted) return;

      if (!success) {
        setState(() {
          _errorMessage = 'Erro ao enviar código. Tente novamente.';
        });
      } else {
        // OTP enviado - continuar para próxima tela (verificação)
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginStep3OtpScreen(
                authController: widget.authController,
                themeController: widget.themeController,
              ),
              settings: RouteSettings(
                arguments: {
                  'cpf': _cpf,
                  'phone': phone,
                },
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

  // MOCK: Simula envio de OTP
  bool _mockRequestOtp(String cpf, String phone) {
    // Para teste: sempre retorna sucesso
    // Em produção, isso virá da API
    AppLogger.debug('MOCK: Enviando OTP');
    AppLogger.sensitive('CPF/Telefone', '$cpf/$phone');
    AppLogger.debug('MOCK: Código enviado: 123456');
    return true;
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
                  'Insira seu telefone',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enviaremos um código de verificação via WhatsApp',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                PhoneInputField(
                  controller: _phoneController,
                  hintText: '(XX) XXXXX-XXXX',
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
                    onPressed: _isLoading ? null : _handleSendOtp,
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
                            'Enviar Código',
                            style: TextStyle(
                              fontSize: 18,
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

