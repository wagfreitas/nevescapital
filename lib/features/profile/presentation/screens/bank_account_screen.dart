import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/components/glass_app_bar.dart';
import '../../../../shared/components/custom_button.dart';
import '../../../../shared/data/brazilian_banks.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/services/firestore_service.dart';
import '../../../../shared/services/secure_storage_service.dart';

/// Tela para cadastro/edição de dados bancários
/// Conforme wireframe: "Altere a Conta de Recebimento das Vendas"
class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankController = TextEditingController();
  final _branchController = TextEditingController();
  final _accountController = TextEditingController();
  
  BrazilianBank? _selectedBank;
  bool _isLoading = false;
  bool _isLoadingData = false;
  
  // Valores originais para rastrear mudanças
  String? _originalBankCode;
  String _originalBranch = '';
  String _originalAccount = '';
  bool _hasChanges = false;
  
  // Focus nodes para gerenciar o foco
  final _bankFocusNode = FocusNode();
  final _branchFocusNode = FocusNode();
  final _accountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadBankAccountData();
    
    // Adicionar listeners para rastrear mudanças
    _branchController.addListener(_checkForChanges);
    _accountController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _branchController.removeListener(_checkForChanges);
    _accountController.removeListener(_checkForChanges);
    _bankController.dispose();
    _branchController.dispose();
    _accountController.dispose();
    _bankFocusNode.dispose();
    _branchFocusNode.dispose();
    _accountFocusNode.dispose();
    super.dispose();
  }
  
  /// Verificar se houve mudanças nos campos
  void _checkForChanges() {
    final currentBankCode = _selectedBank?.code;
    final currentBranch = _branchController.text.trim();
    final currentAccount = _accountController.text.trim();
    
    final hasChanges = currentBankCode != _originalBankCode ||
        currentBranch != _originalBranch ||
        currentAccount != _originalAccount;
    
    if (_hasChanges != hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  /// Carregar dados bancários existentes (se houver)
  Future<void> _loadBankAccountData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // 1. Buscar CPF do SecureStorage
      final cpf = await SecureStorageService.getLastCpf();
      if (cpf == null || cpf.isEmpty) {
        throw Exception('CPF não encontrado. Faça login novamente.');
      }

      // 2. Buscar dados do usuário no Firestore
      final userData = await FirestoreService.getUserByCpf(cpf);
      if (userData == null || userData['id'] == null) {
        throw Exception('Usuário não encontrado.');
      }

      final userId = userData['id'] as String;

      // 3. Buscar dados bancários
      final bankData = await FirestoreService.getBankAccount(userId);
      
      if (bankData != null) {
        // Preencher campos com dados existentes
        final bankCode = bankData['bankCode'] as String?;
        if (bankCode != null) {
          _selectedBank = BrazilianBanks.findByCode(bankCode);
          if (_selectedBank != null) {
            _bankController.text = _selectedBank!.displayName;
          }
        }
        
        _branchController.text = bankData['branch'] as String? ?? '';
        _accountController.text = bankData['account'] as String? ?? '';
        
        // Armazenar valores originais
        _originalBankCode = bankCode;
        _originalBranch = _branchController.text.trim();
        _originalAccount = _accountController.text.trim();
        _hasChanges = false;
        
        AppLogger.info('✅ Dados bancários carregados com sucesso');
      } else {
        // Se não há dados, valores originais são vazios
        _originalBankCode = null;
        _originalBranch = '';
        _originalAccount = '';
        _hasChanges = false;
        
        AppLogger.info('Dados bancários não encontrados - será criado novo registro');
      }
    } catch (e) {
      AppLogger.error('Erro ao carregar dados bancários', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  /// Abrir tela de busca de banco
  Future<void> _openBankSearch() async {
    final selected = await Navigator.push<BrazilianBank>(
      context,
      MaterialPageRoute(
        builder: (context) => const _BankSearchScreen(),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedBank = selected;
        _bankController.text = selected.displayName;
      });
      _checkForChanges();
    }
  }

  /// Salvar dados bancários
  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que um banco foi selecionado
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um banco'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Buscar CPF do SecureStorage
      final cpf = await SecureStorageService.getLastCpf();
      if (cpf == null || cpf.isEmpty) {
        throw Exception('CPF não encontrado. Faça login novamente.');
      }

      // 2. Buscar dados do usuário no Firestore para obter userId
      final userData = await FirestoreService.getUserByCpf(cpf);
      if (userData == null || userData['id'] == null) {
        throw Exception('Usuário não encontrado.');
      }

      final userId = userData['id'] as String;

      // 3. Salvar dados bancários
      final success = await FirestoreService.saveBankAccount(
        userId: userId,
        bankCode: _selectedBank!.code,
        bankName: _selectedBank!.name,
        branch: _branchController.text.trim(),
        branchDigit: null, // Removido campo dígito
        account: _accountController.text.trim(),
        accountDigit: null, // Por enquanto não temos campo separado para dígito da conta
      );

      if (!mounted) return;

      if (success) {
        // Atualizar valores originais após salvar
        _originalBankCode = _selectedBank?.code;
        _originalBranch = _branchController.text.trim();
        _originalAccount = _accountController.text.trim();
        _hasChanges = false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados bancários salvos com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Aguardar o SnackBar desaparecer antes de navegar
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Falha ao salvar dados bancários');
      }
    } catch (e) {
      AppLogger.error('Erro ao salvar dados bancários', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text(
          'Dados Bancários',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24.0,
                  MediaQuery.of(context).padding.top + kToolbarHeight + 40,
                  24.0,
                  0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Campo: Banco
                      _buildBankField(),
                      const SizedBox(height: 24),

                      // Campo: Agência
                      _buildTextField(
                        label: 'Agência',
                        controller: _branchController,
                        focusNode: _branchFocusNode,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        prefixIcon: Icons.location_on,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe sua Agência';
                          }
                          if (value.length != 4) {
                            return 'Agência deve ter 4 dígitos';
                          }
                          return null;
                        },
                        helpText: 'Informe sua Agência',
                      ),
                      const SizedBox(height: 24),

                      // Campo: Conta
                      _buildTextField(
                        label: 'Conta com Dígito',
                        controller: _accountController,
                        focusNode: _accountFocusNode,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        prefixIcon: Icons.account_balance_wallet,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe sua Conta com Dígito';
                          }
                          return null;
                        },
                        helpText: 'Informe sua Conta com Dígito',
                      ),
                      const SizedBox(height: 32),

                      // Aviso sobre regras de preenchimento
                      _buildRulesWarning(),
                      const Spacer(),
                      // Botão Atualizar (altura padrão: 24px abaixo)
                      CustomButton(
                        text: 'Atualizar',
                        onPressed: (_isLoading || !_hasChanges) ? null : _handleConfirm,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// Construir aviso de regras de preenchimento
  Widget _buildRulesWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.inputEditableBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ATENÇÃO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'A conta bancária para recebimento das vendas deve ser de titularidade do vendedor.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: 0.0,
                    wordSpacing: 0.0,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construir campo de banco customizado
  Widget _buildBankField() {
    return GestureDetector(
      onTap: _openBankSearch,
      child: TextFormField(
        controller: _bankController,
        readOnly: true,
        onTap: _openBankSearch,
        maxLines: null,
        minLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: 'Banco',
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: const Icon(
            Icons.account_balance,
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
    );
  }

  /// Construir campo de texto customizado com tema escuro
  /// Label funciona como placeholder e sobe quando o campo recebe foco
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType? keyboardType,
    int? maxLength,
    IconData? prefixIcon,
    TextAlign textAlign = TextAlign.start,
    String? Function(String?)? validator,
    String? helpText,
    List<TextInputFormatter>? inputFormatters,
  }) {
      return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      keyboardAppearance: Brightness.dark, // Teclado escuro para uniformidade
      maxLength: maxLength,
      textAlign: textAlign,
      inputFormatters: inputFormatters ??
          (keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null),
      style: const TextStyle(color: Colors.white),
      onChanged: (value) => _checkForChanges(),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppTheme.textSecondary)
            : null,
        hintText: helpText,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: AppTheme.inputEditableBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.errorColor,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.errorColor,
            width: 2,
          ),
        ),
        counterText: '',
      ),
    );
  }
}

/// Tela de busca de banco
class _BankSearchScreen extends StatefulWidget {
  const _BankSearchScreen();

  @override
  State<_BankSearchScreen> createState() => _BankSearchScreenState();
}

class _BankSearchScreenState extends State<_BankSearchScreen> {
  final _searchController = TextEditingController();
  List<BrazilianBank> _filteredBanks = BrazilianBanks.getAllBanks();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      _filteredBanks = BrazilianBanks.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        onBackPressed: () => Navigator.of(context).pop(),
        title: const Text(
          'Selecione o Banco',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Container(
        color: AppTheme.backgroundColor,
        child: Builder(
          builder: (context) {
            // Mesmo padrão da tela Ramo: pouco espaço entre título e caixa de busca
            final topPadding = MediaQuery.of(context).padding.top;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0, top: topPadding, bottom: 4.0),
                  child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Digite o nome ou código do banco',
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
                child: _filteredBanks.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum banco encontrado',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _filteredBanks.length,
                        itemBuilder: (context, index) {
                          final bank = _filteredBanks[index];
                          return ListTile(
                            title: Text(
                              bank.displayName,
                              style: const TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              Navigator.of(context).pop(bank);
                            },
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
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

