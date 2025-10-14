import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/cpf_input_field.dart';
import 'package:neves_capital/shared/components/smart_text_form_field.dart';
import 'package:neves_capital/shared/helpers/cpf_helper.dart';
import 'package:neves_capital/shared/helpers/email_helper.dart';
import 'package:neves_capital/shared/helpers/password_helper.dart';
import 'package:neves_capital/features/auth/presentation/screens/personal_data_screen.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller_real.dart';

class LoginDataScreen extends StatefulWidget {
  const LoginDataScreen({super.key});

  @override
  State<LoginDataScreen> createState() => _LoginDataScreenState();
}

class _LoginDataScreenState extends State<LoginDataScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // AuthController para autenticação real
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _authController.initialize();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        foregroundColor: AppTheme.lightTheme.colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12.0),
                Text(
                  'Criar Conta',
                  style: AppTheme.lightTheme.textTheme.headlineLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Preencha seus dados básicos para começar',
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32.0),
                
                // Indicador de progresso
                _buildProgressIndicator(step: 1, totalSteps: 2),
                const SizedBox(height: 24.0),
                
                // Nome Completo
                SmartTextFormField(
                  controller: _fullNameController,
                  hintText: 'Nome Completo',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nome completo é obrigatório';
                    }
                    if (value.length < 3) {
                      return 'Nome deve ter pelo menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12.0),
                
                // CPF
                CpfInputField(
                  controller: _cpfController,
                  hintText: 'Digite seu CPF',
                  validator: CpfHelper.validateCpf,
                  onFocusLost: () {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12.0),
                
                // Email
                SmartTextFormField(
                  controller: _emailController,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email,
                  validator: EmailHelper.validateEmail,
                ),
                const SizedBox(height: 12.0),
                
                // Senha
                SmartTextFormField(
                  controller: _passwordController,
                  hintText: 'Digite sua senha',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: PasswordHelper.validateStrongPassword,
                ),
                const SizedBox(height: 12.0),
                
                // Confirmar Senha
                SmartTextFormField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirme sua senha',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    final passwordError = PasswordHelper.validateStrongPassword(value);
                    if (passwordError != null) return passwordError;
                    
                    return PasswordHelper.validatePasswordMatch(
                      _passwordController.text,
                      value,
                    );
                  },
                ),
                const SizedBox(height: 24.0),
                
                // Tooltip com critérios de senha
                _buildPasswordTooltip(),
                const SizedBox(height: 32.0),
                
                _buildContinueButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator({required int step, required int totalSteps}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index < step;
        final isCurrent = index == step - 1;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: isCurrent ? 24.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: isActive 
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4.0),
          ),
        );
      }),
    );
  }

  Widget _buildPasswordTooltip() {
    return Row(
      children: [
        const Icon(
          Icons.info_outline,
          color: Colors.white70,
          size: 16,
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            'Sua senha deve ter pelo menos 8 caracteres, uma letra maiúscula, um número e um caractere especial',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleContinue,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Continuar'),
    );
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    // Apenas navegar para próxima tela com os dados
    // O registro acontecerá depois de coletar TODOS os dados
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalDataScreen(
          loginData: {
            'fullName': _fullNameController.text.trim(),
            'cpf': CpfHelper.getCpfNumbers(_cpfController.text),
            'email': EmailHelper.cleanEmail(_emailController.text),
            'password': _passwordController.text,
          },
        ),
      ),
    );
  }
}
