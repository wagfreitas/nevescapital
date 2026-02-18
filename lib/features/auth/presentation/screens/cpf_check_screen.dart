import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/data/services/auth_api_service.dart';
import 'package:neves_capital/shared/helpers/cpf_helper.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';

/// Tela de Verificação de CPF (Segundo Fator)
/// Pede o CPF COMPLETO (11 dígitos) para confirmar identidade e determinar o fluxo
class CpfCheckScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;

  const CpfCheckScreen({
    super.key,
    this.authController,
    this.themeController,
  });

  @override
  State<CpfCheckScreen> createState() => _CpfCheckScreenState();
}

class _CpfCheckScreenState extends State<CpfCheckScreen> {
  final TextEditingController _cpfController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  int _attemptCount = 0;
  static const int _maxAttempts = 5;
  DateTime? _blockedUntil;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _token = args?['token'] as String?;

      if (_token == null) {
        setState(() {
          _errorMessage = 'Sessão inválida. Reinicie o login.';
        });
      }
    });
  }

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  bool _isBlocked() {
    if (_blockedUntil == null) return false;
    if (DateTime.now().isBefore(_blockedUntil!)) {
      return true;
    }
    // Desbloqueou
    _blockedUntil = null;
    _attemptCount = 0;
    return false;
  }

  String _getRemainingBlockTime() {
    if (_blockedUntil == null) return '';
    final remaining = _blockedUntil!.difference(DateTime.now());
    if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes} minutos';
    }
    return '${remaining.inSeconds} segundos';
  }

  Future<void> _handleCompleteLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_token == null) return;

    // Verificar se está bloqueado
    if (_isBlocked()) {
      setState(() {
        _errorMessage =
            'Muitas tentativas. Aguarde ${_getRemainingBlockTime()}.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cpfFull = _cpfController.text.trim();

      AppLogger.info('🔐 Verificando CPF completo...');

      // Incrementar contador de tentativas
      _attemptCount++;

      final result = await AuthApiService.checkUserByCpf(_token!, cpfFull);

      if (!mounted) return;

      final success = result['success'] as bool? ?? false;
      final status = result['status'] as String?;

      if (success) {
        // Resetar contador em caso de sucesso
        _attemptCount = 0;

        switch (status) {
          case 'LOGIN_SUCCESS':
            // Caso A: CPF encontrado + Telefone correspondente
            final token = result['token'] as String;
            AppLogger.info('✅ Login direto - CPF e telefone correspondem!');
            await _loginWithToken(token);
            break;

          case 'PHONE_CHANGE_DETECTED':
            // Caso B: CPF encontrado + Telefone diferente
            AppLogger.info('⚠️ Novo telefone detectado');
            _handlePhoneChange(result);
            break;

          case 'PRE_REGISTRATION_FOUND':
            // Caso C: Pré-cadastro encontrado
            AppLogger.info('📝 Retomando cadastro pendente');
            _handlePreRegistration(result);
            break;

          case 'NEW_USER':
            // Caso D: CPF não encontrado - novo usuário
            AppLogger.info('🆕 Novo usuário - iniciando cadastro');
            _handleNewRegistration();
            break;

          default:
            setState(() {
              _errorMessage = 'Status desconhecido';
            });
        }
      } else {
        // Falha na verificação
        if (_attemptCount >= _maxAttempts) {
          _blockedUntil = DateTime.now().add(const Duration(minutes: 30));
          setState(() {
            _errorMessage =
                'Muitas tentativas falhas. Conta bloqueada por 30 minutos.';
          });
        } else {
          final remainingAttempts = _maxAttempts - _attemptCount;
          setState(() {
            _errorMessage =
                'Dados não conferem. $remainingAttempts tentativas restantes.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro de conexão. Tente novamente.';
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

  Future<void> _loginWithToken(String token) async {
    if (widget.authController != null) {
      final loginSuccess =
          await widget.authController!.loginWithCustomToken(token);

      if (!mounted) return;

      if (loginSuccess) {
        // Login completo! Ir para Dashboard
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/dashboard', (route) => false);
      } else {
        setState(() {
          _errorMessage =
              widget.authController!.errorMessage ?? 'Erro ao autenticar';
        });
      }
    }
  }

  void _handlePhoneChange(Map<String, dynamic> result) {
    // TODO: Implementar fluxo de validação adicional para troca de telefone
    // Por enquanto, mostrar alerta
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo telefone detectado'),
        content: const Text(
            'Por segurança, precisamos de informações adicionais para confirmar sua identidade.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handlePreRegistration(Map<String, dynamic> result) {
    final currentStep = result['currentStep'] as String?;
    // TODO: Navegar para a tela correta do cadastro
    Navigator.pushReplacementNamed(context, '/registration/$currentStep');
  }

  void _handleNewRegistration() {
    // Ir para início do cadastro
    Navigator.pushReplacementNamed(context, '/registration/start');
  }

  String _formatCpfInput(String value) {
    return CpfHelper.formatCpf(value);
  }

  bool _isValidCpf(String cpf) {
    return CpfHelper.isValidCpf(cpf);
  }

  Widget _buildTestButton(String label, String cpf, Color color) {
    return ElevatedButton(
      onPressed: () {
        _cpfController.text = cpf;
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(),
      body: SafeArea(
        child: KeyboardDismissWrapper(
          child: LayoutBuilder(
            builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SingleChildScrollView(
              reverse: true,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 40.0,
                bottom: bottomInset + 32.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Confirme sua identidade',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Digite seu CPF completo para continuar',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // 🎯 BOTÕES DE TESTE RÁPIDO (MODO DEBUG)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTestButton('A: Login OK', '123.456.789-01', Colors.green),
                        _buildTestButton('B: Troca Tel', '987.654.321-00', Colors.orange),
                        _buildTestButton('C: Pré-Cadastro', '111.222.333-44', Colors.blue),
                        _buildTestButton('D: Novo User', '555.666.777-88', Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 24),
                TextFormField(
                  controller: _cpfController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  keyboardAppearance: Brightness.dark, // Teclado escuro para uniformidade
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    // Fechar teclado quando usuário pressionar "OK" ou "Done"
                    FocusScope.of(context).unfocus();
                    // Opcional: validar e submeter automaticamente se CPF completo
                    if (_cpfController.text.length == 14) {
                      _handleCompleteLogin();
                    }
                  },
                  enabled: !_isBlocked(),
                  maxLength: 14, // 11 dígitos + 3 caracteres de formatação
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    // Auto-formatar enquanto digita
                    final formatted = _formatCpfInput(value);
                    if (formatted != value) {
                      _cpfController.value = TextEditingValue(
                        text: formatted,
                        selection:
                            TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: '000.000.000-00',
                    hintStyle: TextStyle(
                      fontSize: 20,
                      color: Colors.white.withValues(alpha: 0.3),
                      letterSpacing: 2,
                    ),
                    counterText: '',
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
                      borderSide:
                          BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite seu CPF';
                    }
                    final cleanCpf = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (cleanCpf.length != 11) {
                      return 'CPF deve ter 11 dígitos';
                    }
                    if (!_isValidCpf(cleanCpf)) {
                      return 'CPF inválido';
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
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCompleteLogin,
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
                            'Confirmar',
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
            );
          },
        ),
        ),
      ),
    );
  }
}
