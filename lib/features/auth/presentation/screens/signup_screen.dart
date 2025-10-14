import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/features/auth/presentation/screens/document_upload_screen.dart';
import 'package:neves_capital/shared/components/cpf_input_field.dart';
import 'package:neves_capital/shared/components/phone_input_field.dart';
import 'package:neves_capital/shared/components/cep_input_field.dart';
import 'package:neves_capital/shared/helpers/cpf_helper.dart';
import 'package:neves_capital/shared/helpers/phone_helper.dart';
import 'package:neves_capital/shared/helpers/cep_helper.dart';
import 'package:neves_capital/shared/helpers/password_helper.dart';
import 'package:neves_capital/shared/services/cep_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _complementController = TextEditingController();
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cepController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _streetController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    super.dispose();
  }

  Future<void> _searchCep() async {
    final cep = CepHelper.getCepNumbers(_cepController.text);
    
    if (cep.length != 8) return;
    
    try {
      final addressData = await CepService.getAddressByCep(cep);
      
      if (addressData != null && mounted) {
        setState(() {
          _streetController.text = addressData['street'] ?? '';
          _neighborhoodController.text = addressData['neighborhood'] ?? '';
          _cityController.text = addressData['city'] ?? '';
          _stateController.text = addressData['state'] ?? '';
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CEP não encontrado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar CEP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Criar Conta'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Criar Conta',
              style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            
            // Nome Completo
            _buildInputField(
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
            const SizedBox(height: 16.0),
            
            // CPF
            CpfInputField(
              controller: _cpfController,
              hintText: 'Digite seu CPF',
              validator: CpfHelper.validateCpf,
              onFocusLost: () {
                setState(() {});
              },
            ),
            const SizedBox(height: 16.0),
            
            // Email
            _buildInputField(
              controller: _emailController,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
              icon: Icons.email,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email é obrigatório';
                }
                if (!value.contains('@')) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            
            // Telefone
            PhoneInputField(
              controller: _phoneController,
              hintText: 'Digite seu telefone',
              validator: PhoneHelper.validatePhone,
              onFocusLost: () {
                setState(() {});
              },
            ),
            const SizedBox(height: 16.0),
            
            // CEP
            CepInputField(
              controller: _cepController,
              hintText: 'Digite seu CEP',
              validator: CepHelper.validateCep,
              onFocusLost: () {
                setState(() {});
                _searchCep(); // Busca endereço automaticamente
              },
            ),
            const SizedBox(height: 16.0),
            
            // Endereço (preenchido automaticamente pelo CEP)
            _buildInputField(
              controller: _streetController,
              hintText: 'Rua/Logradouro',
              icon: Icons.location_on,
              enabled: false, // Preenchido automaticamente
            ),
            const SizedBox(height: 16.0),
            
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _neighborhoodController,
                    hintText: 'Bairro',
                    icon: Icons.location_city,
                    enabled: false, // Preenchido automaticamente
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: _buildInputField(
                    controller: _cityController,
                    hintText: 'Cidade',
                    icon: Icons.location_city,
                    enabled: false, // Preenchido automaticamente
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildInputField(
                    controller: _numberController,
                    hintText: 'Número',
                    icon: Icons.numbers,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  flex: 3,
                  child: _buildInputField(
                    controller: _complementController,
                    hintText: 'Complemento',
                    icon: Icons.home,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            
            // Senha
            _buildPasswordField(
              controller: _passwordController,
              hintText: 'Digite sua senha',
              obscureText: _obscurePassword,
              onToggleVisibility: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              validator: PasswordHelper.validateStrongPassword,
            ),
            const SizedBox(height: 16.0),
            
            // Confirmar Senha
            _buildPasswordField(
              controller: _confirmPasswordController,
              hintText: 'Confirme sua senha',
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              validator: (value) {
                final passwordError = PasswordHelper.validateStrongPassword(value);
                if (passwordError != null) return passwordError;
                
                return PasswordHelper.validatePasswordMatch(
                  _passwordController.text,
                  value,
                );
              },
            ),
            const SizedBox(height: 16.0),
            
            // Critérios de senha forte
            _buildPasswordCriteria(),
            const SizedBox(height: 32.0),
            
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      style: TextStyle(
        color: enabled ? Colors.white : Colors.grey,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: enabled ? Colors.white70 : Colors.grey,
        ),
        prefixIcon: icon != null ? Icon(
          icon,
          color: enabled ? Colors.white : Colors.grey,
        ) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: enabled ? Colors.white : Colors.grey,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: enabled ? Colors.white : Colors.grey,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(
            color: Color(0xFF22C55E),
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(
            color: Colors.grey,
          ),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: Colors.white,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
            size: 20,
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.white),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.white),
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
    );
  }

  Widget _buildPasswordCriteria() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Critérios para senha forte:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8.0),
          ...PasswordHelper.getPasswordCriteria().map((criteria) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 8.0),
                Text(
                  criteria,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
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

    setState(() {
      _isLoading = true;
    });

    try {
      // Simular validação de CPF e busca de CEP
      await Future.delayed(const Duration(seconds: 1));

      // Coletar dados do formulário (apenas números para CPF, telefone e CEP)
      final userData = <String, String>{
        'fullName': _fullNameController.text.trim(),
        'cpf': CpfHelper.getCpfNumbers(_cpfController.text),
        'email': _emailController.text.trim(),
        'phone': PhoneHelper.getPhoneNumbers(_phoneController.text),
        'cep': CepHelper.getCepNumbers(_cepController.text),
        'password': _passwordController.text,
        'street': _streetController.text.trim(),
        'neighborhood': _neighborhoodController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'number': _numberController.text.trim(),
        'complement': _complementController.text.trim(),
      };

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentUploadScreen(userData: userData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar dados: $e'),
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