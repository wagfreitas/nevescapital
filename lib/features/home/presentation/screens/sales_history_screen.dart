import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/shared/services/secure_storage_service.dart';
import 'package:neves_capital/shared/helpers/card_brand_detector.dart';
import 'package:neves_capital/shared/helpers/card_brand_image_loader.dart';
import 'package:neves_capital/shared/helpers/format_helpers.dart';
import 'package:neves_capital/shared/components/bottom_tab_bar.dart';
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
  double? _minNetValue;

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
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: null,
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
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhuma venda encontrada',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Suas vendas aparecerão aqui',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
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
      bottomNavigationBar: BottomTabBar(
        isVendasActive: true,
        onVendasTap: () {
          Navigator.of(context).pop();
        },
        onContaTap: () {
          // Navegar para tela de conta se necessário
          // Por enquanto, apenas volta
          Navigator.of(context).pop();
        },
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
    
    // Formatar valores
    final saleAmountFormatted = FormatHelpers.formatCurrency(saleAmount / 100);
    final netAmountFormatted = FormatHelpers.formatCurrency(netAmount / 100);
    
    // Formatar data e horário
    final dateTime = _formatDateTime(saleDate);
    
    // Detectar bandeira do cartão
    CardBrand detectedBrand = CardBrand.unknown;
    if (cardNumber.isNotEmpty) {
      detectedBrand = CardBrandDetector.detectBrand(cardNumber);
    } else if (cardBrand.isNotEmpty) {
      // Tentar detectar pela string da bandeira
      detectedBrand = _detectBrandFromString(cardBrand);
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
          Text(
            'Data e Horário: $dateTime',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          
          // Cartão Utilizado
          Row(
            children: [
              const Text(
                'Cartão Utilizado: ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              Text(
                '•••• $lastFourDigits',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              if (CardBrandImageLoader.getBrandImage(detectedBrand) != null)
                SizedBox(
                  width: 32,
                  height: 20,
                  child: CardBrandImageLoader.getBrandImage(detectedBrand),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Valor da Venda
          Text(
            'Valor da Venda: $saleAmountFormatted',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          
          // Valor Líquido
          Text(
            'Valor Líquido: $netAmountFormatted',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
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
    if (brandLower.contains('diners')) return CardBrand.diners;
    if (brandLower.contains('discover')) return CardBrand.discover;
    if (brandLower.contains('jcb')) return CardBrand.jcb;
    
    return CardBrand.unknown;
  }

  void _showFilterDialog() {
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    double? tempMinSaleValue = _minSaleValue;
    double? tempMinNetValue = _minNetValue;
    
    final startDateController = TextEditingController(
      text: tempStartDate != null ? FormatHelpers.date(tempStartDate) : '',
    );
    final endDateController = TextEditingController(
      text: tempEndDate != null ? FormatHelpers.date(tempEndDate) : '',
    );
    final saleValueController = TextEditingController(
      text: tempMinSaleValue != null ? FormatHelpers.formatCurrency(tempMinSaleValue) : '',
    );
    final netValueController = TextEditingController(
      text: tempMinNetValue != null ? FormatHelpers.formatCurrency(tempMinNetValue) : '',
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
            child: Column(
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
                
                // Data exata ou período
                const Text(
                  'Data exata ou período da venda:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: startDateController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                          _DateInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          hintText: 'DD/MM/AAAA',
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
                            Icons.calendar_today,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          if (value.length == 10) {
                            final parsed = _parseDate(value);
                            if (parsed != null) {
                              tempStartDate = parsed;
                            }
                          } else {
                            tempStartDate = null;
                          }
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'a',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: endDateController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                          _DateInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          hintText: 'DD/MM/AAAA',
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
                            Icons.calendar_today,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          if (value.length == 10) {
                            final parsed = _parseDate(value);
                            if (parsed != null) {
                              tempEndDate = parsed;
                            }
                          } else {
                            tempEndDate = null;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Valor da Venda
                const Text(
                  'Valor da Venda:',
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
                
                // Valor Líquido da Venda
                const Text(
                  'Valor Líquido da Venda:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: netValueController,
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
                        tempMinNetValue = intValue / 100; // Converter centavos para reais
                      } else {
                        tempMinNetValue = null;
                      }
                    } else {
                      tempMinNetValue = null;
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
                        // Limpar controllers
                        startDateController.clear();
                        endDateController.clear();
                        saleValueController.clear();
                        netValueController.clear();
                        
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _minSaleValue = null;
                          _minNetValue = null;
                        });
                        
                        // Aplicar filtros após limpar
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _applyFilters();
                        });
                        
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Limpar',
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
                        
                        // Valor líquido
                        if (netValueController.text.isNotEmpty) {
                          final digitsOnly = netValueController.text.replaceAll(RegExp(r'[^\d]'), '');
                          AppLogger.debug('  - Texto do campo valor líquido: ${netValueController.text}');
                          AppLogger.debug('  - Dígitos extraídos: $digitsOnly');
                          if (digitsOnly.isNotEmpty) {
                            final intValue = int.parse(digitsOnly);
                            tempMinNetValue = intValue / 100;
                            AppLogger.debug('  - Valor calculado (centavos): $intValue');
                            AppLogger.debug('  - Valor em reais: $tempMinNetValue');
                          } else {
                            tempMinNetValue = null;
                          }
                        } else {
                          tempMinNetValue = null;
                        }
                        
                        // Atualizar valores antes de aplicar filtros
                        setState(() {
                          _startDate = tempStartDate;
                          _endDate = tempEndDate;
                          _minSaleValue = tempMinSaleValue;
                          _minNetValue = tempMinNetValue;
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
    AppLogger.debug('  - Valor mínimo líquido: $_minNetValue');
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
        
        // Filtro de valor da venda (filtro por igualdade com tolerância)
        if (_minSaleValue != null && _minSaleValue! > 0) {
          final saleAmount = transaction['amount'] ?? transaction['gross_amount'] ?? 0.0;
          // Converter para reais (valores vêm em centavos do Firestore)
          double amountInReais;
          if (saleAmount is int) {
            amountInReais = saleAmount / 100.0;
          } else if (saleAmount is double) {
            // Se já estiver em reais, usar diretamente
            amountInReais = saleAmount;
          } else {
            amountInReais = 0.0;
          }
          
          AppLogger.debug('  - Transação ID: ${transaction['id']}');
          AppLogger.debug('  - Valor original: $saleAmount (tipo: ${saleAmount.runtimeType})');
          AppLogger.debug('  - Valor em reais: $amountInReais');
          AppLogger.debug('  - Valor filtro: ${_minSaleValue!}');
          
          // Filtro por igualdade com tolerância de 0.01 para evitar problemas de ponto flutuante
          final difference = (amountInReais - _minSaleValue!).abs();
          if (difference > 0.01) {
            AppLogger.debug('  ❌ Valor da venda não corresponde: $amountInReais != ${_minSaleValue!} (diferença: $difference)');
            return false;
          }
          AppLogger.debug('  ✅ Valor da venda passou no filtro (igualdade)');
        }
        
        // Filtro de valor líquido (filtro por igualdade com tolerância)
        if (_minNetValue != null && _minNetValue! > 0) {
          final netAmount = transaction['net_amount'] ?? 0.0;
          // Converter para reais (valores vêm em centavos do Firestore)
          double netInReais;
          if (netAmount is int) {
            netInReais = netAmount / 100.0;
          } else if (netAmount is double) {
            // Se já estiver em reais, usar diretamente
            netInReais = netAmount;
          } else {
            netInReais = 0.0;
          }
          
          AppLogger.debug('  - Valor líquido original: $netAmount (tipo: ${netAmount.runtimeType})');
          AppLogger.debug('  - Valor líquido em reais: $netInReais');
          AppLogger.debug('  - Valor líquido filtro: ${_minNetValue!}');
          
          // Filtro por igualdade com tolerância de 0.01 para evitar problemas de ponto flutuante
          final difference = (netInReais - _minNetValue!).abs();
          if (difference > 0.01) {
            AppLogger.debug('  ❌ Valor líquido não corresponde: $netInReais != ${_minNetValue!} (diferença: $difference)');
            return false;
          }
          AppLogger.debug('  ✅ Valor líquido passou no filtro (igualdade)');
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

    // Limitar a 9 dígitos (máximo R$999.999,99 = 99999999 centavos)
    final limitedDigits = digitsOnly.length > 9 
        ? digitsOnly.substring(0, 9) 
        : digitsOnly;
    
    final intValue = int.parse(limitedDigits);
    final formatted = FormatHelpers.formatCurrency(intValue / 100);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
