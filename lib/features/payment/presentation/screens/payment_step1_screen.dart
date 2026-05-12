import 'package:flutter/material.dart';
import 'package:neves_capital/shared/components/custom_button.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/shared/services/secure_storage_service.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import '../helpers/payment_step_helper.dart';
import 'payment_step2_screen.dart';

/// Tela 1: Inserir nome do estabelecimento e ramo de atuação
/// Só aparece se o usuário ainda não tiver estabelecimento e ramo definidos
class PaymentStep1Screen extends StatefulWidget {
  const PaymentStep1Screen({super.key});

  @override
  State<PaymentStep1Screen> createState() => _PaymentStep1ScreenState();
}

class _PaymentStep1ScreenState extends State<PaymentStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeEstabelecimentoController = TextEditingController();
  String? _ramoAtuacao;
  bool _isLoading = true;
  bool _shouldShowScreen = false;

  // Lista de ramos de atividade (igual à tela Dados da Loja)
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
    _checkIfShouldShowScreen();
  }

  @override
  void dispose() {
    _nomeEstabelecimentoController.dispose();
    super.dispose();
  }

  String? _getRamoLabel(String? value) {
    if (value == null) return null;
    try {
      return _businessTypes.firstWhere((e) => e['value'] == value)['label'];
    } catch (_) {
      return null;
    }
  }

  /// Verificar se o usuário já tem estabelecimento e ramo definidos
  Future<void> _checkIfShouldShowScreen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Buscar CPF do SecureStorage
      final cpf = await SecureStorageService.getLastCpf();
      if (cpf == null || cpf.isEmpty) {
        AppLogger.warning('CPF não encontrado - mostrando tela de estabelecimento');
        setState(() {
          _shouldShowScreen = true;
          _isLoading = false;
        });
        return;
      }

      // Buscar dados do usuário no Firestore
      final userData = await FirestoreService.getUserByCpf(cpf);
      
      if (userData == null) {
        AppLogger.warning('Usuário não encontrado - mostrando tela de estabelecimento');
        setState(() {
          _shouldShowScreen = true;
          _isLoading = false;
        });
        return;
      }

      // Verificar se já tem estabelecimento e ramo
      final storeName = userData['storeName'] as String?;
      final businessType = userData['businessType'] as String?;

      final hasStoreData = storeName != null && 
                          storeName.isNotEmpty && 
                          businessType != null && 
                          businessType.isNotEmpty;

      AppLogger.debug('Dados da loja encontrados: storeName=${storeName != null}, businessType=${businessType != null}');

      if (hasStoreData) {
        // Usuário já tem estabelecimento e ramo - pular para step 2
        AppLogger.info('Usuário já tem estabelecimento e ramo - pulando para step 2');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentStep2Screen(
                nomeEstabelecimento: storeName,
                ramoAtuacao: businessType,
              ),
            ),
          );
        }
      } else {
        // Usuário não tem estabelecimento e ramo - mostrar tela
        AppLogger.info('Usuário não tem estabelecimento e ramo - mostrando tela');
        setState(() {
          _shouldShowScreen = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Erro ao verificar dados do estabelecimento', e);
      // Em caso de erro, mostrar a tela para o usuário preencher
      setState(() {
        _shouldShowScreen = true;
        _isLoading = false;
      });
    }
  }

  void _continuar() {
    if (_formKey.currentState?.validate() ?? false) {
      // Salvar dados do estabelecimento no Firestore antes de continuar
      _saveStoreDataAndContinue();
    }
  }

  /// Salvar dados do estabelecimento e continuar para próxima tela
  Future<void> _saveStoreDataAndContinue() async {
    try {
      // Buscar CPF e userId
      final cpf = await SecureStorageService.getLastCpf();
      if (cpf == null || cpf.isEmpty) {
        throw Exception('CPF não encontrado. Faça login novamente.');
      }

      final userData = await FirestoreService.getUserByCpf(cpf);
      if (userData == null || userData['id'] == null) {
        throw Exception('Usuário não encontrado.');
      }

      final userId = userData['id'] as String;

      // Salvar dados do estabelecimento
      final success = await FirestoreService.updateUser(
        userId: userId,
        storeName: _nomeEstabelecimentoController.text.trim(),
        businessType: _ramoAtuacao ?? '',
      );

      if (!success) {
        throw Exception('Erro ao salvar dados do estabelecimento');
      }

      AppLogger.info('Dados do estabelecimento salvos com sucesso');

      // Continuar para próxima tela
      // Marcar como primeira venda para que a numeração dos passos seja correta (2/5)
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentStep2Screen(
              nomeEstabelecimento: _nomeEstabelecimentoController.text.trim(),
              ramoAtuacao: _ramoAtuacao ?? '',
              isFirstSale: true, // Indica que é a primeira venda
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Erro ao salvar dados do estabelecimento', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loading enquanto verifica se deve mostrar a tela
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    // Se não deve mostrar a tela, não renderizar nada (já foi redirecionado)
    if (!_shouldShowScreen) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: GlassAppBar(
        title: const Text(
          'Dados da Loja',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: PaymentStepHelper.buildProgressIndicator(1, 5),
          ),
        ),
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
                  child: SingleChildScrollView(
                    clipBehavior: Clip.none,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  TextFormField(
                    controller: _nomeEstabelecimentoController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Nome da Loja',
                      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      prefixIcon: const Icon(Icons.storefront, color: Colors.white70),
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
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o nome do estabelecimento';
                      }
                      if (value.length < 3) {
                        return 'Nome deve ter pelo menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: _getRamoLabel(_ramoAtuacao) ?? '',
                    ),
                    onTap: () async {
                      final value = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (context) => _RamoSearchScreen(
                            businessTypes: _businessTypes,
                            selectedValue: _ramoAtuacao,
                          ),
                        ),
                      );
                      if (!mounted) return;
                      FocusManager.instance.primaryFocus?.unfocus();
                      if (value != null) {
                        setState(() {
                          _ramoAtuacao = value;
                        });
                      }
                    },
                    style: TextStyle(
                      color: _ramoAtuacao != null
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Ramo de Atuação',
                      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      hintText: 'Selecione o ramo',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      prefixIcon: const Icon(Icons.store, color: Colors.white70),
                      suffixIcon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
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
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    validator: (_) {
                      if (_ramoAtuacao == null || _ramoAtuacao!.isEmpty) {
                        return 'Por favor, selecione o ramo de atuação';
                      }
                      return null;
                    },
                  ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Avançar',
              onPressed: _continuar,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
    );
  }
}

/// Tela de seleção de ramo de atuação (mesmo formato da tela de seleção de banco)
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
          onPressed: () => Navigator.of(context).pop(widget.selectedValue),
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
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check, color: AppTheme.primaryColor)
                            : null,
                        onTap: () => Navigator.of(context).pop(value),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
