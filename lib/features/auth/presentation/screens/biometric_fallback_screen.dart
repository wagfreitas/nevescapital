import 'package:flutter/material.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/shared/components/cpf_input_field.dart';
import 'package:neves_capital/shared/helpers/cpf_helper.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/home/presentation/screens/dashboard_screen.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';

/// Tela de fallback quando biometria falha
/// Permite acesso via CPF + Nome da Mãe
class BiometricFallbackScreen extends StatefulWidget {
  final AuthController authController;
  final ThemeController? themeController;

  const BiometricFallbackScreen({
    super.key,
    required this.authController,
    this.themeController,
  });

  @override
  State<BiometricFallbackScreen> createState() => _BiometricFallbackScreenState();
}

class _BiometricFallbackScreenState extends State<BiometricFallbackScreen> {
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Limpar mensagem de erro quando o usuário começar a digitar
    _cpfController.addListener(() {
      if (_errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
    _motherNameController.addListener(() {
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
    _motherNameController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    // Validar o formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validação adicional do CPF
    final cpf = CpfHelper.getCpfNumbers(_cpfController.text);
    if (!CpfHelper.isValidCpf(cpf)) {
      setState(() {
        _errorMessage = 'CPF inválido. Por favor, verifique o número digitado.';
      });
      return;
    }

    // Validar nome da mãe
    final motherName = _motherNameController.text.trim();
    if (motherName.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, digite o nome da sua mãe.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      AppLogger.info('🔐 Verificando CPF + Nome da Mãe...');

      // Buscar usuário por CPF
      final userData = await FirestoreService.getUserByCpf(cpf);

      if (userData == null) {
        setState(() {
          _errorMessage = 'CPF não encontrado. Verifique o número digitado.';
          _isLoading = false;
        });
        return;
      }

      // Verificar nome da mãe (comparação case-insensitive)
      final storedMotherName = (userData['motherName'] as String? ?? '').trim();
      if (storedMotherName.isEmpty) {
        AppLogger.warning('Nome da mãe não cadastrado para este usuário');
        setState(() {
          _errorMessage = 'Nome da mãe não cadastrado. Entre em contato com o suporte.';
          _isLoading = false;
        });
        return;
      }

      // Comparar nomes (case-insensitive, normalizado)
      final normalizedStored = storedMotherName.toLowerCase().trim();
      final normalizedInput = motherName.toLowerCase().trim();

      if (normalizedStored != normalizedInput) {
        AppLogger.warning('Nome da mãe não confere');
        setState(() {
          _errorMessage = 'Nome da mãe não confere. Tente novamente.';
          _isLoading = false;
        });
        return;
      }

      // Validação bem-sucedida!
      AppLogger.info('✅ CPF + Nome da Mãe validados com sucesso');

      // Redirecionar para Dashboard
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              authController: widget.authController,
              themeController: widget.themeController ?? ThemeController(),
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Erro ao verificar CPF + Nome da Mãe', e);
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao verificar dados. Tente novamente.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Acesso Alternativo',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Digite seu CPF e nome da mãe para acessar',
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
                                    style: const TextStyle(color: Colors.red, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        CpfInputField(
                          controller: _cpfController,
                          labelText: 'CPF',
                          hintText: '000.000.000-00',
                          autofocus: true,
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
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _motherNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Nome da Mãe',
                            hintText: 'Digite o nome completo da sua mãe',
                            labelStyle: const TextStyle(color: Colors.white70),
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white30),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor, digite o nome da sua mãe';
                            }
                            if (value.trim().length < 3) {
                              return 'Nome deve ter pelo menos 3 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleVerify,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Verificar e Acessar',
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
}


