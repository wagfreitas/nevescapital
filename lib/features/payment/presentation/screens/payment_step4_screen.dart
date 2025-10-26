import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neves_capital/shared/components/custom_button.dart';
import 'package:neves_capital/shared/components/custom_text_field.dart';
import 'package:neves_capital/shared/helpers/card_brand_detector.dart';
import 'package:card_scanner/card_scanner.dart';
import 'payment_step5_screen.dart';

/// Tela 4: Inserir dados do cartão
class PaymentStep4Screen extends StatefulWidget {
  final String nomeEstabelecimento;
  final String ramoAtuacao;
  final int valorCentavos;
  final String chavePix;
  final String tipoChavePix;

  const PaymentStep4Screen({
    Key? key,
    required this.nomeEstabelecimento,
    required this.ramoAtuacao,
    required this.valorCentavos,
    required this.chavePix,
    required this.tipoChavePix,
  }) : super(key: key);

  @override
  State<PaymentStep4Screen> createState() => _PaymentStep4ScreenState();
}

class _PaymentStep4ScreenState extends State<PaymentStep4Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeTitularController = TextEditingController();
  final _numeroCartaoController = TextEditingController();
  final _cvvController = TextEditingController();
  final _vencimentoController = TextEditingController();
  CardBrand _detectedBrand = CardBrand.unknown;

  @override
  void initState() {
    super.initState();
    // Escutar mudanças no número do cartão para detectar a bandeira
    _numeroCartaoController.addListener(_detectCardBrand);
  }

  @override
  void dispose() {
    _numeroCartaoController.removeListener(_detectCardBrand);
    _nomeTitularController.dispose();
    _numeroCartaoController.dispose();
    _cvvController.dispose();
    _vencimentoController.dispose();
    super.dispose();
  }

  void _detectCardBrand() {
    final cardNumber = _numeroCartaoController.text.replaceAll(' ', '');
    final detectedBrand = CardBrandDetector.detectBrand(cardNumber);
    
    if (detectedBrand != _detectedBrand) {
      setState(() {
        _detectedBrand = detectedBrand;
      });
      print('💳 Bandeira detectada: ${CardBrandDetector.getBrandName(detectedBrand)}');
    }
  }

  Future<void> _scanCard() async {
    try {
      print('📷 Iniciando scan de cartão...');
      
      final scanResult = await CardScanner.scanCard();

      if (scanResult != null) {
        print('📷 Cartão escaneado com sucesso!');
        print('📷 Número: ${scanResult.cardNumber}');
        print('📷 Nome: ${scanResult.cardHolderName}');
        print('📷 Validade: ${scanResult.expiryDate}');

        // Preencher campos automaticamente
        _numeroCartaoController.text = _formatCardNumber(scanResult.cardNumber);
        _nomeTitularController.text = scanResult.cardHolderName;
        _vencimentoController.text = _formatExpiryDate(scanResult.expiryDate);

        // Mostrar feedback de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cartão escaneado com sucesso! Verifique os dados.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('📷 Scan cancelado pelo usuário');
      }
    } catch (e) {
      print('❌ Erro ao escanear cartão: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao escanear cartão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatCardNumber(String cardNumber) {
    // Remove espaços e formata: XXXX XXXX XXXX XXXX
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    
    return buffer.toString();
  }

  String _formatExpiryDate(String expiryDate) {
    // Formatar para MM/AA
    final cleaned = expiryDate.replaceAll(RegExp(r'\D'), '');
    
    if (cleaned.length >= 4) {
      // Se veio no formato MMYY ou MMYYYY
      final month = cleaned.substring(0, 2);
      final year = cleaned.length >= 4 ? cleaned.substring(2, 4) : cleaned.substring(2);
      return '$month/$year';
    }
    
    return expiryDate;
  }

  void _continuar() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentStep5Screen(
            nomeEstabelecimento: widget.nomeEstabelecimento,
            ramoAtuacao: widget.ramoAtuacao,
            valorCentavos: widget.valorCentavos,
            chavePix: widget.chavePix,
            tipoChavePix: widget.tipoChavePix,
            nomeTitular: _nomeTitularController.text,
            numeroCartao: _numeroCartaoController.text.replaceAll(' ', ''),
            cvv: _cvvController.text,
            vencimento: _vencimentoController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '4/5',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Título
                const Text(
                  'DADOS DO CARTÃO DO COMPRADOR',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Botão Escanear Cartão
                OutlinedButton.icon(
                  onPressed: _scanCard,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Escanear Cartão com Câmera'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Ou digitar manualmente
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[600])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou digite manualmente',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[600])),
                  ],
                ),
                
                const SizedBox(height: 20),

                // Nome do Titular
                CustomTextField(
                  controller: _nomeTitularController,
                  hintText: 'Nome Completo do Titular',
                  labelText: 'Nome Completo do Titular',
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Insira o nome do titular';
                    }
                    if (value.length < 3) {
                      return 'Nome inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Número do Cartão
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _numeroCartaoController,
                      hintText: 'Número do Cartão',
                      labelText: 'Número do Cartão',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                        _CardNumberFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Insira o número do cartão';
                        }
                        final digits = value.replaceAll(' ', '');
                        if (digits.length < 13 || digits.length > 16) {
                          return 'Número do cartão inválido';
                        }
                        return null;
                      },
                    ),
                    // Indicador de bandeira detectada
                    if (_detectedBrand != CardBrand.unknown) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.credit_card,
                            size: 20,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Bandeira: ${CardBrandDetector.getBrandName(_detectedBrand)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // CVV e Data de Vencimento
                Row(
                  children: [
                    // CVV
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _cvvController,
                        hintText: 'CVV',
                        labelText: 'CVV',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Insira o CVV';
                          }
                          if (value.length < 3) {
                            return 'CVV inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Data de Vencimento
                    Expanded(
                      flex: 3,
                      child: CustomTextField(
                        controller: _vencimentoController,
                        hintText: 'Data de Vencimento',
                        labelText: 'Data de Vencimento',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          _ExpiryDateFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Insira a validade';
                          }
                          if (value.length != 5) {
                            return 'Data inválida';
                          }
                          final parts = value.split('/');
                          final month = int.tryParse(parts[0]) ?? 0;
                          if (month < 1 || month > 12) {
                            return 'Mês inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Botão Avançar
                CustomButton(
                  text: 'Avançar',
                  onPressed: _continuar,
                ),
                
                const SizedBox(height: 20),
                
                // Indicador de progresso
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressDot(true),
                    _buildProgressLine(),
                    _buildProgressDot(true),
                    _buildProgressLine(),
                    _buildProgressDot(true),
                    _buildProgressLine(),
                    _buildProgressDot(true),
                    _buildProgressLine(),
                    _buildProgressDot(false),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Aviso de segurança
                const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Seus dados estão protegidos com criptografia',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
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


  Widget _buildProgressDot(bool isActive) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Theme.of(context).primaryColor : Colors.grey[300],
      ),
    );
  }

  Widget _buildProgressLine() {
    return Container(
      width: 40,
      height: 2,
      color: Colors.grey[300],
    );
  }

}

/// Formatador para número do cartão (adiciona espaços)
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatador para data de vencimento (MM/AA)
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 4; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }
    
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}


