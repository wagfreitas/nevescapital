import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/features/auth/presentation/controllers/registration_lifecycle_observer.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'step6_personal_data_2_screen.dart';

/// Formatter para data no formato DD/MM/YYYY
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length > 10) {
      return oldValue;
    }

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      formatted += text[i];
      if (i == 1 || i == 3) {
        formatted += '/';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Tela 5 do Cadastro: Informações Pessoais
class Step5PersonalData1Screen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;
  final String cpf;
  final String phone;
  final String email;

  const Step5PersonalData1Screen({
    super.key,
    this.authController,
    this.themeController,
    required this.cpf,
    required this.phone,
    required this.email,
  });

  @override
  State<Step5PersonalData1Screen> createState() =>
      _Step5PersonalData1ScreenState();
}

class _Step5PersonalData1ScreenState extends State<Step5PersonalData1Screen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final FocusNode _fullNameFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _selectedDate;
  late RegistrationLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();

    _lifecycleObserver = RegistrationLifecycleObserver(
      getCurrentProgress: () => RegistrationProgress(
        cpf: widget.cpf,
        currentStep: 'personal1',
        status: RegistrationStatus.inProgress,
        lastUpdated: DateTime.now(),
        phone: widget.phone,
        email: widget.email,
        fullName: _fullNameController.text.isNotEmpty
            ? _fullNameController.text.trim()
            : null,
        birthDate: _selectedDate,
        motherName: _motherNameController.text.isNotEmpty
            ? _motherNameController.text.trim()
            : null,
      ),
      shouldSaveProgress: () => ModalRoute.of(context)?.isCurrent ?? false,
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    // Abrir teclado automaticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fullNameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _lifecycleObserver.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _fullNameFocusNode.dispose();
    _fullNameController.dispose();
    _birthDateController.dispose();
    _motherNameController.dispose();
    super.dispose();
  }

  DateTime? _parseBirthDate(String text) {
    try {
      if (text.length != 10) return null;
      final parts = text.split('/');
      if (parts.length != 3) return null;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  bool _isValidAge(DateTime birthDate) {
    final now = DateTime.now();
    final age = now.year -
        birthDate.year -
        (now.month < birthDate.month ||
                (now.month == birthDate.month && now.day < birthDate.day)
            ? 1
            : 0);

    return age >= 18 && age <= 110;
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!mounted) return;

      // Salvar progresso LOCALMENTE antes de navegar
      AppLogger.debug(
          'Salvando progresso antes de navegar para Dados Pessoais 2');
      await _lifecycleObserver.saveNow(localOnly: true);

      // Navegar para próxima tela
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Step6PersonalData2Screen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: widget.cpf,
            phone: widget.phone,
            email: widget.email,
            fullName: _fullNameController.text.trim(),
            birthDate: _selectedDate!,
            motherName: _motherNameController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Informações Pessoais',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Precisamos de algumas informações para completar seu cadastro',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                // Nome Completo
                TextFormField(
                  controller: _fullNameController,
                  focusNode: _fullNameFocusNode,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nome Completo',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF22C55E), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.white70),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Digite seu nome completo';
                    }
                    if (value.trim().split(' ').length < 2) {
                      return 'Digite nome e sobrenome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Data de Nascimento
                TextFormField(
                  controller: _birthDateController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _DateInputFormatter(),
                  ],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Data de Nascimento',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF22C55E), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    prefixIcon:
                        const Icon(Icons.calendar_today, color: Colors.white70),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite sua data de nascimento';
                    }
                    if (value.length != 10) {
                      return 'Data incompleta';
                    }

                    final birthDate = _parseBirthDate(value);
                    if (birthDate == null) {
                      return 'Data inválida';
                    }

                    if (!_isValidAge(birthDate)) {
                      final now = DateTime.now();
                      final age = now.year - birthDate.year;
                      if (age < 18) {
                        return 'Você deve ter no mínimo 18 anos';
                      }
                      return 'Data de nascimento inválida';
                    }

                    setState(() {
                      _selectedDate = birthDate;
                    });

                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Nome da Mãe
                TextFormField(
                  controller: _motherNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nome da Mãe',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF22C55E), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.family_restroom,
                        color: Colors.white70),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Digite o nome da sua mãe';
                    }
                    if (value.trim().split(' ').length < 2) {
                      return 'Digite nome e sobrenome';
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
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF122118)),
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
