import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/shared/services/secure_storage_service.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'package:neves_capital/shared/components/custom_button.dart';

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
  final _ramoController = TextEditingController();
  final _storeNameFocus = FocusNode();

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
    {
      'value': 'alimentos_bebidas_vr',
      'label': 'Alimentos e Bebidas (Aceita VR)'
    },
    {
      'value': 'acougues_peixarias_va',
      'label': 'Açougues e Peixarias (Aceita VA)'
    },
    {'value': 'beleza_cuidados', 'label': 'Beleza e Cuidados Pessoais'},
    {'value': 'construcao_reparos', 'label': 'Construção e Reparos'},
    {'value': 'lazer_eventos', 'label': 'Lazer e Eventos'},
    {'value': 'moda_acessorios', 'label': 'Moda e Acessórios'},
    {'value': 'petshop_veterinario', 'label': 'Petshop e Veterinário'},
    {'value': 'saude_bem_estar', 'label': 'Saúde e Bem-Estar'},
    {'value': 'servicos_gerais', 'label': 'Serviços Gerais'},
    {'value': 'tecnologia_informatica', 'label': 'Tecnologia e Informática'},
    {'value': 'transporte_entregas', 'label': 'Transporte e Entregas'},
    {
      'value': 'outros_produtos_servicos',
      'label': 'Outros Produtos e Serviços'
    },
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
    _ramoController.dispose();
    _storeNameFocus.dispose();
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
        AppLogger.warning(
            'BusinessType "$loadedBusinessType" não existe mais na lista. Resetando para null.');
      }

      setState(() {
        _storeNameController.text = userData['storeName'] ?? '';
        _selectedBusinessType = validBusinessType;
        _ramoController.text = _getSelectedRamoLabel() ?? '';

        // Armazenar valores originais
        _originalStoreName = _storeNameController.text.trim();
        _originalBusinessType = _selectedBusinessType;
        _hasChanges = false;
      });

      // Adicionar listeners para rastrear mudanças
      _storeNameController.addListener(_checkForChanges);

      AppLogger.info(
          'Dados da loja carregados: ${_storeNameController.text}, $_selectedBusinessType');
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

  String? _getSelectedRamoLabel() {
    if (_selectedBusinessType == null) return null;
    final type = _businessTypes.firstWhere(
      (t) => t['value'] == _selectedBusinessType,
      orElse: () => {'label': ''},
    );
    return type['label'];
  }

  void _showRamoSearch(BuildContext context) async {
    final selected = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => _RamoSearchScreen(
          businessTypes: _businessTypes,
          selectedValue: _selectedBusinessType,
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedBusinessType = selected;
        _ramoController.text = _getSelectedRamoLabel() ?? '';
        _checkForChanges();
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
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text(
          'Dados da Loja',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : SafeArea(
              top: false,
              child: KeyboardDismissWrapper(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        clipBehavior: Clip.none,
                        padding: EdgeInsets.fromLTRB(
                          24.0,
                          MediaQuery.of(context).padding.top + kToolbarHeight + 24,
                          24.0,
                          0,
                        ),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _storeNameController,
                                focusNode: _storeNameFocus,
                                autofocus: false,
                                textInputAction: TextInputAction.next,
                                inputFormatters: [_TitleCasePtBrFormatter()],
                                style: const TextStyle(color: Colors.white),
                                onChanged: (value) => _checkForChanges(),
                                decoration: InputDecoration(
                                  labelText: 'Nome da Loja',
                                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _ramoController,
                                readOnly: true,
                                onTap: () {
                                  _storeNameFocus.unfocus();
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  _showRamoSearch(context);
                                },
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Ramo de Atuação',
                                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                                  prefixIcon: const Icon(
                                    Icons.store,
                                    color: AppTheme.textSecondary,
                                  ),
                                  suffixIcon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: AppTheme.textSecondary,
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
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
                      child: CustomButton(
                        text: 'Atualizar',
                        onPressed: (_isLoading || !_hasChanges)
                            ? null
                            : _saveStoreData,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Tela de busca de ramo de atuação (igual à tela de ocupação)
class _RamoSearchScreen extends StatefulWidget {
  final List<Map<String, String>> businessTypes;
  final String? selectedValue;

  const _RamoSearchScreen({
    required this.businessTypes,
    this.selectedValue,
  });

  @override
  State<_RamoSearchScreen> createState() => _RamoSearchScreenState();
}

class _RamoSearchScreenState extends State<_RamoSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, String>> _filteredTypes = [];

  @override
  void initState() {
    super.initState();
    _filteredTypes = List.from(widget.businessTypes);
    _searchController.addListener(_filterTypes);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterTypes);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _removeAccents(String text) {
    return text
        .replaceAll(RegExp('[àáâãäå]'), 'a')
        .replaceAll(RegExp('[èéêë]'), 'e')
        .replaceAll(RegExp('[ìíîï]'), 'i')
        .replaceAll(RegExp('[òóôõö]'), 'o')
        .replaceAll(RegExp('[ùúûü]'), 'u')
        .replaceAll(RegExp('[ýÿ]'), 'y')
        .replaceAll('ñ', 'n')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp('[ÀÁÂÃÄÅ]'), 'A')
        .replaceAll(RegExp('[ÈÉÊË]'), 'E')
        .replaceAll(RegExp('[ÌÍÎÏ]'), 'I')
        .replaceAll(RegExp('[ÒÓÔÕÖ]'), 'O')
        .replaceAll(RegExp('[ÙÚÛÜ]'), 'U')
        .replaceAll(RegExp('[ÝŸ]'), 'Y')
        .replaceAll('Ñ', 'N')
        .replaceAll('Ç', 'C');
  }

  /// Verifica se [query] é uma subsequência de [target] — os caracteres
  /// da query aparecem em [target] na mesma ordem (permite caracteres faltando).
  /// Tolera digitação como "acogue" casando com "acougue".
  bool _isSubsequence(String query, String target) {
    int qi = 0;
    for (int ti = 0; ti < target.length && qi < query.length; ti++) {
      if (target[ti] == query[qi]) qi++;
    }
    return qi == query.length;
  }

  void _filterTypes() {
    final query = _removeAccents(_searchController.text.toLowerCase().trim());
    setState(() {
      if (query.isEmpty) {
        _filteredTypes = List.from(widget.businessTypes);
      } else {
        _filteredTypes = widget.businessTypes.where((type) {
          final normalized =
              _removeAccents((type['label'] ?? '').toLowerCase());
          if (normalized.contains(query)) return true;
          if (query.length >= 3) return _isSubsequence(query, normalized);
          return false;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, widget.selectedValue),
        ),
        title: const Text(
          'Selecione o Ramo de Atuação',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 4.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: false,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Digite o nome do ramo de atuação',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
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
            ),
          ),
          Expanded(
            child: _filteredTypes.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum ramo encontrado',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _filteredTypes.length,
                    itemBuilder: (context, index) {
                      final type = _filteredTypes[index];
                      final value = type['value']!;
                      final label = type['label']!;
                      final isSelected = value == widget.selectedValue;
                      return ListTile(
                        title: Text(
                          label,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check, color: AppTheme.primaryColor)
                            : null,
                        onTap: () => Navigator.pop(context, value),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Aplica title case PT-BR: capitaliza cada palavra, exceto stopwords
/// (de, do, da, e, etc.). A primeira palavra sempre fica capitalizada.
/// Exemplos: "loja do zé" → "Loja do Zé", "comercio e representacoes" → "Comercio e Representacoes".
class _TitleCasePtBrFormatter extends TextInputFormatter {
  static const Set<String> _stopwords = {
    'de', 'do', 'da', 'dos', 'das',
    'e',
    'a', 'o', 'as', 'os',
    'em', 'no', 'na', 'nos', 'nas',
    'um', 'uma', 'uns', 'umas',
    'por', 'para', 'com',
    'ao', 'aos', 'à', 'às',
  };

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final words = text.split(' ');
    final result = <String>[];

    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      if (w.isEmpty) {
        result.add(w);
        continue;
      }
      final lower = w.toLowerCase();
      if (i > 0 && _stopwords.contains(lower)) {
        result.add(lower);
      } else {
        result.add(w[0].toUpperCase() + (w.length > 1 ? w.substring(1).toLowerCase() : ''));
      }
    }

    final formatted = result.join(' ');
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
