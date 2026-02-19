import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:neves_capital/shared/helpers/cpf_helper.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/step2_phone_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/new_registration/step4_email_screen.dart';
import 'package:neves_capital/features/auth/data/services/registration_service.dart';
import 'package:neves_capital/features/auth/presentation/helpers/registration_navigator.dart';
import 'package:neves_capital/shared/helpers/phone_helper.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'package:neves_capital/features/home/presentation/screens/main_tab_screen.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/features/auth/presentation/screens/phone_login_screen.dart';

/// Tela Unificada: Insira seu CPF
/// Verifica se o CPF existe e direciona automaticamente para:
/// - Fluxo de LOGIN (com OTP) se CPF já cadastrado
/// - Fluxo de CADASTRO se CPF não cadastrado
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
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _cpfMaskedController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Restaurar CPF se fornecido
    if (widget.initialCpf != null && widget.initialCpf!.isNotEmpty) {
      _cpfController.text = CpfHelper.getCpfNumbers(widget.initialCpf!);
      _cpfMaskedController.text = CpfHelper.formatCpf(widget.initialCpf!);
      AppLogger.debug('CPF restaurado: ${widget.initialCpf!.substring(0, 3)}***');
    }
    
    // Limpar mensagem de erro quando o usuário começar a digitar
    _cpfMaskedController.addListener(() {
      if (_errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
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
    final limitedValue = cleanValue.length > 11 ? cleanValue.substring(0, 11) : cleanValue;
    final formatted = CpfHelper.formatCpf(limitedValue);
    if (_cpfMaskedController.text != formatted) {
      _cpfMaskedController.text = formatted;
      _cpfMaskedController.selection = TextSelection.collapsed(offset: formatted.length);
    }
    _cpfController.text = limitedValue;
  }

  Future<void> _handleNext() async {
    // Validar o formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validação adicional do CPF antes de prosseguir
    final cpf = CpfHelper.getCpfNumbers(_cpfController.text);

    if (!CpfHelper.isValidCpf(cpf)) {
      setState(() {
        _errorMessage = 'CPF inválido. Por favor, verifique o número digitado.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verificar se CPF existe no banco usando Firestore (busca por hash)
      AppLogger.info('🚀 Verificando CPF: ${cpf.substring(0, 3)}***');
      AppLogger.debug('Usando FirestoreService.checkCpf para buscar por cpfHash');

      // Usar FirestoreService que busca pelo hash corretamente
      final result = await FirestoreService.checkCpf(cpf);

      if (!mounted) return;

      final success = result['success'] as bool? ?? false;
      final exists = result['exists'] as bool? ?? false;

      if (success && exists) {
        // ============================================
        // CPF EXISTE: Fazer login automaticamente
        // ============================================
        AppLogger.info(
            '✅ CPF encontrado - Fazendo login automaticamente');

        // Verificar se authController está disponível
        if (widget.authController == null) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Erro: AuthController não disponível';
            });
          }
          return;
        }

        // Fazer login com OTP (já validado na tela anterior)
        final loginSuccess = await widget.authController!.loginWithOtpMock(cpf);

        if (!mounted) return;

        if (loginSuccess) {
          AppLogger.info(
              '✅ Login realizado com sucesso - redirecionando para MainTabScreen');
          
          // Navegar para Dashboard quando login bem-sucedido
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MainTabScreen(
                authController: widget.authController!,
                themeController: widget.themeController ?? ThemeController(),
              ),
            ),
            (route) => false, // Remove todas as rotas anteriores
          );
        } else {
          // Login falhou - mostrar erro
          setState(() {
            _errorMessage = widget.authController?.errorMessage ??
                'Erro ao fazer login. Tente novamente.';
          });
        }
      } else if (success && !exists) {
        // ============================================
        // CPF NÃO EXISTE: Fluxo de Cadastro
        // ============================================
        AppLogger.info('👤 CPF não encontrado - Redirecionando para cadastro');

        // Verificar se há cadastro abandonado
        final registrationProgress = await RegistrationService.getProgress(cpf);

        if (registrationProgress != null &&
            !registrationProgress.isComplete &&
            !registrationProgress.isStale) {
          if (!mounted) return;

          final shouldResume = await RegistrationNavigator.showResumeDialog(
            context,
            registrationProgress.currentStep,
          );

          if (!mounted) return;

          if (shouldResume) {
            RegistrationNavigator.navigateToStep(
              context: context,
              progress: registrationProgress,
              authController: widget.authController,
              themeController: widget.themeController,
            );
            return;
          } else {
            await RegistrationService.deleteProgress(cpf);
          }
        }

        // Novo cadastro
        if (mounted) {
          final normalizedPhone = _normalizeInitialPhone(widget.initialPhone);
          AppLogger.debug('Novo cadastro - initialPhone: ${widget.initialPhone}, normalizedPhone: $normalizedPhone');
          
          final nextScreen = normalizedPhone != null
              ? Step4EmailScreen(
                  authController: widget.authController,
                  themeController: widget.themeController,
                  cpf: cpf,
                  phone: normalizedPhone,
                )
              : Step2PhoneScreen(
                  authController: widget.authController,
                  themeController: widget.themeController,
                  cpf: cpf,
                );

          AppLogger.info('Navegando para: ${normalizedPhone != null ? "Step4EmailScreen" : "Step2PhoneScreen"}');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => nextScreen),
          );
        }
      } else {
        // Erro ao verificar CPF
        setState(() {
          _errorMessage = 'Erro ao verificar CPF. Tente novamente.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro de conexão. Verifique sua internet.';
        });
        AppLogger.error('Erro no _handleNext: $e');
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
        onBackPressed: () {
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
        },
      ),
      body: SafeArea(
        child: KeyboardDismissWrapper(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bottomInset = MediaQuery.of(context).viewInsets.bottom;
              const topPad = 40.0;
              const bottomPad = 48.0;
              return SingleChildScrollView(
                reverse: true,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: topPad,
                  bottom: bottomInset + bottomPad,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - topPad - bottomPad,
                  ),
                  child: Form(
                    key: _formKey,
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          const Center(
                            child: Text(
                              'Insira seu CPF',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          if (_errorMessage != null) ...[
                            _buildErrorMessage(),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _cpfMaskedController,
                            autofocus: widget.initialCpf == null || widget.initialCpf!.isEmpty,
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
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
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
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundColor),
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
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
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

  // _buildForm removido - formulário inline no build

  String? _normalizeInitialPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      AppLogger.debug('_normalizeInitialPhone: phone é null ou vazio');
      return null;
    }

    try {
      // Obter apenas os números (remove +, espaços, etc)
      final phoneNumbers = PhoneHelper.getPhoneNumbers(phone);
      AppLogger.debug('_normalizeInitialPhone: telefone original: $phone, números: $phoneNumbers');
      
      // Se o telefone tem código do país (55) e mais de 11 dígitos, remover o código do país
      // O Step4EmailScreen espera o telefone sem o código do país
      if (phoneNumbers.length > 11 && phoneNumbers.startsWith('55')) {
        final phoneWithoutCountryCode = phoneNumbers.substring(2);
        AppLogger.debug('_normalizeInitialPhone: removendo código do país, resultado: $phoneWithoutCountryCode');
        return phoneWithoutCountryCode;
      }
      
      // Se já está no formato correto (10 ou 11 dígitos), retornar como está
      if (phoneNumbers.length >= 10 && phoneNumbers.length <= 11) {
        AppLogger.debug('_normalizeInitialPhone: telefone já está no formato correto');
        return phoneNumbers;
      }
      
      AppLogger.warning('_normalizeInitialPhone: formato de telefone inválido: $phoneNumbers (${phoneNumbers.length} dígitos)');
      return null;
    } catch (e) {
      AppLogger.error('_normalizeInitialPhone: erro ao normalizar telefone', e);
      return null;
    }
  }
}
