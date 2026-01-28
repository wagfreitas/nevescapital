import 'dart:async';
import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/features/auth/presentation/controllers/registration_lifecycle_observer.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'package:neves_capital/features/auth/presentation/helpers/registration_navigation_helper.dart';
import 'package:neves_capital/shared/helpers/cep_helper.dart';
import 'package:neves_capital/shared/services/cep_service.dart';
import 'step5_personal_data_1_screen.dart';
import 'step7_personal_data_2_screen.dart';

/// Tela 6 do Cadastro: Informações de Endereço
class Step6AddressScreen extends StatefulWidget {
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

  const Step6AddressScreen({
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
  State<Step6AddressScreen> createState() => _Step6AddressScreenState();
}

class _Step6AddressScreenState extends State<Step6AddressScreen> {
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _complementController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final FocusNode _cepFocusNode = FocusNode();
  final FocusNode _numberFocusNode = FocusNode();
  final FocusNode _complementFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSearchingCep = false;
  String? _errorMessage;
  late RegistrationLifecycleObserver _lifecycleObserver;
  Timer? _saveDebounceTimer;
  Timer? _cepSearchTimer;
  String _lastSearchedCep = '';

  @override
  void initState() {
    super.initState();

    // Restaurar valores salvos se existirem
    if (widget.initialCep != null && widget.initialCep!.isNotEmpty) {
      // Formatar CEP corretamente (99999-999)
      _cepController.text = CepHelper.formatCep(widget.initialCep!);
    }
    if (widget.initialStreet != null && widget.initialStreet!.isNotEmpty) {
      _streetController.text = widget.initialStreet!;
    }
    if (widget.initialNumber != null && widget.initialNumber!.isNotEmpty) {
      _numberController.text = widget.initialNumber!;
    }
    if (widget.initialComplement != null && widget.initialComplement!.isNotEmpty) {
      _complementController.text = widget.initialComplement!;
    }
    if (widget.initialNeighborhood != null && widget.initialNeighborhood!.isNotEmpty) {
      _neighborhoodController.text = widget.initialNeighborhood!;
    }
    if (widget.initialCity != null && widget.initialCity!.isNotEmpty) {
      _cityController.text = widget.initialCity!;
    }
    if (widget.initialState != null && widget.initialState!.isNotEmpty) {
      _stateController.text = widget.initialState!;
    }

    _lifecycleObserver = RegistrationLifecycleObserver(
      getCurrentProgress: () => RegistrationProgress(
        cpf: widget.cpf,
        currentStep: 'address',
        status: RegistrationStatus.inProgress,
        lastUpdated: DateTime.now(),
        phone: widget.phone,
        email: widget.email,
        fullName: widget.fullName,
        birthDate: widget.birthDate,
        motherName: widget.motherName,
        cep: CepHelper.getCepNumbers(_cepController.text),
        street: _streetController.text.trim().isNotEmpty ? _streetController.text.trim() : null,
        number: _numberController.text.trim().isNotEmpty ? _numberController.text.trim() : null,
        complement: _complementController.text.trim().isNotEmpty ? _complementController.text.trim() : null,
        neighborhood: _neighborhoodController.text.trim().isNotEmpty ? _neighborhoodController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        state: _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
      ),
      shouldSaveProgress: () => ModalRoute.of(context)?.isCurrent ?? false,
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    // Salvar progresso imediatamente se houver valores restaurados
    if (widget.initialCep != null || widget.initialStreet != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lifecycleObserver.saveNow(localOnly: false);
      });
    }

    // Adicionar listeners para salvar automaticamente quando o usuário digitar
    _cepController.addListener(_onFieldChanged);
    _streetController.addListener(_onFieldChanged);
    _numberController.addListener(_onFieldChanged);
    _complementController.addListener(_onFieldChanged);
    _neighborhoodController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
    _stateController.addListener(_onFieldChanged);

    // Listener para buscar CEP quando perder o foco (fallback)
    _cepFocusNode.addListener(() {
      if (!_cepFocusNode.hasFocus && _cepController.text.isNotEmpty) {
        final cep = CepHelper.getCepNumbers(_cepController.text);
        if (cep.length == 8 && cep != _lastSearchedCep) {
        _searchCep();
        }
      }
    });

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

  Future<void> _searchCep() async {
    final cep = CepHelper.getCepNumbers(_cepController.text);
    
    if (cep.length != 8) return;
    
    // Evitar buscar o mesmo CEP novamente
    if (cep == _lastSearchedCep) return;
    
    setState(() {
      _isSearchingCep = true;
      _errorMessage = null;
    });

    try {
      final addressData = await CepService.getAddressByCep(cep);
      
      if (addressData != null && mounted) {
        setState(() {
          _streetController.text = addressData['street'] ?? '';
          _neighborhoodController.text = addressData['neighborhood'] ?? '';
          _cityController.text = addressData['city'] ?? '';
          _stateController.text = addressData['state'] ?? '';
          _lastSearchedCep = cep; // Marcar como buscado
        });
        
        // Salvar progresso após buscar CEP
        await _lifecycleObserver.saveNow(localOnly: true);
        
        // Mover foco para o campo de número apenas se o campo de CEP ainda estiver em foco
        if (_cepFocusNode.hasFocus) {
        _numberFocusNode.requestFocus();
        }
      } else if (mounted) {
        setState(() {
          _errorMessage = 'CEP não encontrado. Verifique e tente novamente.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao buscar CEP. Tente novamente.';
        });
        AppLogger.error('Erro ao buscar CEP: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingCep = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _cepSearchTimer?.cancel();
    _cepController.removeListener(_onFieldChanged);
    _streetController.removeListener(_onFieldChanged);
    _numberController.removeListener(_onFieldChanged);
    _complementController.removeListener(_onFieldChanged);
    _neighborhoodController.removeListener(_onFieldChanged);
    _cityController.removeListener(_onFieldChanged);
    _stateController.removeListener(_onFieldChanged);
    _lifecycleObserver.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _cepFocusNode.dispose();
    _numberFocusNode.dispose();
    _complementFocusNode.dispose();
    _cepController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
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
        currentStep: 'personal2',
        status: RegistrationStatus.inProgress,
        lastUpdated: DateTime.now(),
        phone: widget.phone,
        email: widget.email,
        fullName: widget.fullName,
        birthDate: widget.birthDate,
        motherName: widget.motherName,
        cep: CepHelper.getCepNumbers(_cepController.text),
        street: _streetController.text.trim().isNotEmpty ? _streetController.text.trim() : null,
        number: _numberController.text.trim().isNotEmpty ? _numberController.text.trim() : null,
        complement: _complementController.text.trim().isNotEmpty ? _complementController.text.trim() : null,
        neighborhood: _neighborhoodController.text.trim().isNotEmpty ? _neighborhoodController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        state: _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
      );

      // Salvar e buscar progresso completo (garante que dados de outras telas sejam preservados)
      final completeProgress = await RegistrationNavigationHelper.saveAndGetCompleteProgress(
        currentProgress: currentProgress,
      );

      if (!mounted) return;

      // Navegar para próxima tela
      // Usar dados do progresso completo para restaurar tudo que já foi preenchido
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Step7PersonalData2Screen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: widget.cpf,
            phone: widget.phone,
            email: widget.email,
            fullName: completeProgress?.fullName ?? widget.fullName,
            birthDate: completeProgress?.birthDate ?? widget.birthDate,
            motherName: completeProgress?.motherName ?? widget.motherName,
            cep: completeProgress?.cep ?? CepHelper.getCepNumbers(_cepController.text),
            street: completeProgress?.street ?? _streetController.text.trim(),
            number: completeProgress?.number ?? _numberController.text.trim(),
            complement: completeProgress?.complement ?? _complementController.text.trim(),
            neighborhood: completeProgress?.neighborhood ?? _neighborhoodController.text.trim(),
            city: completeProgress?.city ?? _cityController.text.trim(),
            state: completeProgress?.state ?? _stateController.text.trim(),
            initialIsPep: completeProgress?.isPep,
            initialOccupation: completeProgress?.occupation,
            initialIncomeRange: completeProgress?.incomeRange,
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Tentar fazer pop primeiro (se houver tela anterior na pilha)
            // Se não houver, navegar explicitamente para a tela anterior
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Não há tela anterior na pilha (vem do fluxo de "Recomeçar")
              // Navegar explicitamente para a tela de dados pessoais 1
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Step5PersonalData1Screen(
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
          },
        ),
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
                                Container(
                                  width: 32,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 32,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
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
                            'Informe seu Endereço:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // CEP
                          TextFormField(
                            controller: _cepController,
                            focusNode: _cepFocusNode,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              // Fechar teclado quando usuário pressionar "OK" ou "Done"
                              _cepFocusNode.unfocus();
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9), // xxxxx-xxx
                            ],
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) {
                              // Formatar CEP enquanto digita
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
                              
                              // Buscar CEP automaticamente quando tiver 8 dígitos
                              if (cleanCep.length == 8 && cleanCep != _lastSearchedCep) {
                                // Cancelar timer anterior se existir
                                _cepSearchTimer?.cancel();
                                
                                // Aguardar 500ms após parar de digitar antes de buscar (debounce)
                                _cepSearchTimer = Timer(const Duration(milliseconds: 500), () {
                                  if (mounted) {
                                    final currentCep = CepHelper.getCepNumbers(_cepController.text);
                                    if (currentCep.length == 8 && currentCep != _lastSearchedCep) {
                                      _searchCep();
                                    }
                                  }
                                });
                              }
                            },
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
                                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              prefixIcon: const Icon(Icons.location_on, color: Colors.white70),
                            ),
                            validator: CepHelper.validateCep,
                          ),
                          if (_isSearchingCep) ...[
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Buscando endereço...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),
                          // Logradouro
                          TextFormField(
                            controller: _streetController,
                            keyboardType: TextInputType.streetAddress,
                            readOnly: true,
                            style: const TextStyle(color: Colors.white60),
                            decoration: InputDecoration(
                              labelText: 'Logradouro',
                              labelStyle: const TextStyle(color: Colors.white60),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              prefixIcon: const Icon(Icons.home, color: Colors.white60),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Digite o logradouro';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Número e Complemento (lado a lado)
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _numberController,
                                  focusNode: _numberFocusNode,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    // Fechar teclado quando usuário pressionar "OK" ou "Done"
                                    _numberFocusNode.unfocus();
                                  },
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Nº',
                                    labelStyle: const TextStyle(color: Colors.white70),
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
                                    prefixIcon: const Icon(Icons.numbers, color: Colors.white70),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Digite o número';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _complementController,
                                  focusNode: _complementFocusNode,
                                  keyboardType: TextInputType.text,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Complemento',
                                    labelStyle: const TextStyle(color: Colors.white70),
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
                                    prefixIcon: const Icon(Icons.apartment, color: Colors.white70),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Bairro
                          TextFormField(
                            controller: _neighborhoodController,
                            keyboardType: TextInputType.text,
                            readOnly: true,
                            style: const TextStyle(color: Colors.white60),
                            decoration: InputDecoration(
                              labelText: 'Bairro',
                              labelStyle: const TextStyle(color: Colors.white60),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              prefixIcon: const Icon(Icons.location_city, color: Colors.white60),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Digite o bairro';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // UF e Cidade (lado a lado)
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _stateController,
                                  keyboardType: TextInputType.text,
                                  textCapitalization: TextCapitalization.characters,
                                  maxLength: 2,
                                  readOnly: true,
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
                                      borderSide: BorderSide(
                                          color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    ),
                                    prefixIcon: const Icon(Icons.map, color: Colors.white60),
                                    counterText: '',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Digite a UF';
                                    }
                                    if (value.trim().length != 2) {
                                      return 'UF deve ter 2 letras';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _cityController,
                                  keyboardType: TextInputType.text,
                                  readOnly: true,
                                  style: const TextStyle(color: Colors.white60),
                                  decoration: InputDecoration(
                                    labelText: 'Cidade',
                                    labelStyle: const TextStyle(color: Colors.white60),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.05),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    ),
                                    prefixIcon: const Icon(Icons.location_city, color: Colors.white60),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Digite a cidade';
                                    }
                                    return null;
                                  },
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
                          const SizedBox(height: 40),
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

