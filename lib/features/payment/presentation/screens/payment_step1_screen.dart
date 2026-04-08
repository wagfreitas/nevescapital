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
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(),
      body: SafeArea(
        child: KeyboardDismissWrapper(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título
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
                  
                  const SizedBox(height: 20),
                  
                  // Indicador de progresso (abaixo do título)
                  // Esta tela só aparece se o usuário não tem conta, então sempre é passo 1 de 5
                  PaymentStepHelper.buildProgressIndicator(1, 5),
                  const SizedBox(height: 32),

                  // Campo de nome do estabelecimento
                  TextFormField(
                    controller: _nomeEstabelecimentoController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nome do Estabelecimento',
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

                  // Campo de ramo de atuação (abre tela de seleção no formato da escolha do banco)
                  FormField<String>(
                    initialValue: _ramoAtuacao,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, selecione o ramo de atuação';
                      }
                      return null;
                    },
                    builder: (formState) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final value = await Navigator.of(context).push<String>(
                                MaterialPageRoute(
                                  builder: (context) => _RamoSearchScreen(
                                    businessTypes: _businessTypes,
                                    selectedValue: _ramoAtuacao,
                                  ),
                                ),
                              );
                              if (value != null && mounted) {
                                setState(() {
                                  _ramoAtuacao = value;
                                  formState.didChange(value);
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.inputEditableBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: formState.hasError
                                      ? Colors.red
                                      : Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.store, color: Colors.white70),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _getRamoLabel(_ramoAtuacao) ?? 'Ramo de Atuação',
                                      style: TextStyle(
                                        color: _ramoAtuacao != null
                                            ? Colors.white
                                            : Colors.white.withValues(alpha: 0.5),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down,
                                      color: Colors.white70),
                                ],
                              ),
                            ),
                          ),
                          if (formState.hasError) ...[
                            const SizedBox(height: 8),
                            Text(
                              formState.errorText!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // Botão Avançar
                  CustomButton(
                    text: 'Avançar',
                    onPressed: _continuar,
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
    const accented =  'àáâãäåèéêëìíîïòóôõöùúûüýñçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝÑÇ';
    const unaccented = 'aaaaaaeeeeiiiioooooouuuuyncAAAAAAEEEEIIIIOOOOOUUUUYNC';
    return text.split('').map((char) {
      final index = accented.indexOf(char);
      return index >= 0 ? unaccented[index] : char;
    }).join();
  }

  void _filterTypes() {
    final query = _removeAccents(_searchController.text.toLowerCase().trim());
    setState(() {
      if (query.isEmpty) {
        _filteredTypes = List.from(widget.businessTypes);
      } else {
        _filteredTypes = widget.businessTypes
            .where((type) =>
                _removeAccents((type['label'] ?? '').toLowerCase()).contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        onBackPressed: () => Navigator.of(context).pop(widget.selectedValue),
        title: const Text(
          'Selecione o Ramo de Atuação',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Container(
        color: AppTheme.backgroundColor,
        child: Builder(
          builder: (context) {
            // Pouco espaço entre o título e a caixa de busca (mais próximo)
            final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 1;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0, top: topPadding, bottom: 4.0),
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
            );
          },
        ),
      ),
    );
  }
}
