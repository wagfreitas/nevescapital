import 'dart:async';
import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/features/auth/presentation/controllers/registration_lifecycle_observer.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'package:neves_capital/features/auth/presentation/helpers/registration_navigation_helper.dart';
import 'step4_email_screen.dart';
import 'step6_address_screen.dart';

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
      if (i == 2 || i == 4) {
        formatted += '/';
      }
      formatted += digitsOnly[i];
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
  final String? initialFullName;
  final DateTime? initialBirthDate;
  final String? initialMotherName;

  const Step5PersonalData1Screen({
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
  Timer? _saveDebounceTimer;

  @override
  void initState() {
    super.initState();

    // Restaurar valores salvos se existirem
    if (widget.initialFullName != null && widget.initialFullName!.isNotEmpty) {
      _fullNameController.text = widget.initialFullName!;
    }
    
    if (widget.initialBirthDate != null) {
      _selectedDate = widget.initialBirthDate;
      // Formatar data para DD/MM/AAAA
      final day = widget.initialBirthDate!.day.toString().padLeft(2, '0');
      final month = widget.initialBirthDate!.month.toString().padLeft(2, '0');
      final year = widget.initialBirthDate!.year.toString();
      _birthDateController.text = '$day/$month/$year';
    }
    
    if (widget.initialMotherName != null && widget.initialMotherName!.isNotEmpty) {
      _motherNameController.text = widget.initialMotherName!;
    }

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

    // Salvar progresso imediatamente se houver valores restaurados
    if (widget.initialFullName != null || widget.initialBirthDate != null || widget.initialMotherName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lifecycleObserver.saveNow(localOnly: false);
      });
    }

    // Adicionar listeners para salvar automaticamente quando o usuário digitar
    _fullNameController.addListener(_onFieldChanged);
    _birthDateController.addListener(_onFieldChanged);
    _motherNameController.addListener(_onFieldChanged);

    // Não abrir teclado automaticamente
  }

  void _onFieldChanged() {
    // Cancelar timer anterior se existir
    _saveDebounceTimer?.cancel();
    
    // Agendar salvamento após 2 segundos de inatividade (debounce)
    _saveDebounceTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _lifecycleObserver.saveNow(localOnly: true);
      }
    });
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _fullNameController.removeListener(_onFieldChanged);
    _birthDateController.removeListener(_onFieldChanged);
    _motherNameController.removeListener(_onFieldChanged);
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

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!mounted) return;

      // Criar progresso atual com dados preenchidos
      final currentProgress = RegistrationProgress(
        cpf: widget.cpf,
        currentStep: 'address',
        status: RegistrationStatus.inProgress,
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

      // Salvar e buscar progresso completo (garante que dados de outras telas sejam preservados)
      final completeProgress = await RegistrationNavigationHelper.saveAndGetCompleteProgress(
        currentProgress: currentProgress,
      );

      if (!mounted) return;

      // Navegar para próxima tela (Endereço)
      // Usar dados do progresso completo para restaurar tudo que já foi preenchido
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Step6AddressScreen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: widget.cpf,
            phone: widget.phone,
            email: widget.email,
            fullName: completeProgress?.fullName ?? _fullNameController.text.trim(),
            birthDate: completeProgress?.birthDate ?? _selectedDate!,
            motherName: completeProgress?.motherName ?? _motherNameController.text.trim(),
            initialCep: completeProgress?.cep,
            initialStreet: completeProgress?.street,
            initialNumber: completeProgress?.number,
            initialComplement: completeProgress?.complement,
            initialNeighborhood: completeProgress?.neighborhood,
            initialCity: completeProgress?.city,
            initialState: completeProgress?.state,
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
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        onBackPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Step4EmailScreen(
                  authController: widget.authController,
                  themeController: widget.themeController,
                  cpf: widget.cpf,
                  phone: widget.phone,
                  initialEmail: widget.email,
                ),
              ),
            );
          }
        },
      ),
      body: SafeArea(
        child: KeyboardDismissWrapper(
          child: LayoutBuilder(
            builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SingleChildScrollView(
              reverse: true,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                bottom: bottomInset + 32.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: IntrinsicHeight(
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
                              // Primeiro traço (ativo) - primeira de 3
                              Container(
                                width: 32,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Segundo traço (inativo)
                              Container(
                                width: 32,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Terceiro traço (inativo)
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
                        const SizedBox(height: 40),
                        // Nome Completo
                        TextFormField(
                          controller: _fullNameController,
                          focusNode: _fullNameFocusNode,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Nome Completo',
                            labelStyle: const TextStyle(color: Colors.white70),
                            hintText: 'Igual ao Doc. de Identidade',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
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
                              borderSide:
                                  BorderSide(color: AppTheme.primaryColor, width: 2),
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
                          maxLength: 10,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) {
                            // Atualizar _selectedDate quando o usuário digita
                            if (value.length == 10) {
                              final parsed = _parseBirthDate(value);
                              if (parsed != null && _isValidAge(parsed)) {
                                setState(() {
                                  _selectedDate = parsed;
                                });
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
                              borderSide:
                                  BorderSide(color: AppTheme.primaryColor, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            prefixIcon:
                                const Icon(Icons.calendar_today, color: Colors.white70),
                            counterText: '', // Ocultar contador
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite sua data de nascimento';
                            }
                            if (value.length != 10) {
                              return 'Use o formato DD/MM/AAAA';
                            }

                            final birthDate = _parseBirthDate(value);
                            if (birthDate == null) {
                              return 'Data inválida';
                            }

                            if (!_isValidAge(birthDate)) {
                              return 'Data de nascimento inválida para maiores de 18 anos';
                            }

                            _selectedDate = birthDate;
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
                            hintText: 'Igual ao Doc. de Identidade',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
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
                              borderSide:
                                  BorderSide(color: AppTheme.primaryColor, width: 2),
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
            );
          },
          ),
        ),
      ),
    );
  }
}
