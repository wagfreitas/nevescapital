import 'package:flutter/material.dart';
import 'package:neves_capital/shared/components/custom_button.dart';
import 'package:neves_capital/shared/components/custom_loading.dart';
import 'package:neves_capital/shared/helpers/format_helpers.dart';
import 'package:neves_capital/shared/helpers/card_brand_detector.dart';
import 'package:neves_capital/shared/helpers/card_brand_image_loader.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
// TODO: Reativar quando implementar retorno do gateway:
// import 'package:neves_capital/features/payment/data/services/pagarme_service.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/shared/services/secure_storage_service.dart';
import 'package:neves_capital/shared/data/brazilian_banks.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import '../helpers/payment_step_helper.dart';
import 'sale_completion_screen.dart';
// import 'payment_result_screen.dart'; // TODO: Reativar quando implementar retorno do gateway

/// Tela 5: Resumo da operação
class PaymentStep5Screen extends StatefulWidget {
  final String nomeEstabelecimento;
  final String ramoAtuacao;
  final int valorCentavos;
  final String chavePix;
  final String tipoChavePix;
  final String nomeTitular;
  final String numeroCartao;
  final String cvv;
  final String vencimento;

  const PaymentStep5Screen({
    super.key,
    required this.nomeEstabelecimento,
    required this.ramoAtuacao,
    required this.valorCentavos,
    required this.chavePix,
    required this.tipoChavePix,
    required this.nomeTitular,
    required this.numeroCartao,
    required this.cvv,
    required this.vencimento,
  });

  @override
  State<PaymentStep5Screen> createState() => _PaymentStep5ScreenState();
}

class _PaymentStep5ScreenState extends State<PaymentStep5Screen> {
  bool _isProcessing = false;
  bool _hasAccount = false;
  bool _isLoadingAccount = true;
  bool _isLoadingBankData = true;
  
  // Dados bancários
  String? _bankName;
  String? _bankCode;
  String? _branch;
  String? _account;

  @override
  void initState() {
    super.initState();
    _checkUserAccount();
    _loadBankAccountData();
  }

  Future<void> _checkUserAccount() async {
    final hasAccount = await PaymentStepHelper.hasUserAccount();
    setState(() {
      _hasAccount = hasAccount;
      _isLoadingAccount = false;
    });
  }

  /// Carregar dados bancários do usuário
  Future<void> _loadBankAccountData() async {
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
        final bankCode = bankData['bankCode'] as String?;
        if (bankCode != null) {
          final bank = BrazilianBanks.findByCode(bankCode);
          if (bank != null) {
            setState(() {
              _bankCode = bankCode;
              _bankName = bank.name;
              _branch = bankData['branch'] as String? ?? '';
              _account = bankData['account'] as String? ?? '';
            });
          }
        }
        
        AppLogger.info('✅ Dados bancários carregados com sucesso no resumo da venda');
      } else {
        AppLogger.info('Dados bancários não encontrados');
      }
    } catch (e) {
      AppLogger.error('Erro ao carregar dados bancários no resumo da venda', e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBankData = false;
        });
      }
    }
  }

  Future<void> _concluirVenda() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Buscar userId do usuário atual
      final cpf = await SecureStorageService.getLastCpf();
      if (cpf == null || cpf.isEmpty) {
        throw Exception('CPF não encontrado. Faça login novamente.');
      }

      final userData = await FirestoreService.getUserByCpf(cpf);
      if (userData == null || userData['id'] == null) {
        throw Exception('Usuário não encontrado.');
      }

      final userId = userData['id'] as String;

      // 2. Detectar bandeira e obter últimos 4 dígitos do cartão
      final detectedBrand = CardBrandDetector.detectBrand(widget.numeroCartao);
      final cardBrand = CardBrandDetector.getBrandName(detectedBrand);
      final digitsOnly = widget.numeroCartao.replaceAll(RegExp(r'[^\d]'), '');
      final cardLastFour = digitsOnly.length >= 4 
          ? digitsOnly.substring(digitsOnly.length - 4)
          : '';
      final cardNumberDisplay = '•••• $cardLastFour';

      // 3. Salvar venda no Firestore (inclui conta de destino para o histórico)
      final saleId = await FirestoreService.saveSale(
        userId: userId,
        valorCentavos: widget.valorCentavos,
        nomeEstabelecimento: widget.nomeEstabelecimento,
        ramoAtuacao: widget.ramoAtuacao,
        cardBrand: cardBrand,
        cardLastFour: cardLastFour,
        cardNumber: cardNumberDisplay,
        bankCode: _bankCode,
        branch: _branch,
        account: _account,
        status: 'completed',
      );

      if (saleId == null) {
        throw Exception('Erro ao salvar venda');
      }

      AppLogger.info('✅ Venda cadastrada com sucesso: $saleId');

      // TODO: Processar pagamento com gateway quando implementar retorno
      // final pagarmeService = PagarmeService();
      // final resultado = await pagarmeService.processarPagamentoCartao(...);

      if (!mounted) return;

      // 4. Navegar para tela de conclusão da venda
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SaleCompletionScreen(),
        ),
      );
      
      // TODO: Quando implementar retorno do gateway, usar PaymentResultScreen
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => PaymentResultScreen(
      //       sucesso: resultado['success'] ?? false,
      //       mensagem: resultado['message'] ?? 'Erro desconhecido',
      //       transactionId: resultado['transactionId'],
      //       valorCentavos: widget.valorCentavos,
      //       nomeEstabelecimento: widget.nomeEstabelecimento,
      //     ),
      //   ),
      // );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar pagamento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final valorFormatado = FormatHelpers.formatCurrency(widget.valorCentavos / 100);
    final valorLiquido = (widget.valorCentavos * 0.97) / 100;
    final valorLiquidoFormatado = FormatHelpers.formatCurrency(valorLiquido);
    
    // Calcular passo atual baseado se tem conta ou não
    final currentStep = PaymentStepHelper.calculateCurrentStep(5, _hasAccount);
    final totalSteps = PaymentStepHelper.getTotalSteps(_hasAccount);
    
    // Detectar bandeira do cartão (mostrar somente se tiver 6+ dígitos)
    final digitsOnly = widget.numeroCartao.replaceAll(RegExp(r'\D'), '');
    final showBrand = digitsOnly.length >= 6;
    final detectedBrand = showBrand ? CardBrandDetector.detectBrand(widget.numeroCartao) : CardBrand.unknown;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text(
          'Resumo da Venda',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: PaymentStepHelper.buildProgressIndicator(currentStep, totalSteps),
          ),
        ),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomLoading(),
                  SizedBox(height: 24),
                  Text(
                    'Processando pagamento...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aguarde enquanto validamos os dados',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : (_isLoadingAccount || _isLoadingBankData)
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                )
              : Container(
                  color: AppTheme.backgroundColor,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Conteúdo rolável (altura inicial igual às outras: 40px do fim da app bar)
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              24.0,
                              MediaQuery.of(context).padding.top + kToolbarHeight + 28 + 40,
                              24.0,
                              24.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Card de resumo
                                Card(
                                elevation: 2,
                                color: AppTheme.cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Valor da Venda
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'VALOR DA VENDA',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            readOnly: true,
                                            initialValue: valorFormatado,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            decoration: InputDecoration(
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
                                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // Valor Líquido (texto simples abaixo do campo)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Valor Líquido: $valorLiquidoFormatado',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      
                                      // Meio de Pagamento
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'MEIO DE PAGAMENTO',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppTheme.inputEditableBackgroundColor,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.2),
                                              ),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                            child: Row(
                                              children: [
                                                Text(
                                                  _getCardDisplay(widget.numeroCartao),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                if (showBrand && CardBrandImageLoader.getBrandImage(detectedBrand) != null)
                                                  SizedBox(
                                                    width: 40,
                                                    height: 24,
                                                    child: CardBrandImageLoader.getBrandImage(detectedBrand),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      // Título DADOS BANCÁRIOS à esquerda
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'DADOS BANCÁRIOS',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Dados Bancários
                                      _buildBankAccountInfo(),
                                    ],
                                  ),
                                ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                        // Botão Finalizar a Venda (mesma posição do Avançar: 24px acima e abaixo)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
                          child: CustomButton(
                            text: 'Finalizar a Venda',
                            icon: Icons.lock,
                            onPressed: _concluirVenda,
                            capitalizeText: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// Obter exibição do cartão no formato: "•••• YYYY"
  /// onde •••• são 4 bolinhas e YYYY são os últimos 4 dígitos
  String _getCardDisplay(String numeroCartao) {
    // Remove espaços e caracteres não numéricos
    final digitsOnly = numeroCartao.replaceAll(RegExp(r'[^\d]'), '');
    
    // Se tiver pelo menos 4 dígitos, mostra os últimos 4
    if (digitsOnly.length >= 4) {
      final ultimosDigitos = digitsOnly.substring(digitsOnly.length - 4);
      return '•••• $ultimosDigitos';
    }
    
    // Caso contrário, mostra apenas as bolinhas
    return '••••';
  }

  /// Construir widget para exibir dados bancários
  Widget _buildBankAccountInfo() {
    if (_bankName == null || _branch == null || _account == null) {
      return const SizedBox.shrink();
    }

    // Formatar nome do banco com código: "001 - BANCO DO BRASIL S.A."
    final bankDisplayName = _bankCode != null 
        ? '$_bankCode - ${_bankName!.toUpperCase()}'
        : _bankName!.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo Banco: uma linha quando cabe, cresce se o nome for longo
        TextFormField(
          readOnly: true,
          initialValue: bankDisplayName,
          minLines: 1,
          maxLines: null,
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
              size: 24,
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
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Campo Conta
        TextFormField(
          readOnly: true,
          initialValue: _account,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            labelText: 'Conta com Dígito',
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            prefixIcon: const Icon(
              Icons.account_balance_wallet,
              color: AppTheme.textSecondary,
              size: 24,
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
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Campo Agência
        TextFormField(
          readOnly: true,
          initialValue: _branch,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            labelText: 'Agência',
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            prefixIcon: const Icon(
              Icons.location_on,
              color: AppTheme.textSecondary,
              size: 24,
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
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
        ),
      ],
    );
  }

}
