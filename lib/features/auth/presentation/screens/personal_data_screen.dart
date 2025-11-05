import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/cep_input_field.dart';
import 'package:neves_capital/shared/helpers/cep_helper.dart';
import 'package:neves_capital/shared/services/cep_service.dart';
import 'package:neves_capital/shared/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';

class PersonalDataScreen extends StatefulWidget {
  final Map<String, String> loginData;
  final bool isEditMode;
  final String? userId;

  const PersonalDataScreen({
    super.key,
    required this.loginData,
    this.isEditMode = false,
    this.userId,
  });

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _complementController = TextEditingController();
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _authController.initialize();
    
    // Se for modo de edição, pré-preencher campos com dados existentes
    if (widget.isEditMode) {
      _cepController.text = widget.loginData['cep'] ?? '';
      _streetController.text = widget.loginData['street'] ?? '';
      _neighborhoodController.text = widget.loginData['neighborhood'] ?? '';
      _cityController.text = widget.loginData['city'] ?? '';
      _stateController.text = widget.loginData['state'] ?? '';
      _numberController.text = widget.loginData['number'] ?? '';
      _complementController.text = widget.loginData['complement'] ?? '';
    }
  }

  @override
  void dispose() {
    _cepController.dispose();
    _streetController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _authController.dispose();
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
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        foregroundColor: AppTheme.lightTheme.colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12.0),
                Text(
                  'Seu Endereço',
                  style: AppTheme.lightTheme.textTheme.headlineLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Preencha seu endereço para completar o cadastro',
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32.0),
                
                // Indicador de progresso
                _buildProgressIndicator(step: 2, totalSteps: 2),
                const SizedBox(height: 24.0),
                
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
                const SizedBox(height: 12.0),
                
                // Logradouro
                _buildInputField(
                  controller: _streetController,
                  hintText: 'Logradouro',
                  icon: Icons.location_on,
                  enabled: widget.isEditMode, // Editável no modo edição
                ),
                const SizedBox(height: 12.0),
                
                // Bairro e Cidade
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _neighborhoodController,
                        hintText: 'Bairro',
                        icon: Icons.location_city,
                        enabled: widget.isEditMode, // Editável no modo edição
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: _buildInputField(
                        controller: _cityController,
                        hintText: 'Cidade',
                        icon: Icons.location_city,
                        enabled: widget.isEditMode, // Editável no modo edição
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                
                // Estado
                _buildInputField(
                  controller: _stateController,
                  hintText: 'Estado',
                  icon: Icons.map,
                  enabled: widget.isEditMode, // Editável no modo edição
                ),
                const SizedBox(height: 12.0),
                
                // Número e Complemento
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildInputField(
                        controller: _numberController,
                        hintText: 'Número',
                        icon: Icons.numbers,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Número é obrigatório';
                          }
                          return null;
                        },
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
      validator: validator,
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
          : Text(widget.isEditMode ? 'Salvar Alterações' : 'Finalizar Cadastro'),
    );
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isEditMode) {
        // Modo de edição - apenas atualizar endereço
        final cep = CepHelper.getCepNumbers(_cepController.text);
        final street = _streetController.text.trim();
        final neighborhood = _neighborhoodController.text.trim();
        final city = _cityController.text.trim();
        final state = _stateController.text.trim();
        final number = _numberController.text.trim();
        final complement = _complementController.text.trim();

        // Atualizar apenas endereço no PostgreSQL
        if (widget.userId == null || widget.userId!.isEmpty) {
          throw Exception('ID do usuário não encontrado');
        }

        String postgresUserId = widget.userId!;
        
        // Verificar se é Firebase UID ou PostgreSQL UUID
        final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(widget.userId!);
        
        if (!isUuid) {
          // Se não é UUID, precisa buscar o ID do PostgreSQL primeiro
          print('⚠️ Firebase UID detectado no modo edição, buscando ID do PostgreSQL...');
          // Buscar via CPF conhecido (temporário até ter endpoint por Firebase UID)
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser?.email == 'wagfreitas@hotmail.com') {
            final userData = await DatabaseService.getUserByCpf('227.439.101-78');
            if (userData != null && userData['id'] != null) {
              postgresUserId = userData['id'] as String;
            } else {
              throw Exception('Não foi possível encontrar o ID do usuário no banco de dados.');
            }
          } else {
            throw Exception('Não foi possível encontrar o ID do usuário. Endpoint por Firebase UID ainda não está disponível.');
          }
        }

        final success = await DatabaseService.updateUser(
          userId: postgresUserId,
          cep: cep,
          address: street,
          neighborhood: neighborhood,
          city: city,
          state: state,
          number: number,
          complement: complement,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Endereço atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );

          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.of(context).pop(true); // Retornar true indica sucesso
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao atualizar endereço'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Modo cadastro - registro completo
        final email = widget.loginData['email']!;
        final password = widget.loginData['password']!;
        final fullName = widget.loginData['fullName']!;
        final cpf = widget.loginData['cpf']!;
        final phone = widget.loginData['phone']!;
        final cep = CepHelper.getCepNumbers(_cepController.text);
        final street = _streetController.text.trim();
        final neighborhood = _neighborhoodController.text.trim();
        final city = _cityController.text.trim();
        final state = _stateController.text.trim();
        final number = _numberController.text.trim();
        final complement = _complementController.text.trim();

        // Registrar usuário no Firebase + PostgreSQL
        final success = await _authController.register(
          email: email,
          password: password,
          fullName: fullName,
          cpf: cpf,
          phone: phone,
          cep: cep,
          address: street,
          neighborhood: neighborhood,
          city: city,
          state: state,
          number: number,
          complement: complement,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cadastro realizado com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_authController.errorMessage ?? 'Erro no cadastro'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
