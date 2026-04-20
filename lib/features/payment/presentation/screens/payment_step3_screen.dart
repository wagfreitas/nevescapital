import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/shared/components/custom_button.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:neves_capital/shared/data/brazilian_banks.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/shared/services/secure_storage_service.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import '../helpers/payment_step_helper.dart';
import 'payment_step4_screen.dart';

/// Tela 3: Dados Bancários - Conforme wireframe
class PaymentStep3Screen extends StatefulWidget {
  final String nomeEstabelecimento;
  final String ramoAtuacao;
  final int valorCentavos;
  final bool hasAccount;

  const PaymentStep3Screen({
    super.key,
    required this.nomeEstabelecimento,
    required this.ramoAtuacao,
    required this.valorCentavos,
    required this.hasAccount,
  });

  @override
  State<PaymentStep3Screen> createState() => _PaymentStep3ScreenState();
}

class _PaymentStep3ScreenState extends State<PaymentStep3Screen> {
  final _formKey = GlobalKey<FormState>();
  final _bankController = TextEditingController();
  final _branchController = TextEditingController();
  final _accountController = TextEditingController();
  
  BrazilianBank? _selectedBank;
  bool _isLoadingBankData = true;
  bool _isSaving = false;

  // Armazenar dados originais para comparar alterações
  String? _originalBankCode;
  String _originalBranch = '';
  String _originalAccount = '';
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _branchController.addListener(_checkForChanges);
    _accountController.addListener(_checkForChanges);
    _loadBankAccountData();
  }

  /// Habilita o botão "Avançar" somente quando há alterações nos dados bancários.
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
      _isLoadingBankData = true;
    });

    try {
      // 1. Buscar CPF do SecureStorage
      final cpf = await SecureStorageService.getLastCpf();
      if (cpf == null || cpf.isEmpty) {
        AppLogger.warning('CPF não encontrado - dados bancários não serão carregados');
        setState(() {
          _isLoadingBankData = false;
        });
        return;
      }

      // 2. Buscar dados do usuário no Firestore
      final userData = await FirestoreService.getUserByCpf(cpf);
      if (userData == null || userData['id'] == null) {
        AppLogger.warning('Usuário não encontrado - dados bancários não serão carregados');
        setState(() {
          _isLoadingBankData = false;
        });
        return;
      }

      final userId = userData['id'] as String;

      // 3. Buscar dados bancários
      final bankData = await FirestoreService.getBankAccount(userId);
      
      if (bankData != null && mounted) {
        // Preencher campos com dados existentes
        final bankCode = bankData['bankCode'] as String?;
        if (bankCode != null) {
          _selectedBank = BrazilianBanks.findByCode(bankCode);
          if (_selectedBank != null) {
            _bankController.text = _selectedBank!.displayName;
          }
        }
        
        final branch = bankData['branch'] as String? ?? '';
        final account = bankData['account'] as String? ?? '';
        
        _branchController.text = branch;
        _accountController.text = account;
        
        // Armazenar dados originais para comparação
        setState(() {
          _originalBankCode = bankCode;
          _originalBranch = branch;
          _originalAccount = account;
          _hasChanges = false;
        });

        AppLogger.info('✅ Dados bancários carregados com sucesso no fluxo de pagamento');
      } else {
        AppLogger.info('Dados bancários não encontrados - usuário precisará preencher');
        setState(() {
          _originalBankCode = null;
          _originalBranch = '';
          _originalAccount = '';
          _hasChanges = false;
        });
      }
    } catch (e) {
      AppLogger.error('Erro ao carregar dados bancários no fluxo de pagamento', e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBankData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _branchController.removeListener(_checkForChanges);
    _accountController.removeListener(_checkForChanges);
    _bankController.dispose();
    _branchController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  void _openBankSearch() {
    showDialog(
      context: context,
      builder: (context) => _BankSearchDialog(
        onBankSelected: (bank) {
          setState(() {
            _selectedBank = bank;
            _bankController.text = bank.displayName;
          });
          _checkForChanges();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _continuar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um banco'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar se houve alterações nos dados bancários
    final currentBankCode = _selectedBank!.code;
    final currentBranch = _branchController.text.trim();
    final currentAccount = _accountController.text.trim();

    // Se houver alterações, salvar na collection de user
    if (_hasChanges) {
      setState(() {
        _isSaving = true;
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

        // 3. Salvar dados bancários atualizados
        final success = await FirestoreService.saveBankAccount(
          userId: userId,
          bankCode: currentBankCode,
          bankName: _selectedBank!.name,
          branch: currentBranch,
          branchDigit: null,
          account: currentAccount,
          accountDigit: null,
        );

        if (!mounted) return;

        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao salvar dados bancários. Tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSaving = false;
          });
          return;
        }

        AppLogger.info('✅ Dados bancários atualizados com sucesso no fluxo de vendas');
        
        // Atualizar dados originais após salvar
        setState(() {
          _originalBankCode = currentBankCode;
          _originalBranch = currentBranch;
          _originalAccount = currentAccount;
          _hasChanges = false;
        });
      } catch (e) {
        AppLogger.error('Erro ao salvar dados bancários no fluxo de vendas', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar dados: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSaving = false;
          });
        }
        return;
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }

    // Navegar para próxima tela
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentStep4Screen(
          nomeEstabelecimento: widget.nomeEstabelecimento,
          ramoAtuacao: widget.ramoAtuacao,
          valorCentavos: widget.valorCentavos,
          chavePix: '', // Não usado mais, mas mantido para compatibilidade
          tipoChavePix: 'conta_bancaria',
          hasAccount: widget.hasAccount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calcular passo atual baseado se tem conta ou não
    final currentStep = PaymentStepHelper.calculateCurrentStep(3, widget.hasAccount);
    final totalSteps = PaymentStepHelper.getTotalSteps(widget.hasAccount);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: GlassAppBar(
        title: const Text(
          'Dados Bancários',
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
            child: PaymentStepHelper.buildProgressIndicator(currentStep, totalSteps),
          ),
        ),
      ),
      body: _isLoadingBankData
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : KeyboardDismissWrapper(
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
                              // Texto de instrução
                              const Text(
                                'Confirme a conta em que receberá a venda:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Campo: Banco
                              GestureDetector(
                                onTap: _openBankSearch,
                                child: _buildBankField(),
                              ),
                              const SizedBox(height: 24),

                              // Campo: Agência
                              _buildTextField(
                                label: 'Agência',
                                controller: _branchController,
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
                              ),
                              const SizedBox(height: 24),

                              // Campo: Conta com dígito
                              _buildTextField(
                                label: 'Conta com Dígito',
                                controller: _accountController,
                                keyboardType: TextInputType.number,
                                maxLength: 10,
                                prefixIcon: Icons.account_balance_wallet,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Informe sua Conta com Dígito';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),

                              // Aviso sobre regras de preenchimento
                              _buildRulesWarning(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: _isSaving ? 'Salvando...' : 'Avançar',
                      onPressed: _isSaving ? null : _continuar,
                    ),
                    const SizedBox(height: 24),
                  ],
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

  Widget _buildBankField() {
    return TextFormField(
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
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required int maxLength,
    required IconData prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      keyboardAppearance: Brightness.dark,
      maxLength: maxLength,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        prefixIcon: Icon(prefixIcon, color: AppTheme.textSecondary),
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
          borderSide: BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        counterText: '',
      ),
      validator: validator,
    );
  }
}

/// Dialog para busca de bancos
class _BankSearchDialog extends StatefulWidget {
  final Function(BrazilianBank) onBankSelected;

  const _BankSearchDialog({required this.onBankSelected});

  @override
  State<_BankSearchDialog> createState() => _BankSearchDialogState();
}

class _BankSearchDialogState extends State<_BankSearchDialog> {
  final _searchController = TextEditingController();
  List<BrazilianBank> _filteredBanks = BrazilianBanks.getAllBanks();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterBanks);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterBanks);
    _searchController.dispose();
    super.dispose();
  }

  void _filterBanks() {
    final query = _searchController.text.trim();
    setState(() {
      _filteredBanks = BrazilianBanks.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A2B1F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Selecione o Banco',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search field — teclado já aberto ao abrir o diálogo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar banco...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.inputEditableBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // List
            Expanded(
              child: ListView.builder(
                itemCount: _filteredBanks.length,
                itemBuilder: (context, index) {
                  final bank = _filteredBanks[index];
                  return ListTile(
                    title: Text(
                      bank.displayName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      widget.onBankSelected(bank);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
