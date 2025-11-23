import 'package:flutter/material.dart';
import 'package:neves_capital/shared/components/cpf_input_field.dart';
import 'package:neves_capital/shared/helpers/cpf_helper.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'login_step3_otp_screen.dart';

/// Tela inicial: Insira seu CPF
/// Verifica se o usuário existe no Firestore e direciona para o fluxo correto
class LoginStep1CpfScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;

  const LoginStep1CpfScreen({
    super.key,
    this.authController,
    this.themeController,
  });

  @override
  State<LoginStep1CpfScreen> createState() => _LoginStep1CpfScreenState();
}

class _LoginStep1CpfScreenState extends State<LoginStep1CpfScreen> {
  final TextEditingController _cpfController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

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
      
      // Verificar se CPF já está cadastrado no Firestore
      final result = await FirestoreService.checkCpf(cpf);

      if (!mounted) return;

      // Verificar se a resposta tem sucesso
      final success = result['success'] as bool? ?? false;
      final message = result['message'] as String? ?? '';
      
      if (!success) {
        // Se não teve sucesso, mostrar mensagem
        setState(() {
          _errorMessage = message.isNotEmpty ? message : 'Erro ao verificar CPF';
        });
        return;
      }

      final exists = result['exists'] as bool? ?? false;
      AppLogger.debug('Resultado verificação CPF: exists=$exists');

      if (exists) {
        // CPF existe - buscar dados do usuário (incluindo telefone) e ir direto para OTP
        AppLogger.debug('Buscando dados do usuário para obter telefone');
        final userData = await FirestoreService.getUserByCpf(cpf);
        
        if (!mounted) return;
        
        if (userData == null) {
          setState(() {
            _errorMessage = 'Erro ao buscar dados do usuário. Tente novamente.';
          });
          return;
        }
        
        final phone = userData['phone'] as String?;
        
        if (phone == null || phone.isEmpty) {
          setState(() {
            _errorMessage = 'Telefone não cadastrado. Entre em contato com o suporte.';
          });
          return;
        }
        
        AppLogger.sensitive('Telefone encontrado', phone);
        AppLogger.debug('Enviando OTP automaticamente para o telefone cadastrado');
        
        // MOCK: Simular envio de OTP
        // Em produção, chamaria: DatabaseService.requestLoginOtp(cpf, phone)
        AppLogger.debug('MOCK: OTP enviado para telefone cadastrado');
        
        // Ir direto para tela de OTP (pulando tela de telefone)
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginStep3OtpScreen(
                authController: widget.authController,
                themeController: widget.themeController,
              ),
              settings: RouteSettings(arguments: {
                'cpf': cpf,
                'phone': phone, // Telefone obtido automaticamente
              }),
            ),
          );
        }
      } else {
        // CPF não cadastrado - mostrar mensagem e voltar para onboarding após 3 segundos
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'CPF não encontrado. Redirecionando...';
          });
          
          // Mostrar mensagem informativa
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CPF não encontrado. Você será redirecionado para o cadastro em 3 segundos.'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
          
          // Aguardar 3 segundos e voltar para onboarding
          await Future.delayed(const Duration(seconds: 3));
          
          if (mounted) {
            // Voltar para tela inicial (onboarding)
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Extrair mensagem da Exception (que já vem do backend quando há erro HTTP)
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        
        // Detectar erros específicos
        final errorLower = errorMsg.toLowerCase();
        if (errorLower.contains('permission-denied') ||
            errorLower.contains('unauthenticated')) {
          errorMsg = 'Erro de autenticação. Faça login novamente.';
        } else if (errorLower.contains('network') ||
            errorLower.contains('connection')) {
          errorMsg = 'Erro de conexão. Verifique sua internet e tente novamente.';
        } else if (errorMsg.isEmpty || errorMsg == 'Erro ao verificar CPF') {
          errorMsg = 'Erro ao verificar CPF. Tente novamente.';
        }
        
        setState(() {
          _errorMessage = errorMsg;
        });
        AppLogger.error('Erro ao verificar CPF: $e');
        AppLogger.debug('Mensagem exibida: $errorMsg');
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

