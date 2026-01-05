import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/shared/helpers/cep_helper.dart';
import 'package:neves_capital/shared/services/cep_service.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'package:neves_capital/shared/components/number_keyboard_toolbar.dart';

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
  final FocusNode _cepFocusNode = FocusNode();
  final FocusNode _numberFocusNode = FocusNode();
  final FocusNode _complementFocusNode = FocusNode();
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSearchingCep = false;
  String? _errorMessage;
  Timer? _cepSearchTimer;
  String _lastSearchedCep = '';

  @override
  void initState() {
    super.initState();
    
    // Se for modo de edição, pré-preencher campos com dados existentes
    if (widget.isEditMode) {
      final cep = widget.loginData['cep'] ?? '';
      if (cep.isNotEmpty) {
        _cepController.text = CepHelper.formatCep(cep);
      }
      _streetController.text = widget.loginData['street'] ?? '';
      _neighborhoodController.text = widget.loginData['neighborhood'] ?? '';
      _cityController.text = widget.loginData['city'] ?? '';
      _stateController.text = widget.loginData['state'] ?? '';
      _numberController.text = widget.loginData['number'] ?? '';
      _complementController.text = widget.loginData['complement'] ?? '';
    }

    // Listener para buscar CEP quando perder o foco (fallback)
    _cepFocusNode.addListener(() {
      if (!_cepFocusNode.hasFocus && _cepController.text.isNotEmpty) {
        final cep = CepHelper.getCepNumbers(_cepController.text);
        if (cep.length == 8 && cep != _lastSearchedCep) {
          _searchCep();
        }
      }
    });

    // Abrir teclado automaticamente apenas se não houver valores restaurados
    final cepValue = widget.loginData['cep'];
    if (!widget.isEditMode || (cepValue == null || cepValue.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cepFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _cepSearchTimer?.cancel();
    _cepController.dispose();
    _streetController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _cepFocusNode.dispose();
    _numberFocusNode.dispose();
    _complementFocusNode.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
                            child: Container(
                              width: 32,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Color(0xFF22C55E),
                                borderRadius: BorderRadius.circular(2),
                              ),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CEP',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              NumberKeyboardToolbar(
                                focusNode: _cepFocusNode,
                                doneText: 'OK',
                                toolbarColor: const Color(0xFF122118), // Cor do fundo do body da aplicação
                                buttonColor: const Color(0xFF007AFF),
                                child: TextFormField(
                                  controller: _cepController,
                                  focusNode: _cepFocusNode,
                                  keyboardType: TextInputType.number,
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
                                  hintText: '00000-000',
                                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.1),
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
                                    borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.red, width: 2),
                                  ),
                                    prefixIcon: const Icon(Icons.location_on, color: Colors.white70),
                                  ),
                                  validator: CepHelper.validateCep,
                                ),
                              ),
                            ],
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
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
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
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Logradouro',
                              labelStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
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
                                    const BorderSide(color: Color(0xFF22C55E), width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              prefixIcon: const Icon(Icons.home, color: Colors.white70),
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
                                child: NumberKeyboardToolbar(
                                  focusNode: _numberFocusNode,
                                  doneText: 'OK',
                                  toolbarColor: const Color(0xFF122118), // Cor do fundo do body da aplicação
                                  buttonColor: const Color(0xFF007AFF),
                                  child: TextFormField(
                                    controller: _numberController,
                                    focusNode: _numberFocusNode,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Nº',
                                      labelStyle: const TextStyle(color: Colors.white70),
                                      filled: true,
                                      fillColor: Colors.white.withValues(alpha: 0.1),
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
                                            const BorderSide(color: Color(0xFF22C55E), width: 2),
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
                                    fillColor: Colors.white.withValues(alpha: 0.1),
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
                                          const BorderSide(color: Color(0xFF22C55E), width: 2),
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
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Bairro',
                              labelStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
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
                                    const BorderSide(color: Color(0xFF22C55E), width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              prefixIcon: const Icon(Icons.location_city, color: Colors.white70),
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
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'UF',
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.1),
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
                                          const BorderSide(color: Color(0xFF22C55E), width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    ),
                                    prefixIcon: const Icon(Icons.map, color: Colors.white70),
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
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Cidade',
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.1),
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
                                          const BorderSide(color: Color(0xFF22C55E), width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    ),
                                    prefixIcon: const Icon(Icons.location_city, color: Colors.white70),
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
                              onPressed: _isLoading ? null : _handleContinue,
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
                                  : Text(
                                      widget.isEditMode ? 'Salvar Alterações' : 'Finalizar Cadastro',
                                      style: const TextStyle(
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

        // Atualizar apenas endereço no Firestore
        if (widget.userId == null || widget.userId!.isEmpty) {
          throw Exception('ID do usuário não encontrado');
        }

        final success = await FirestoreService.updateUser(
          userId: widget.userId!,
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
        // Modo cadastro não é mais usado nesta tela
        // Esta tela é apenas para edição de endereço
        throw Exception('Modo cadastro não suportado nesta tela');
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
