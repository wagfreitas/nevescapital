import 'package:flutter/material.dart';
import 'package:neves_capital/shared/components/cpf_input_field.dart';
import 'package:neves_capital/shared/helpers/cpf_helper.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'step2_phone_screen.dart';

/// Tela 1: Insira seu CPF
class Step1CpfScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;

  const Step1CpfScreen({
    super.key,
    this.authController,
    this.themeController,
  });

  @override
  State<Step1CpfScreen> createState() => _Step1CpfScreenState();
}

class _Step1CpfScreenState extends State<Step1CpfScreen> {
  final TextEditingController _cpfController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Receber CPF da tela anterior (se vier da tela inicial)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final cpf = args?['cpf'] as String?;
      if (cpf != null && cpf.isNotEmpty) {
        // Pré-preencher CPF se vier da tela inicial
        _cpfController.text = CpfHelper.formatCpf(cpf);
      }
    });
  }

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cpf = CpfHelper.getCpfNumbers(_cpfController.text);
      
      // Verificar se CPF já está cadastrado no Firestore (verificação de segurança)
      final result = await FirestoreService.checkCpf(cpf);
      
      if (!mounted) return;

      final exists = result['exists'] as bool? ?? false;

      if (exists) {
        // CPF já cadastrado - redirecionar para login
        setState(() {
          _errorMessage = 'CPF já cadastrado. Use a opção de login.';
        });
        // Opcional: Navegar para tela de login após 2 segundos
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else {
        // CPF não existe - continuar para próxima tela do cadastro (telefone)
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Step2PhoneScreen(
                authController: widget.authController,
                themeController: widget.themeController,
                cpf: cpf,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao verificar CPF. Verifique sua conexão e tente novamente.';
        });
        AppLogger.error('Erro ao verificar CPF: $e');
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
                  'Insira seu CPF',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Precisamos do seu CPF para verificar se você já é nosso cliente',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                CpfInputField(
                  controller: _cpfController,
                  hintText: 'XXX.XXX.XXX-XX',
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
                    onPressed: _isLoading ? null : _handleNext,
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
                            'Avançar',
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




