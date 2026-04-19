import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:neves_capital/shared/helpers/cpf_helper.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/registration_phone_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/registration_email_screen.dart';
import 'package:neves_capital/features/auth/data/services/local_registration_storage.dart';
import 'package:neves_capital/shared/helpers/phone_helper.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'package:neves_capital/features/home/presentation/screens/main_tab_screen.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/features/auth/presentation/screens/phone_login_screen.dart';

/// Tela Unificada de CPF
/// Verifica se o CPF existe e direciona para:
/// - LOGIN automatico se CPF ja cadastrado
/// - CADASTRO se CPF nao cadastrado
class UnifiedCpfScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;
  final String? initialPhone;
  final String? initialCpf;

  const UnifiedCpfScreen({
    super.key,
    this.authController,
    this.themeController,
    this.initialPhone,
    this.initialCpf,
  });

  @override
  State<UnifiedCpfScreen> createState() => _UnifiedCpfScreenState();
}

class _UnifiedCpfScreenState extends State<UnifiedCpfScreen> {
  final _cpfController = TextEditingController();
  final _cpfMaskedController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    if (widget.initialCpf != null && widget.initialCpf!.isNotEmpty) {
      _cpfController.text = CpfHelper.getCpfNumbers(widget.initialCpf!);
      _cpfMaskedController.text = CpfHelper.formatCpf(widget.initialCpf!);
    }

    _cpfMaskedController.addListener(() {
      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      }
    });
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _cpfMaskedController.dispose();
    super.dispose();
  }

  void _onCpfChanged(String value) {
    final cleanValue = CpfHelper.cleanCpf(value);
    final limitedValue =
        cleanValue.length > 11 ? cleanValue.substring(0, 11) : cleanValue;
    final formatted = CpfHelper.formatCpf(limitedValue);
    if (_cpfMaskedController.text != formatted) {
      _cpfMaskedController.text = formatted;
      _cpfMaskedController.selection =
          TextSelection.collapsed(offset: formatted.length);
    }
    _cpfController.text = limitedValue;
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    final cpf = CpfHelper.getCpfNumbers(_cpfController.text);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FirestoreService.checkCpf(cpf);

      if (!mounted) return;

      final success = result['success'] as bool? ?? false;
      final exists = result['exists'] as bool? ?? false;

      if (success && exists) {
        await _handleLogin(cpf);
      } else if (success && !exists) {
        _handleRegistration(cpf);
      } else {
        setState(() => _errorMessage = 'Erro ao verificar CPF. Tente novamente.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Erro de conexão. Verifique sua internet.');
        AppLogger.error('Erro ao verificar CPF: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// CPF existe - fazer login automatico
  Future<void> _handleLogin(String cpf) async {
    if (widget.authController == null) {
      if (mounted) {
        setState(() => _errorMessage = 'Erro interno. Tente novamente.');
      }
      return;
    }

    final loginSuccess = await widget.authController!.loginWithOtp(cpf);

    if (!mounted) return;

    if (loginSuccess) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => MainTabScreen(
            authController: widget.authController!,
            themeController: widget.themeController ?? ThemeController(),
          ),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        _errorMessage = widget.authController?.errorMessage ??
            'Erro ao fazer login. Tente novamente.';
      });
    }
  }

  /// CPF nao existe - direcionar para cadastro
  /// Carrega progresso salvo para preservar dados ja preenchidos
  Future<void> _handleRegistration(String cpf) async {
    if (!mounted) return;

    // Carregar progresso salvo (caso o usuario tenha voltado)
    final savedProgress = await LocalRegistrationStorage.getLocal();
    final savedPhone = savedProgress?.phone;
    final normalizedPhone = _normalizePhone(widget.initialPhone) ?? savedPhone;

    // DEBUG: remover depois
    AppLogger.info('DEBUG _handleRegistration:');
    AppLogger.info('  savedProgress: ${savedProgress != null}');
    AppLogger.info('  savedProgress.cpf: ${savedProgress?.cpf}');
    AppLogger.info('  savedProgress.phone: ${savedProgress?.phone}');
    AppLogger.info('  savedProgress.email: ${savedProgress?.email}');
    AppLogger.info('  savedProgress.currentStep: ${savedProgress?.currentStep}');
    AppLogger.info('  widget.initialPhone: ${widget.initialPhone}');
    AppLogger.info('  normalizedPhone: $normalizedPhone');
    AppLogger.info('  savedPhone: $savedPhone');

    if (!mounted) return;

    final nextScreen = normalizedPhone != null
        ? RegistrationEmailScreen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: cpf,
            phone: normalizedPhone,
            initialEmail: savedProgress?.email,
          )
        : RegistrationPhoneScreen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: cpf,
            initialPhone: savedPhone,
          );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PhoneLoginScreen(
            authController: widget.authController,
            themeController: widget.themeController,
          ),
        ),
      );
    }
  }

  /// Normaliza telefone removendo DDI 55 se necessario.
  String? _normalizePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;

    try {
      final numbers = PhoneHelper.getPhoneNumbers(phone);

      // Remover DDI 55 se presente
      if (numbers.length > 11 && numbers.startsWith('55')) {
        return numbers.substring(2);
      }

      if (numbers.length >= 10 && numbers.length <= 11) {
        return numbers;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text(
          'CPF',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        onBackPressed: _handleBack,
      ),
      body: SafeArea(
        top: false,
        child: KeyboardDismissWrapper(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: EdgeInsets.fromLTRB(
              24.0,
              MediaQuery.of(context).padding.top + kToolbarHeight + 40,
              24.0,
              MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    _buildErrorBanner(),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _cpfMaskedController,
                    autofocus:
                        widget.initialCpf == null || widget.initialCpf!.isEmpty,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(14),
                    ],
                    onChanged: _onCpfChanged,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite seu CPF';
                      }
                      final cpfNumbers = CpfHelper.getCpfNumbers(value);
                      if (cpfNumbers.length != 11) {
                        return 'CPF deve ter 11 dígitos';
                      }
                      if (!CpfHelper.isValidCpf(value)) {
                        return 'CPF inválido. Verifique os dígitos.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'CPF',
                      labelStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      hintText: '000.000.000-00',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      filled: true,
                      fillColor: AppTheme.inputEditableBackgroundColor,
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
                            color: AppTheme.primaryColor, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.red, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                  ),
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
                              'Continuar',
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

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 1),
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
    );
  }
}
