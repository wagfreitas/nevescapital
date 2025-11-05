import 'package:flutter/material.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/shared/components/cpf_input_field.dart';
import 'package:neves_capital/shared/helpers/cpf_helper.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final AuthController authController;

  const ForgotPasswordScreen({
    super.key,
    required this.authController,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _cpfController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122118), // bg-[#122118]
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // px-4
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 40.0), // mb-10
                _buildTitle(),
                const SizedBox(height: 24.0), // mt-6
                if (_emailSent) ...[
                  _buildSuccessMessage(),
                ] else ...[
                  _buildDescription(),
                  const SizedBox(height: 24.0),
                  _buildForm(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/icons/ios_120.png',
      width: 80,
      height: 80,
      fit: BoxFit.contain,
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Esqueceu sua senha?',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription() {
    return const Text(
      'Digite seu CPF para receber um email com instruções para redefinir sua senha.',
      style: TextStyle(
        fontSize: 14,
        color: Colors.white70,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF22C55E),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF22C55E),
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Email enviado!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF22C55E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Verifique sua caixa de entrada e siga as instruções para redefinir sua senha.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: const Color(0xFF122118),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
              elevation: 0,
            ),
            child: const Text(
              'Voltar ao Login',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
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
          _buildCpfField(),
          const SizedBox(height: 24.0),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildCpfField() {
    return CpfInputField(
      controller: _cpfController,
      hintText: 'Digite seu CPF',
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleResetPassword,
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
                'Enviar Email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cpf = CpfHelper.getCpfNumbers(_cpfController.text);
      final success = await widget.authController.resetPasswordByCpf(cpf);

      if (!mounted) return;

      if (success) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      } else {
        final errorMessage = widget.authController.errorMessage ?? 'Erro ao enviar email';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }
}



