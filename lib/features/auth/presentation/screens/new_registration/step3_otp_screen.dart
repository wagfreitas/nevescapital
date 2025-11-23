import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/shared/helpers/phone_helper.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/presentation/controllers/registration_lifecycle_observer.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'step4_email_screen.dart';

/// Tela 3 do Cadastro: Insira o código OTP (4 dígitos)
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
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  int _resendCountdown = 0;
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
  }

  @override
  void dispose() {
    _lifecycleObserver.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
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

        // Salvar progresso LOCALMENTE antes de navegar
        AppLogger.debug('Salvando progresso antes de navegar para Email');
        await _lifecycleObserver.saveNow(localOnly: true);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Step4EmailScreen(
                authController: widget.authController,
                themeController: widget.themeController,
                cpf: widget.cpf,
                phone: widget.phone,
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
    AppLogger.debug(
        'MOCK: Reenviando OTP para telefone: ${widget.phone.substring(0, 2)}***');
    AppLogger.debug('MOCK: Novo código: 1234');

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
                  'Informe o código de verificação recebido no número ${PhoneHelper.maskPhoneLast4(widget.phone)}',
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
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF22C55E), width: 2),
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
