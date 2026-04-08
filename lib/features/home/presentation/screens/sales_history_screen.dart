import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/shared/services/secure_storage_service.dart';
import 'package:neves_capital/shared/helpers/card_brand_detector.dart';
import 'package:neves_capital/shared/helpers/card_brand_image_loader.dart';
import 'package:neves_capital/shared/helpers/format_helpers.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<dynamic> _transactions = [];
  List<dynamic> _filteredTransactions = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Filtros
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minSaleValue;
  double? _maxSaleValue;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Buscar CPF do usuário
      final cpf = await SecureStorageService.getLastCpf();
      if (cpf == null || cpf.isEmpty) {
        setState(() {
          _transactions = [];
          _filteredTransactions = [];
          _isLoading = false;
        });
        return;
      }

      // Buscar userId
      final userData = await FirestoreService.getUserByCpf(cpf);
      if (userData == null || userData['id'] == null) {
        setState(() {
          _transactions = [];
          _filteredTransactions = [];
          _isLoading = false;
        });
        return;
      }

      final userId = userData['id'] as String;

      // Buscar vendas do Firestore (sem filtros - filtragem será feita localmente)
      final sales = await FirestoreService.getUserSales(
        userId: userId,
        limit: 100,
      );

      // Converter formato das vendas para o formato esperado pela UI
      final transactions = sales.map((sale) {
        final createdAt = sale['createdAt'];
        DateTime? saleDate;
        if (createdAt != null) {
          if (createdAt is Timestamp) {
            saleDate = createdAt.toDate();
          } else if (createdAt is DateTime) {
            saleDate = createdAt;
          }
        }

        return {
          'id': sale['saleId'] ?? sale['id'],
          'sale_date': saleDate?.toIso8601String(),
          'created_at': saleDate?.toIso8601String(),
          'card_number': sale['cardNumber'] ?? '',
          'card_last_four': sale['cardLastFour'] ?? '',
          'card_brand': sale['cardBrand'] ?? '',
          'amount': sale['valorCentavos'] ?? 0,
          'gross_amount': sale['valorCentavos'] ?? 0,
          'net_amount': sale['valorLiquidoCentavos'] ?? 0,
          'bank_code': sale['bankCode'],
          'branch': sale['branch'],
          'account': sale['account'],
        };
      }).toList();

      setState(() {
        _transactions = transactions;
        _filteredTransactions = transactions;
        _isLoading = false;
      });
      
      // Aplicar filtros após carregar
      _applyFilters();
    } catch (e) {
      AppLogger.error('Erro ao carregar histórico de vendas', e);
      setState(() {
        _transactions = [];
        _filteredTransactions = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text(
          'Histórico',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTransactions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Espaço abaixo da app bar para o botão Filtros não ficar embaixo do botão voltar
                    SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 24),
                    // Botão Filtros
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _showFilterDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cardColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Filtros',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Lista de transações
                    Expanded(
                      child: _transactions.isEmpty
                          ? Center(
                              child: Align(
                                alignment: const Alignment(0, -0.20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 64,
                                      color: const Color.fromARGB(255, 238, 238, 238),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Nenhuma venda encontrada',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: const Color.fromARGB(255, 219, 217, 217),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                          : RefreshIndicator(
                              onRefresh: _loadTransactions,
                              color: AppTheme.primaryColor,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                itemCount: _filteredTransactions.length,
                                itemBuilder: (context, index) {
                                  final transaction = _filteredTransactions[index];
                                  return _buildTransactionCard(transaction);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    // Extrair dados da transação
    final saleDate = transaction['sale_date'] ?? transaction['created_at'];
    final cardNumber = transaction['card_number'] ?? transaction['card_last_four'] ?? '';
    final cardBrand = transaction['card_brand'] ?? '';
    final saleAmount = transaction['amount'] ?? transaction['gross_amount'] ?? 0.0;
    final netAmount = transaction['net_amount'] ?? (saleAmount * 0.97);
    final bankCode = transaction['bank_code']?.toString().trim();
    final branch = transaction['branch']?.toString().trim();
    final account = transaction['account']?.toString().trim();
    
    // Formatar valores
    final saleAmountFormatted = FormatHelpers.formatCurrency(saleAmount / 100);
    final netAmountFormatted = FormatHelpers.formatCurrency(netAmount / 100);
    
    // Formatar data e horário
    final dateTime = _formatDateTime(saleDate);
    
    // Detectar bandeira: priorizar nome salvo no Firestore (card_brand)
    CardBrand detectedBrand = CardBrand.unknown;
    if (cardBrand.toString().trim().isNotEmpty) {
      detectedBrand = _detectBrandFromString(cardBrand.toString().trim());
    }
    if (detectedBrand == CardBrand.unknown && cardNumber.isNotEmpty) {
      detectedBrand = CardBrandDetector.detectBrand(cardNumber);
    }
    
    // Obter últimos 4 dígitos
    final lastFourDigits = _getLastFourDigits(cardNumber);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data e Horário
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.white),
              children: [
                const TextSpan(
                  text: 'Data e Horário: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: dateTime),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Cartão Utilizado: •••• 1234 [bandeira]
          Row(
            children: [
              const Text(
                'Cartão Utilizado: ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '•••• $lastFourDigits',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              if (detectedBrand != CardBrand.unknown)
                SizedBox(
                  width: 32,
                  height: 20,
                  child: CardBrandImageLoader.getBrandImage(detectedBrand) ?? Text(
                    CardBrandDetector.getBrandName(detectedBrand),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                )
              else if (cardBrand.toString().trim().isNotEmpty)
                Text(
                  cardBrand.toString().trim(),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Valor da Venda
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.white),
              children: [
                const TextSpan(
                  text: 'Valor da Venda: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: saleAmountFormatted),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Valor Líquido
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.white),
              children: [
                const TextSpan(
                  text: 'Valor Líquido: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: netAmountFormatted),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Conta de Destino: Código do Banco/agência/conta com dígito
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.white),
              children: [
                const TextSpan(
                  text: 'Conta de Destino: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: _formatContaDestino(bankCode, branch, account),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formata conta de destino no padrão: código/agência/conta com dígito (ex: 439/0001/56367-9)
  String _formatContaDestino(String? bankCode, String? branch, String? account) {
    if (bankCode == null && branch == null && account == null) return '—';
    if ((bankCode ?? '').isEmpty && (branch ?? '').isEmpty && (account ?? '').isEmpty) {
      return '—';
    }
    final code = bankCode?.trim() ?? '—';
    final ag = branch?.trim() ?? '—';
    final acc = account?.trim() ?? '—';
    return '$code/$ag/$acc';
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return 'Data não disponível';
    
    try {
      final date = DateTime.parse(dateString);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      
      return '$day/$month/$year às $hour:$minute';
    } catch (e) {
      return 'Data inválida';
    }
  }

  String _getLastFourDigits(String cardNumber) {
    if (cardNumber.isEmpty) return '0000';
    
    // Remove espaços e caracteres não numéricos
    final digitsOnly = cardNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length >= 4) {
      return digitsOnly.substring(digitsOnly.length - 4);
    }
    
    return digitsOnly.padLeft(4, '0');
  }

  CardBrand _detectBrandFromString(String brandString) {
    final brandLower = brandString.toLowerCase();
    
    if (brandLower.contains('visa')) return CardBrand.visa;
    if (brandLower.contains('mastercard') || brandLower.contains('master')) return CardBrand.mastercard;
    if (brandLower.contains('amex') || brandLower.contains('american express')) return CardBrand.amex;
    if (brandLower.contains('elo')) return CardBrand.elo;
    if (brandLower.contains('hipercard')) return CardBrand.hipercard;
    if (brandLower.contains('hiper')) return CardBrand.hiper;
    if (brandLower.contains('diners')) return CardBrand.diners;
    if (brandLower.contains('discover')) return CardBrand.discover;
    if (brandLower.contains('jcb')) return CardBrand.jcb;
    
    return CardBrand.unknown;
  }

  void _showFilterDialog() {
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    double? tempMinSaleValue = _minSaleValue;
    double? tempMaxSaleValue = _maxSaleValue;
    
    final startDateController = TextEditingController(
      text: tempStartDate != null ? FormatHelpers.date(tempStartDate) : '',
    );
    final endDateController = TextEditingController(
      text: tempEndDate != null ? FormatHelpers.date(tempEndDate) : '',
    );
    final saleValueController = TextEditingController(
      text: tempMinSaleValue != null ? FormatHelpers.formatCurrency(tempMinSaleValue) : '',
    );
    final maxSaleValueController = TextEditingController(
      text: tempMaxSaleValue != null ? FormatHelpers.formatCurrency(tempMaxSaleValue) : '',
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                // Título
                const Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Período da Venda (date picker ao tocar)
                const Text(
                  'Período da Venda',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Data inicial (De)
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempStartDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: tempEndDate ?? DateTime.now(),
                          locale: const Locale('pt', 'BR'),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary: AppTheme.primaryColor,
                                  onPrimary: Colors.white,
                                  surface: AppTheme.cardColor,
                                  onSurface: Colors.white,
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null && context.mounted) {
                          tempStartDate = picked;
                          startDateController.text = FormatHelpers.date(picked);
                          // Se "De" ficou maior que "Até", ajustar "Até"
                          if (tempEndDate != null && picked.isAfter(tempEndDate!)) {
                            tempEndDate = picked;
                            endDateController.text = FormatHelpers.date(picked);
                          }
                          setDialogState(() {});
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: IgnorePointer(
                        child: TextFormField(
                          controller: startDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'De',
                            hintText: 'dd/mm/aaaa',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
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
                            prefixIcon: const Icon(
                              Icons.calendar_today,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Data final (Até)
                    InkWell(
                      onTap: () async {
                        final initial = tempEndDate ?? tempStartDate ?? DateTime.now();
                        final first = tempStartDate ?? DateTime(2020);
                        final now = DateTime.now();
                        final plus12 = tempStartDate != null
                            ? DateTime(
                                tempStartDate!.year + 1,
                                tempStartDate!.month,
                                tempStartDate!.day,
                              )
                            : now;
                        final last = (tempStartDate != null && plus12.isBefore(now))
                            ? plus12
                            : now;
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: first,
                          lastDate: last,
                          locale: const Locale('pt', 'BR'),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary: AppTheme.primaryColor,
                                  onPrimary: Colors.white,
                                  surface: AppTheme.cardColor,
                                  onSurface: Colors.white,
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null && context.mounted) {
                          endDateController.text = FormatHelpers.date(picked);
                          tempEndDate = picked;
                          setDialogState(() {});
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: IgnorePointer(
                        child: TextFormField(
                          controller: endDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Até',
                            hintText: 'dd/mm/aaaa',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
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
                            prefixIcon: const Icon(
                              Icons.calendar_today,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Busque em intervalos de até 12 meses.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Valor Mínimo da Venda
                const Text(
                  'Valor Mínimo da Venda:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: saleValueController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _CurrencyInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: 'R\$ 0,00',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
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
                    prefixIcon: const Icon(
                      Icons.attach_money,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      // Extrair apenas dígitos e converter para centavos
                      final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                      if (digitsOnly.isNotEmpty) {
                        final intValue = int.parse(digitsOnly);
                        tempMinSaleValue = intValue / 100; // Converter centavos para reais
                      } else {
                        tempMinSaleValue = null;
                      }
                    } else {
                      tempMinSaleValue = null;
                    }
                  },
                ),
                const SizedBox(height: 20),
                
                // Valor Máximo da Venda
                const Text(
                  'Valor Máximo da Venda:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: maxSaleValueController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _CurrencyInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: 'R\$ 0,00',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
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
                    prefixIcon: const Icon(
                      Icons.attach_money,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                      if (digitsOnly.isNotEmpty) {
                        final intValue = int.parse(digitsOnly);
                        tempMaxSaleValue = intValue / 100;
                      } else {
                        tempMaxSaleValue = null;
                      }
                    } else {
                      tempMaxSaleValue = null;
                    }
                  },
                ),
                const SizedBox(height: 24),
                
                // Botões
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Limpar todos os filtros e fechar a tela de pesquisa
                        startDateController.clear();
                        endDateController.clear();
                        saleValueController.clear();
                        maxSaleValueController.clear();
                        
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _minSaleValue = null;
                          _maxSaleValue = null;
                        });
                        
                        _applyFilters();
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Capturar valores finais dos controllers antes de fechar
                        // Data início
                        if (startDateController.text.isNotEmpty && startDateController.text.length == 10) {
                          final parsed = _parseDate(startDateController.text);
                          if (parsed != null) {
                            tempStartDate = parsed;
                          }
                        } else {
                          tempStartDate = null;
                        }
                        
                        // Data fim
                        if (endDateController.text.isNotEmpty && endDateController.text.length == 10) {
                          final parsed = _parseDate(endDateController.text);
                          if (parsed != null) {
                            tempEndDate = parsed;
                          }
                        } else {
                          tempEndDate = null;
                        }
                        
                        // Valor da venda
                        if (saleValueController.text.isNotEmpty) {
                          final digitsOnly = saleValueController.text.replaceAll(RegExp(r'[^\d]'), '');
                          AppLogger.debug('  - Texto do campo valor venda: ${saleValueController.text}');
                          AppLogger.debug('  - Dígitos extraídos: $digitsOnly');
                          if (digitsOnly.isNotEmpty) {
                            final intValue = int.parse(digitsOnly);
                            tempMinSaleValue = intValue / 100;
                            AppLogger.debug('  - Valor calculado (centavos): $intValue');
                            AppLogger.debug('  - Valor em reais: $tempMinSaleValue');
                          } else {
                            tempMinSaleValue = null;
                          }
                        } else {
                          tempMinSaleValue = null;
                        }
                        
                        // Valor máximo da venda
                        if (maxSaleValueController.text.isNotEmpty) {
                          final digitsOnly = maxSaleValueController.text.replaceAll(RegExp(r'[^\d]'), '');
                          if (digitsOnly.isNotEmpty) {
                            final intValue = int.parse(digitsOnly);
                            tempMaxSaleValue = intValue / 100;
                          } else {
                            tempMaxSaleValue = null;
                          }
                        } else {
                          tempMaxSaleValue = null;
                        }
                        
                        setState(() {
                          _startDate = tempStartDate;
                          _endDate = tempEndDate;
                          _minSaleValue = tempMinSaleValue;
                          _maxSaleValue = tempMaxSaleValue;
                        });
                        
                        // Aplicar filtros após atualizar estado
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _applyFilters();
                        });
                        
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Filtrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _applyFilters() {
    AppLogger.debug('Aplicando filtros:');
    AppLogger.debug('  - Data início: $_startDate');
    AppLogger.debug('  - Data fim: $_endDate');
    AppLogger.debug('  - Valor mínimo venda: $_minSaleValue');
    AppLogger.debug('  - Valor máximo venda: $_maxSaleValue');
    AppLogger.debug('  - Total de transações: ${_transactions.length}');
    
    setState(() {
      _filteredTransactions = _transactions.where((transaction) {
        // Filtro de data
        if (_startDate != null || _endDate != null) {
          final saleDate = transaction['sale_date'] ?? transaction['created_at'];
          if (saleDate == null) {
            AppLogger.debug('  ❌ Transação sem data: ${transaction['id']}');
            return false;
          }
          
          try {
            DateTime date;
            if (saleDate is String) {
              date = DateTime.parse(saleDate);
            } else if (saleDate is Timestamp) {
              date = saleDate.toDate();
            } else if (saleDate is DateTime) {
              date = saleDate;
            } else {
              AppLogger.debug('  ❌ Formato de data inválido: ${saleDate.runtimeType}');
              return false;
            }
            
            final dateOnly = DateTime(date.year, date.month, date.day);
            
            if (_startDate != null) {
              final startOnly = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
              // Se a data da transação for antes do início, excluir
              if (dateOnly.isBefore(startOnly)) {
                AppLogger.debug('  ❌ Data antes do início: $dateOnly < $startOnly');
                return false;
              }
            }
            
            if (_endDate != null) {
              final endOnly = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
              // Se a data da transação for depois do fim, excluir
              // Usar isAfter para excluir datas posteriores ao fim
              if (dateOnly.isAfter(endOnly)) {
                AppLogger.debug('  ❌ Data depois do fim: $dateOnly > $endOnly');
                return false;
              }
              // Se for o mesmo dia, incluir (não usar isAfter)
            }
            
            AppLogger.debug('  ✅ Data passou no filtro: $dateOnly');
          } catch (e) {
            AppLogger.error('Erro ao processar data da transação', e);
            return false;
          }
        }
        
        // Filtro valor mínimo da venda: amount >= _minSaleValue
        if (_minSaleValue != null && _minSaleValue! > 0) {
          final saleAmount = transaction['amount'] ?? transaction['gross_amount'] ?? 0.0;
          double amountInReais;
          if (saleAmount is int) {
            amountInReais = saleAmount / 100.0;
          } else if (saleAmount is double) {
            amountInReais = saleAmount;
          } else {
            amountInReais = 0.0;
          }
          if (amountInReais < (_minSaleValue! - 0.01)) {
            return false;
          }
        }
        
        // Filtro valor máximo da venda: amount <= _maxSaleValue
        if (_maxSaleValue != null && _maxSaleValue! > 0) {
          final saleAmount = transaction['amount'] ?? transaction['gross_amount'] ?? 0.0;
          double amountInReais;
          if (saleAmount is int) {
            amountInReais = saleAmount / 100.0;
          } else if (saleAmount is double) {
            amountInReais = saleAmount;
          } else {
            amountInReais = 0.0;
          }
          if (amountInReais > (_maxSaleValue! + 0.01)) {
            return false;
          }
        }
        
        AppLogger.debug('  ✅ Transação passou em todos os filtros');
        return true;
      }).toList();
      
      AppLogger.debug('  - Transações filtradas: ${_filteredTransactions.length}');
    });
  }

  /// Parse de data no formato DD/MM/YYYY
  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return null;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900 || year > 2100) {
        return null;
      }
      
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }
}

/// Formatter para data no formato DD/MM/YYYY
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    var formatted = '';
    for (var i = 0; i < digitsOnly.length && i < 8; i++) {
      if (i == 2 || i == 4) {
        formatted += '/';
      }
      formatted += digitsOnly[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatter para valores monetários
/// Formata enquanto o usuário digita, interpretando os dígitos como centavos
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove tudo que não é dígito
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Limitar a 7 dígitos (máximo R$99.999,99 = 5 inteiros + 2 decimais)
    final limitedDigits = digitsOnly.length > 7 
        ? digitsOnly.substring(0, 7) 
        : digitsOnly;
    
    final intValue = int.parse(limitedDigits);
    final formatted = FormatHelpers.formatCurrency(intValue / 100);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
