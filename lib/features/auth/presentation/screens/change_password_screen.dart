import 'package:flutter/material.dart';
import 'package:neves_capital/shared/services/database_service.dart';
import 'package:neves_capital/shared/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class ChangePasswordScreen extends StatefulWidget {
  final String resetToken;
  final String cpf;

  const ChangePasswordScreen({
    super.key,
    required this.resetToken,
    required this.cpf,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // 1. Validar senha antiga usando Firebase Auth
      // Buscar email do usuário por CPF
      final userData = await DatabaseService.getUserByCpf(widget.cpf);
      if (userData == null || userData['email'] == null) {
        throw Exception('Usuário não encontrado');
      }

      final email = userData['email'] as String;

      // Tentar fazer login com senha antiga para validar
      try {
        await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: _oldPasswordController.text.trim(),
        );
      } catch (e) {
        throw Exception('Senha atual incorreta');
      }

      // 2. Se a senha antiga está correta, atualizar senha
      final success = await DatabaseService.changePasswordWithOtp(
        token: widget.resetToken,
        oldPassword: _oldPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _successMessage = 'Senha alterada com sucesso!';
          _isLoading = false;
        });

        // Navegar para tela de login após 2 segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('FirebaseAuthException: ', '');
      });
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 40.0),
                _buildTitle(),
                const SizedBox(height: 24.0),
                if (_errorMessage != null) ...[
                  _buildErrorMessage(),
                  const SizedBox(height: 16.0),
                ],
                if (_successMessage != null) ...[
                  _buildSuccessMessage(),
                  const SizedBox(height: 16.0),
                ],
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/icons/logo_ios_filled.png',
      width: 80,
      height: 80,
      fit: BoxFit.contain,
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Alterar Senha',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: Colors.red, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF22C55E), width: 1),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 24),
          SizedBox(width: 8),
          Text(
            'Senha alterada com sucesso!',
            style: TextStyle(
              color: Color(0xFF22C55E),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildPasswordField(
            controller: _oldPasswordController,
            label: 'Senha Atual',
            obscureText: _obscureOldPassword,
            onToggleVisibility: () {
              setState(() {
                _obscureOldPassword = !_obscureOldPassword;
              });
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Digite sua senha atual';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          _buildPasswordField(
            controller: _newPasswordController,
            label: 'Nova Senha',
            obscureText: _obscureNewPassword,
            onToggleVisibility: () {
              setState(() {
                _obscureNewPassword = !_obscureNewPassword;
              });
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Digite a nova senha';
              }
              if (value.length < 6) {
                return 'Senha deve ter pelo menos 6 caracteres';
              }
              if (value == _oldPasswordController.text.trim()) {
                return 'A nova senha deve ser diferente da atual';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirmar Nova Senha',
            obscureText: _obscureConfirmPassword,
            onToggleVisibility: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Confirme a nova senha';
              }
              if (value != _newPasswordController.text.trim()) {
                return 'As senhas não coincidem';
              }
              return null;
            },
          ),
          const SizedBox(height: 32.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: const Color(0xFF122118),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
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
                      'Alterar Senha',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.white.withOpacity(0.7),
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      validator: validator,
    );
  }
}

