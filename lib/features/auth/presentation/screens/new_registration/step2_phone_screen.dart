import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:neves_capital/shared/components/phone_input_field.dart';
import 'package:neves_capital/shared/helpers/phone_helper.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/presentation/controllers/registration_lifecycle_observer.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/features/auth/presentation/screens/unified_cpf_screen.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'step3_otp_screen.dart';

/// Tela 2 do Cadastro: Insira seu telefone
class Step2PhoneScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;
  final String cpf;
  final String? initialPhone;
  final bool autoSubmitPhone;

  const Step2PhoneScreen({
    super.key,
    this.authController,
    this.themeController,
    required this.cpf,
    this.initialPhone,
    this.autoSubmitPhone = false,
  });

  @override
  State<Step2PhoneScreen> createState() => _Step2PhoneScreenState();
}

class _Step2PhoneScreenState extends State<Step2PhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  late RegistrationLifecycleObserver _lifecycleObserver;
  String? _prefilledPhone;
  bool _hasAutoSubmitted = false;

  @override
  void initState() {
    super.initState();

    // Configurar observer para salvar progresso apenas se o app for encerrado
    _lifecycleObserver = RegistrationLifecycleObserver(
      getCurrentProgress: _buildCurrentProgress,
      shouldSaveProgress: () => ModalRoute.of(context)?.isCurrent ?? false,
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    _prefilledPhone = _normalizeInitialPhone(widget.initialPhone);

    if (_prefilledPhone != null) {
      _phoneController.text = PhoneHelper.formatPhone(_prefilledPhone!);
    }

    // Abrir teclado automaticamente ou avançar se phone já veio validado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_prefilledPhone != null && widget.autoSubmitPhone) {
        _triggerAutoAdvance();
      } else {
        _phoneFocusNode.requestFocus();
      }
    });
  }

  void _triggerAutoAdvance() {
    if (_hasAutoSubmitted) return;
    _hasAutoSubmitted = true;
    _handleNext(autoTriggered: true);
  }

  String? _normalizeInitialPhone(String? phone) {
    if (phone == null || phone.isEmpty) return null;

    final cleaned = PhoneHelper.cleanPhone(phone);
    if (cleaned.isEmpty) {
      return null;
    }

    return cleaned;
  }

  RegistrationProgress _buildCurrentProgress() {
    return RegistrationProgress(
      cpf: widget.cpf,
      currentStep: 'phone',
      status: RegistrationStatus.inProgress,
      lastUpdated: DateTime.now(),
      phone: _safePhoneValue(),
    );
  }

  String? _safePhoneValue() {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) return null;

    try {
      return PhoneHelper.getPhoneNumbers(raw);
    } catch (e) {
      AppLogger.debug('Telefone parcial inválido - não será salvo: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _lifecycleObserver.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _phoneFocusNode.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleNext({bool autoTriggered = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = PhoneHelper.getPhoneNumbers(_phoneController.text);

      // MOCK: Simular envio de OTP para cadastro
      // Em produção, chamaria: FirestoreService.requestRegistrationOtp(widget.cpf, phone)
      AppLogger.debug(
          'MOCK: Enviando OTP de cadastro para CPF: ${widget.cpf.substring(0, 3)}***, Telefone: ${phone.substring(0, 2)}***');
      AppLogger.debug('MOCK: Código enviado: 1234');

      // Simular delay da API
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // Salvar progresso LOCALMENTE antes de navegar
      AppLogger.debug('Salvando progresso antes de navegar para OTP');
      await _lifecycleObserver.saveNow(localOnly: false);

      if (!mounted) return;

      // Navegar para tela de OTP
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Step3OtpScreen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: widget.cpf,
            phone: phone,
          ),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text(
          'Insira seu Celular',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        onBackPressed: () {
          // Se não houver tela anterior na pilha, navegar para tela de CPF
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            // Se não pode voltar, navegar para tela de CPF com CPF restaurado
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UnifiedCpfScreen(
                  authController: widget.authController,
                  themeController: widget.themeController,
                  initialPhone: widget.initialPhone,
                  initialCpf: widget.cpf,
                ),
              ),
            );
          }
        },
      ),
      body: SafeArea(
        top: false,
        child: KeyboardDismissWrapper(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24.0,
              MediaQuery.of(context).padding.top + kToolbarHeight + 40,
              24.0,
              0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enviaremos um código de verificação via WhatsApp',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PhoneInputField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    hintText: '(XX) XXXXX-XXXX',
                    autofocus: true,
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
                      onPressed: _isLoading ? null : _handleNext,
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
                              'Avançar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
