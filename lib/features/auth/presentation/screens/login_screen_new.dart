import 'package:flutter/material.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller_real.dart';
import 'package:neves_capital/shared/components/cpf_input_field.dart';
import 'package:neves_capital/shared/helpers/cpf_helper.dart';
import 'package:neves_capital/shared/widgets/login_progress_widget.dart';
import 'package:neves_capital/features/home/presentation/screens/dashboard_screen.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';

class LoginScreenNew extends StatefulWidget {
  final AuthController authController;
  final ThemeController? themeController;
  
  const LoginScreenNew({
    super.key,
    required this.authController,
    this.themeController,
  });

  @override
  State<LoginScreenNew> createState() => _LoginScreenNewState();
}

class _LoginScreenNewState extends State<LoginScreenNew> {
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122118), // bg-[#122118]
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // px-4
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(),
              const SizedBox(height: 40.0), // mb-10
              _buildWelcomeText(),
              const SizedBox(height: 24.0), // mt-6
              _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/icons/ios_120.png',
      width: 100,
      height: 100,
      fit: BoxFit.contain,
    );
  }

  Widget _buildWelcomeText() {
    return Text(
      'Entre na sua conta:',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      textAlign: TextAlign.left,
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildCpfField(),
          const SizedBox(height: 24.0), // space-y-6
          _buildPasswordField(),
          const SizedBox(height: 16.0),
          _buildForgotPasswordLink(),
          const SizedBox(height: 24.0),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildCpfField() {
    return CpfInputField(
      controller: _cpfController,
      hintText: 'Digite seu CPF',
      onFocusLost: () {
        // Validação automática quando perde foco
      },
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Senha é obrigatória';
              }
              if (value.length < 6) {
                return 'Senha deve ter pelo menos 6 caracteres';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Digite sua Senha',
              hintStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF9CA3AF),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.white),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.white),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Color(0xFF22C55E),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // TODO: Implementar recuperação de senha
        },
        child: const Text(
          'Esqueceu sua senha ?',
          style: TextStyle(
            color: Color(0xFF4ADE80), // text-[var(--primary-400)]
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E), // bg-[var(--primary-500)]
              foregroundColor: const Color(0xFF122118), // text-[#122118]
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25), // rounded-full
              ),
              padding: const EdgeInsets.symmetric(vertical: 14), // py-3.5
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
                    'Entrar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        
        // Widget de progresso granular
        if (_isLoading) ...[
          const SizedBox(height: 16),
          LoginProgressWidget(
            progress: widget.authController.loginProgress,
            errorMessage: widget.authController.errorMessage,
          ),
        ],
      ],
    );
  }



  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Login com CPF e senha
      final success = await widget.authController.loginWithCpf(
        cpf: CpfHelper.getCpfNumbers(_cpfController.text),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        // Login bem-sucedido - navegar diretamente para Dashboard
        print('✅ Login realizado - navegando para Dashboard');
        if (mounted) {
          // Navegar para Dashboard limpando toda a pilha
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                authController: widget.authController,
                themeController: widget.themeController ?? ThemeController(),
              ),
            ),
            (route) => false,
          );
        }
      } else {
        // Login falhou - mostrar mensagem de erro
        final errorMessage = widget.authController.errorMessage ?? 'Erro no login';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no login: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}