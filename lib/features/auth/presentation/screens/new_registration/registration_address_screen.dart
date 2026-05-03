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
import 'package:neves_capital/shared/helpers/cep_helper.dart';
import 'package:neves_capital/shared/services/cep_service.dart';
import 'registration_personal_data_screen.dart';
import 'registration_additional_info_screen.dart';

/// Cadastro - Endereco
/// Coleta endereco com auto-preenchimento por CEP.
class RegistrationAddressScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;
  final String cpf;
  final String phone;
  final String email;
  final String fullName;
  final DateTime birthDate;
  final String motherName;
  final String? initialCep;
  final String? initialStreet;
  final String? initialNumber;
  final String? initialComplement;
  final String? initialNeighborhood;
  final String? initialCity;
  final String? initialState;

  const RegistrationAddressScreen({
    super.key,
    this.authController,
    this.themeController,
    required this.cpf,
    required this.phone,
    required this.email,
    required this.fullName,
    required this.birthDate,
    required this.motherName,
    this.initialCep,
    this.initialStreet,
    this.initialNumber,
    this.initialComplement,
    this.initialNeighborhood,
    this.initialCity,
    this.initialState,
  });

  @override
  State<RegistrationAddressScreen> createState() =>
      _RegistrationAddressScreenState();
}

class _RegistrationAddressScreenState extends State<RegistrationAddressScreen> {
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _cepFocusNode = FocusNode();
  final _numberFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSearchingCep = false;
  String? _errorMessage;
  Timer? _saveDebounceTimer;
  Timer? _cepSearchTimer;
  String _lastSearchedCep = '';

  @override
  void initState() {
    super.initState();
    _restoreInitialValues();
    _setupListeners();
  }

  void _restoreInitialValues() {
    if (widget.initialCep != null && widget.initialCep!.isNotEmpty) {
      _cepController.text = CepHelper.formatCep(widget.initialCep!);
      _lastSearchedCep = CepHelper.getCepNumbers(widget.initialCep!);
    }
    if (widget.initialStreet != null) _streetController.text = widget.initialStreet!;
    if (widget.initialNumber != null) _numberController.text = widget.initialNumber!;
    if (widget.initialComplement != null) _complementController.text = widget.initialComplement!;
    if (widget.initialNeighborhood != null) _neighborhoodController.text = widget.initialNeighborhood!;
    if (widget.initialCity != null) _cityController.text = widget.initialCity!;
    if (widget.initialState != null) _stateController.text = widget.initialState!;
  }

  void _setupListeners() {
    _cepController.addListener(_scheduleSave);
    _numberController.addListener(_scheduleSave);
    _complementController.addListener(_scheduleSave);

    // Buscar CEP ao perder foco (fallback)
    _cepFocusNode.addListener(() {
      if (!_cepFocusNode.hasFocus && _cepController.text.isNotEmpty) {
        final cep = CepHelper.getCepNumbers(_cepController.text);
        if (cep.length == 8 && cep != _lastSearchedCep) _searchCep();
      }
    });
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _cepSearchTimer?.cancel();
    _saveProgressLocally();
    _cepController.removeListener(_scheduleSave);
    _numberController.removeListener(_scheduleSave);
    _complementController.removeListener(_scheduleSave);
    _cepFocusNode.dispose();
    _numberFocusNode.dispose();
    _cepController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
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
    final keepStep = RegistrationProgress.furthestStep(
      existing?.currentStep ?? 'address', 'address',
    );
    final progress = (existing ?? RegistrationProgress(
      cpf: widget.cpf,
      currentStep: keepStep,
      status: RegistrationStatus.inProgress,
      lastUpdated: DateTime.now(),
    )).copyWith(
      currentStep: keepStep,
      lastUpdated: DateTime.now(),
      phone: widget.phone,
      email: widget.email,
      fullName: widget.fullName,
      birthDate: widget.birthDate,
      motherName: widget.motherName,
      cep: CepHelper.getCepNumbers(_cepController.text),
      street: _nonEmpty(_streetController.text),
      number: _nonEmpty(_numberController.text),
      complement: _nonEmpty(_complementController.text),
      neighborhood: _nonEmpty(_neighborhoodController.text),
      city: _nonEmpty(_cityController.text),
      state: _nonEmpty(_stateController.text),
    );
    await LocalRegistrationStorage.saveLocal(progress);
  }

  String? _nonEmpty(String text) => text.trim().isNotEmpty ? text.trim() : null;

  // =========================================================
  // CEP
  // =========================================================

  void _onCepChanged(String value) {
    final cleanCep = CepHelper.cleanCep(value);
    if (cleanCep.length <= 8) {
      final formatted = CepHelper.formatCep(cleanCep);
      if (_cepController.text != formatted) {
        _cepController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
    if (cleanCep.length == 8 && cleanCep != _lastSearchedCep) {
      _cepSearchTimer?.cancel();
      _cepSearchTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) _searchCep();
      });
    }
  }

  Future<void> _searchCep() async {
    final cep = CepHelper.getCepNumbers(_cepController.text);
    if (cep.length != 8 || cep == _lastSearchedCep) return;

    setState(() {
      _isSearchingCep = true;
      _errorMessage = null;
    });

    try {
      final data = await CepService.getAddressByCep(cep);
      if (data != null && mounted) {
        setState(() {
          _streetController.text = data['street'] ?? '';
          _neighborhoodController.text = data['neighborhood'] ?? '';
          _cityController.text = data['city'] ?? '';
          _stateController.text = data['state'] ?? '';
          _lastSearchedCep = cep;
        });
        await _saveProgressLocally();
        if (_cepFocusNode.hasFocus) _numberFocusNode.requestFocus();
      } else if (mounted) {
        setState(() => _errorMessage = 'CEP não encontrado. Verifique e tente novamente.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Erro ao buscar CEP. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _isSearchingCep = false);
    }
  }

  // =========================================================
  // NAVEGACAO
  // =========================================================

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    if (_streetController.text.trim().isEmpty ||
        _neighborhoodController.text.trim().isEmpty ||
        _stateController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Preencha o CEP para carregar o endereço completo.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final existing = await LocalRegistrationStorage.getLocal();
      final savedProgress = (existing ?? RegistrationProgress(
        cpf: widget.cpf,
        currentStep: 'personal2',
        status: RegistrationStatus.inProgress,
        lastUpdated: DateTime.now(),
      )).copyWith(
        currentStep: 'personal2',
        lastUpdated: DateTime.now(),
        phone: widget.phone,
        email: widget.email,
        fullName: widget.fullName,
        birthDate: widget.birthDate,
        motherName: widget.motherName,
        cep: CepHelper.getCepNumbers(_cepController.text),
        street: _nonEmpty(_streetController.text),
        number: _nonEmpty(_numberController.text),
        complement: _nonEmpty(_complementController.text),
        neighborhood: _nonEmpty(_neighborhoodController.text),
        city: _nonEmpty(_cityController.text),
        state: _nonEmpty(_stateController.text),
      );
      await LocalRegistrationStorage.saveLocal(savedProgress);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationAdditionalInfoScreen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: widget.cpf,
            phone: widget.phone,
            email: widget.email,
            fullName: savedProgress.fullName ?? widget.fullName,
            birthDate: savedProgress.birthDate ?? widget.birthDate,
            motherName: savedProgress.motherName ?? widget.motherName,
            cep: savedProgress.cep ?? CepHelper.getCepNumbers(_cepController.text),
            street: savedProgress.street ?? _streetController.text.trim(),
            number: savedProgress.number ?? _numberController.text.trim(),
            complement: savedProgress.complement ?? _complementController.text.trim(),
            neighborhood: savedProgress.neighborhood ?? _neighborhoodController.text.trim(),
            city: savedProgress.city ?? _cityController.text.trim(),
            state: savedProgress.state ?? _stateController.text.trim(),
            initialIsPep: savedProgress.isPep,
            initialOccupation: savedProgress.occupation,
            initialIncomeRange: savedProgress.incomeRange,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
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
          builder: (context) => RegistrationPersonalDataScreen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: widget.cpf,
            phone: widget.phone,
            email: widget.email,
            initialFullName: widget.fullName,
            initialBirthDate: widget.birthDate,
            initialMotherName: widget.motherName,
          ),
        ),
      );
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  InputDecoration _editableDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      prefixIcon: Icon(icon, color: Colors.white70),
    );
  }

  InputDecoration _readOnlyDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      prefixIcon: Icon(icon, color: Colors.white60),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        resizeToAvoidBottomInset: true,
        appBar: GlassAppBar(
          title: const Text(
            'Endereço',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          bottom: RegistrationProgressIndicator.preferredSize(2),
          onBackPressed: _handleBack,
        ),
        body: KeyboardDismissWrapper(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: SingleChildScrollView(
                      clipBehavior: Clip.none,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _cepController,
                            focusNode: _cepFocusNode,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _cepFocusNode.unfocus(),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(8),
                            ],
                            style: const TextStyle(color: Colors.white),
                            onChanged: _onCepChanged,
                            decoration: InputDecoration(
                              labelText: 'CEP',
                              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                              hintText: '00000-000',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
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
                              prefixIcon: const Icon(Icons.location_on, color: Colors.white70),
                              suffixIcon: _isSearchingCep
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            validator: CepHelper.validateCep,
                          ),
                          const SizedBox(height: 20),
                          // Logradouro (read-only)
                          TextFormField(
                            controller: _streetController,
                            readOnly: true,
                            style: const TextStyle(color: Colors.white60),
                            decoration: _readOnlyDecoration('Logradouro', Icons.home),
                          ),
                          const SizedBox(height: 20),
                          // Numero e Complemento
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _numberController,
                                  focusNode: _numberFocusNode,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _numberFocusNode.unfocus(),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _editableDecoration('Nº', Icons.numbers),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Informe' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _complementController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _editableDecoration('Complemento', Icons.apartment),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Bairro (read-only)
                          TextFormField(
                            controller: _neighborhoodController,
                            readOnly: true,
                            style: const TextStyle(color: Colors.white60),
                            decoration: _readOnlyDecoration('Bairro', Icons.location_city),
                          ),
                          const SizedBox(height: 20),
                          // UF e Cidade (read-only)
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _stateController,
                                  readOnly: true,
                                  maxLength: 2,
                                  style: const TextStyle(color: Colors.white60),
                                  decoration: InputDecoration(
                                    labelText: 'UF',
                                    labelStyle: const TextStyle(color: Colors.white60),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.05),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    prefixIcon: const Icon(Icons.map, color: Colors.white60),
                                    counterText: '',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _cityController,
                                  readOnly: true,
                                  style: const TextStyle(color: Colors.white60),
                                  decoration: _readOnlyDecoration('Cidade', Icons.location_city),
                                ),
                              ),
                            ],
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
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundColor),
                            ),
                          )
                        : const Text(
                            'Avançar',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
      ),
    );
  }
}
