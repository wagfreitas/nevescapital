import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/data/services/auth_api_service.dart';

/// Tela de Verificação de CPF (Segundo Fator)
/// Pede os primeiros 5 dígitos do CPF para confirmar identidade
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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

  Future<void> _handleCompleteLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_token == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cpfPrefix = _cpfController.text.trim();
      
      AppLogger.info('🔐 Verificando prefixo do CPF...');
      
      final result = await AuthApiService.loginComplete(_token!, cpfPrefix);

      if (!mounted) return;

      final success = result['success'] as bool? ?? false;

      if (success) {
        final token = result['token'] as String;
        AppLogger.info('✅ CPF confirmado! Token recebido.');

        // Login no Firebase
        if (widget.authController != null) {
          final loginSuccess = await widget.authController!.loginWithCustomToken(token);
          
          if (!mounted) return;

          if (loginSuccess) {
            // Login completo!
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            setState(() {
              _errorMessage = widget.authController!.errorMessage ?? 'Erro ao autenticar';
            });
          }
        }
      } else {
        setState(() {
          _errorMessage = result['message'] as String? ?? 'CPF incorreto';
        });
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
                  'Confirme sua identidade',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Digite os PRIMEIROS 5 NÚMEROS do seu CPF para continuar.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _cpfController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 5,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '12345',
                    hintStyle: TextStyle(
                      fontSize: 32,
                      color: Colors.white.withValues(alpha: 0.3),
                      letterSpacing: 8,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite os 5 números';
                    }
                    if (value.length != 5) {
                      return 'São necessários 5 números';
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
                    onPressed: _isLoading ? null : _handleCompleteLogin,
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
                            'Confirmar',
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
