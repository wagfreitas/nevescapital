import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/features/auth/data/services/local_registration_storage.dart';
import 'package:neves_capital/features/auth/presentation/helpers/registration_progress_indicator.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'registration_email_screen.dart';
import 'registration_address_screen.dart';

/// Formatter para data no formato DD/MM/AAAA
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    var formatted = '';
    for (var i = 0; i < digitsOnly.length && i < 8; i++) {
      if (i == 2 || i == 4) formatted += '/';
      formatted += digitsOnly[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Cadastro - Dados Pessoais
/// Coleta nome completo, data de nascimento e nome da mae.
class RegistrationPersonalDataScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;
  final String cpf;
  final String phone;
  final String email;
  final String? initialFullName;
  final DateTime? initialBirthDate;
  final String? initialMotherName;

  const RegistrationPersonalDataScreen({
    super.key,
    this.authController,
    this.themeController,
    required this.cpf,
    required this.phone,
    required this.email,
    this.initialFullName,
    this.initialBirthDate,
    this.initialMotherName,
  });

  @override
  State<RegistrationPersonalDataScreen> createState() =>
      _RegistrationPersonalDataScreenState();
}

class _RegistrationPersonalDataScreenState
    extends State<RegistrationPersonalDataScreen> {
  final _fullNameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _selectedDate;
  Timer? _saveDebounceTimer;

  @override
  void initState() {
    super.initState();

    if (widget.initialFullName != null && widget.initialFullName!.isNotEmpty) {
      _fullNameController.text = widget.initialFullName!;
    }

    if (widget.initialBirthDate != null) {
      _selectedDate = widget.initialBirthDate;
      final d = widget.initialBirthDate!;
      _birthDateController.text =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }

    if (widget.initialMotherName != null && widget.initialMotherName!.isNotEmpty) {
      _motherNameController.text = widget.initialMotherName!;
    }

    // Auto-save debounced ao digitar
    _fullNameController.addListener(_scheduleSave);
    _birthDateController.addListener(_scheduleSave);
    _motherNameController.addListener(_scheduleSave);
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _fullNameController.removeListener(_scheduleSave);
    _birthDateController.removeListener(_scheduleSave);
    _motherNameController.removeListener(_scheduleSave);
    _fullNameController.dispose();
    _birthDateController.dispose();
    _motherNameController.dispose();
    super.dispose();
  }

  // =========================================================
  // PERSISTENCIA
  // =========================================================

  void _scheduleSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) _saveProgressLocally();
    });
  }

  Future<void> _saveProgressLocally() async {
    final existing = await LocalRegistrationStorage.getLocal();
    final progress = (existing ?? RegistrationProgress(
      cpf: widget.cpf,
      currentStep: 'personal1',
      status: RegistrationStatus.inProgress,
      lastUpdated: DateTime.now(),
    )).copyWith(
      currentStep: 'personal1',
      lastUpdated: DateTime.now(),
      phone: widget.phone,
      email: widget.email,
      fullName: _fullNameController.text.trim().isNotEmpty
          ? _fullNameController.text.trim()
          : null,
      birthDate: _selectedDate,
      motherName: _motherNameController.text.trim().isNotEmpty
          ? _motherNameController.text.trim()
          : null,
    );
    await LocalRegistrationStorage.saveLocal(progress);
  }

  // =========================================================
  // HELPERS
  // =========================================================

  DateTime? _parseBirthDate(String text) {
    try {
      if (text.length != 10) return null;
      final parts = text.split('/');
      if (parts.length != 3) return null;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }
      return date;
    } catch (_) {
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

  // =========================================================
  // NAVEGACAO
  // =========================================================

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Salvar progresso localmente com merge
      final existing = await LocalRegistrationStorage.getLocal();
      final savedProgress = (existing ?? RegistrationProgress(
        cpf: widget.cpf,
        currentStep: 'address',
        status: RegistrationStatus.inProgress,
        lastUpdated: DateTime.now(),
      )).copyWith(
        currentStep: 'address',
        lastUpdated: DateTime.now(),
        phone: widget.phone,
        email: widget.email,
        fullName: _fullNameController.text.trim(),
        birthDate: _selectedDate,
        motherName: _motherNameController.text.trim(),
      );
      await LocalRegistrationStorage.saveLocal(savedProgress);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationAddressScreen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: widget.cpf,
            phone: widget.phone,
            email: widget.email,
            fullName: savedProgress.fullName ?? _fullNameController.text.trim(),
            birthDate: savedProgress.birthDate ?? _selectedDate!,
            motherName: savedProgress.motherName ?? _motherNameController.text.trim(),
            initialCep: savedProgress.cep,
            initialStreet: savedProgress.street,
            initialNumber: savedProgress.number,
            initialComplement: savedProgress.complement,
            initialNeighborhood: savedProgress.neighborhood,
            initialCity: savedProgress.city,
            initialState: savedProgress.state,
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBack() async {
    await _saveProgressLocally();

    if (!mounted) return;

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationEmailScreen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: widget.cpf,
            phone: widget.phone,
            initialEmail: widget.email,
          ),
        ),
      );
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      filled: true,
      fillColor: AppTheme.inputEditableBackgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      prefixIcon: Icon(icon, color: Colors.white70),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text(
          'Dados Cadastrais',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: RegistrationProgressIndicator.preferredSize(1),
        onBackPressed: _handleBack,
      ),
      body: SafeArea(
        top: false,
        child: KeyboardDismissWrapper(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24.0,
              MediaQuery.of(context).padding.top + kToolbarHeight + 16 + 40,
              24.0,
              0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nome Completo
                  TextFormField(
                    controller: _fullNameController,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Nome Completo',
                      'Igual ao Doc. de Identidade',
                      Icons.person,
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
                    maxLength: 10,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      if (value.length == 10) {
                        final parsed = _parseBirthDate(value);
                        if (parsed != null && _isValidAge(parsed)) {
                          setState(() => _selectedDate = parsed);
                        }
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Data de Nascimento',
                      hintText: 'Ex: 25/12/1990',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintStyle:
                          TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: AppTheme.inputEditableBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryColor, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.red, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today,
                          color: Colors.white70),
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite sua data de nascimento';
                      }
                      if (value.length != 10) {
                        return 'Use o formato DD/MM/AAAA';
                      }
                      final birthDate = _parseBirthDate(value);
                      if (birthDate == null) return 'Data inválida';
                      if (!_isValidAge(birthDate)) {
                        return 'Data de nascimento inválida para maiores de 18 anos';
                      }
                      _selectedDate = birthDate;
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Nome da Mae
                  TextFormField(
                    controller: _motherNameController,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Nome da Mãe',
                      'Igual ao Doc. de Identidade',
                      Icons.family_restroom,
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
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.backgroundColor,
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
                                    AppTheme.backgroundColor),
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
