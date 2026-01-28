import 'package:flutter/material.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/shared/services/secure_storage_service.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';

/// Tela para alterar dados da loja (Nome e Ramo)
/// Conforme wireframe fornecido
class EditStoreDataScreen extends StatefulWidget {
  final AuthController authController;

  const EditStoreDataScreen({
    super.key,
    required this.authController,
  });

  @override
  State<EditStoreDataScreen> createState() => _EditStoreDataScreenState();
}

class _EditStoreDataScreenState extends State<EditStoreDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _userId;
  String? _selectedBusinessType;
  
  // Valores originais para rastrear mudanças
  String _originalStoreName = '';
  String? _originalBusinessType;
  bool _hasChanges = false;

  // Lista de ramos de atividade
  final List<Map<String, String>> _businessTypes = [
    {'value': 'alimentos_bebidas_vr', 'label': 'Alimentos e Bebidas (Aceita VR)'},
    {'value': 'acougues_peixarias_va', 'label': 'Açougues e Peixarias (Aceita VA)'},
    {'value': 'beleza_cuidados', 'label': 'Beleza e Cuidados Pessoais'},
    {'value': 'construcao_reparos', 'label': 'Construção e Reparos'},
    {'value': 'lazer_eventos', 'label': 'Lazer e Eventos'},
    {'value': 'moda_acessorios', 'label': 'Moda e Acessórios'},
    {'value': 'petshop_veterinario', 'label': 'Petshop e Veterinário'},
    {'value': 'saude_bem_estar', 'label': 'Saúde e Bem-Estar'},
    {'value': 'servicos_gerais', 'label': 'Serviços Gerais'},
    {'value': 'tecnologia_informatica', 'label': 'Tecnologia e Informática'},
    {'value': 'transporte_entregas', 'label': 'Transporte e Entregas'},
    {'value': 'outros_produtos_servicos', 'label': 'Outros Produtos e Serviços'},
  ];

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  @override
  void dispose() {
    _storeNameController.removeListener(_checkForChanges);
    _storeNameController.dispose();
    super.dispose();
  }
  
  /// Verificar se houve mudanças nos campos
  void _checkForChanges() {
    final currentStoreName = _storeNameController.text.trim();
    final hasChanges = currentStoreName != _originalStoreName ||
        _selectedBusinessType != _originalBusinessType;
    
    if (_hasChanges != hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  /// Carregar dados da loja do Firestore
  Future<void> _loadStoreData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // 1. Buscar CPF e userId
      final cpf = await SecureStorageService.getLastCpf();
      if (cpf == null || cpf.isEmpty) {
        throw Exception('CPF não encontrado. Faça login novamente.');
      }

      // 2. Buscar dados do usuário no Firestore
      final userData = await FirestoreService.getUserByCpf(cpf);
      if (userData == null || userData['id'] == null) {
        throw Exception('Usuário não encontrado.');
      }

      _userId = userData['id'] as String;

      // 3. Carregar dados da loja do documento do usuário
      AppLogger.debug('Carregando dados da loja...');
      AppLogger.debug('storeName: ${userData['storeName']}');
      AppLogger.debug('businessType: ${userData['businessType']}');
      
      // Validar se o businessType existe na lista atual
      final loadedBusinessType = userData['businessType'] as String?;
      final validBusinessType = loadedBusinessType != null &&
          _businessTypes.any((type) => type['value'] == loadedBusinessType)
          ? loadedBusinessType
          : null;
      
      if (loadedBusinessType != null && validBusinessType == null) {
        AppLogger.warning('BusinessType "$loadedBusinessType" não existe mais na lista. Resetando para null.');
      }
      
      setState(() {
        _storeNameController.text = userData['storeName'] ?? '';
        _selectedBusinessType = validBusinessType;
        
        // Armazenar valores originais
        _originalStoreName = _storeNameController.text.trim();
        _originalBusinessType = _selectedBusinessType;
        _hasChanges = false;
      });
      
      // Adicionar listeners para rastrear mudanças
      _storeNameController.addListener(_checkForChanges);
      
      AppLogger.info('Dados da loja carregados: ${_storeNameController.text}, $_selectedBusinessType');
    } catch (e) {
      AppLogger.error('Erro ao carregar dados da loja', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  /// Salvar dados da loja no Firestore
  Future<void> _saveStoreData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBusinessType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o ramo de atividade'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await FirestoreService.updateUser(
        userId: _userId!,
        storeName: _storeNameController.text.trim(),
        businessType: _selectedBusinessType!,
      );

      if (!mounted) return;

      if (success) {
        // Atualizar valores originais após salvar
        _originalStoreName = _storeNameController.text.trim();
        _originalBusinessType = _selectedBusinessType;
        _hasChanges = false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados da loja salvos com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        throw Exception('Erro ao salvar dados da loja');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: KeyboardDismissWrapper(
          child: _isLoadingData
              ? Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                )
              : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título centralizado
                      const Center(
                        child: Text(
                          'Dados da Loja',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Nome da loja
                      TextFormField(
                        controller: _storeNameController,
                        autofocus: false, // Não focar automaticamente
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.normal,
                          height: 1.0,
                          letterSpacing: 0.0,
                        ),
                        onChanged: (value) => _checkForChanges(),
                        decoration: InputDecoration(
                          labelText: 'Nome da Loja',
                          labelStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
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
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nome da loja é obrigatório';
                          }
                          if (value.trim().length < 3) {
                            return 'Nome deve ter pelo menos 3 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24.0),
                      
                      // Ramo de atividade (dropdown)
                      DefaultTextStyle(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.normal,
                          height: 1.0,
                          letterSpacing: 0.0,
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedBusinessType,
                          isExpanded: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.normal,
                            height: 1.0,
                            letterSpacing: 0.0,
                            inherit: false,
                          ),
                          selectedItemBuilder: (BuildContext context) {
                            return _businessTypes.map((type) {
                              return DefaultTextStyle(
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.normal,
                                  height: 1.0,
                                  letterSpacing: 0.0,
                                ),
                                child: Text(
                                  type['label']!,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList();
                          },
                        decoration: InputDecoration(
                          labelText: 'Ramos de Atuação',
                          labelStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                          hintStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
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
                        ),
                        dropdownColor: const Color(0xFF1a2d21),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        items: _businessTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type['value'],
                            child: Text(
                              type['label']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBusinessType = value;
                          });
                          _checkForChanges();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selecione o ramo de atividade';
                          }
                          return null;
                        },
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      
                      // Botão CONFIRMAR
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isLoading || !_hasChanges) ? null : _saveStoreData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppTheme.backgroundColor,
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
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundColor),
                                  ),
                                )
                              : const Text(
                                  'CONFIRMAR',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

