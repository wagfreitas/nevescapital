import 'package:flutter/material.dart';
import 'package:neves_capital/shared/components/custom_button.dart';
import 'package:neves_capital/shared/components/custom_text_field.dart';
import 'payment_step4_screen.dart';

/// Tela 3: Escolher chave Pix
class PaymentStep3Screen extends StatefulWidget {
  final String nomeEstabelecimento;
  final String ramoAtuacao;
  final int valorCentavos;

  const PaymentStep3Screen({
    Key? key,
    required this.nomeEstabelecimento,
    required this.ramoAtuacao,
    required this.valorCentavos,
  }) : super(key: key);

  @override
  State<PaymentStep3Screen> createState() => _PaymentStep3ScreenState();
}

class _PaymentStep3ScreenState extends State<PaymentStep3Screen> {
  final _formKey = GlobalKey<FormState>();
  String? _tipoChavePix;
  final _telefoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _novaChaveController = TextEditingController();

  @override
  void dispose() {
    _telefoneController.dispose();
    _cpfController.dispose();
    _novaChaveController.dispose();
    super.dispose();
  }

  void _continuar() {
    if (_formKey.currentState?.validate() ?? false) {
      String chavePix = '';
      
      switch (_tipoChavePix) {
        case 'telefone':
          chavePix = _telefoneController.text;
          break;
        case 'cpf':
          chavePix = _cpfController.text;
          break;
        case 'nova':
          chavePix = _novaChaveController.text;
          break;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentStep4Screen(
            nomeEstabelecimento: widget.nomeEstabelecimento,
            ramoAtuacao: widget.ramoAtuacao,
            valorCentavos: widget.valorCentavos,
            chavePix: chavePix,
            tipoChavePix: _tipoChavePix ?? '',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fazer uma Venda',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
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
                  'ESCOLHA A CHAVE PIX QUE DESEJA RECEBER A VENDA:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Opções de chave Pix
                _buildPixOption(
                  'telefone',
                  'Telefone',
                  '(xx) XXXXXX',
                  _telefoneController,
                  TextInputType.phone,
                ),
                const SizedBox(height: 20),

                _buildPixOption(
                  'cpf',
                  'CPF/CNPJ',
                  'XXX.XXXXXXX-SS',
                  _cpfController,
                  TextInputType.number,
                ),
                const SizedBox(height: 20),

                _buildPixOption(
                  'nova',
                  'Nova Chave Pix',
                  'Nova Chave. Pix',
                  _novaChaveController,
                  TextInputType.text,
                ),
                
                const SizedBox(height: 40),

                // Botão Continuar
                CustomButton(
                  text: 'Continuar',
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
                    _buildProgressDot(false),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPixOption(
    String value,
    String title,
    String hintText,
    TextEditingController controller,
    TextInputType keyboardType,
  ) {
    final isSelected = _tipoChavePix == value;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _tipoChavePix = value;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Radio<String>(
                    value: value,
                    groupValue: _tipoChavePix,
                    onChanged: (String? newValue) {
                      setState(() {
                        _tipoChavePix = newValue;
                      });
                    },
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                    ),
                  ),
                ],
              ),
              if (isSelected) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: Colors.grey[700],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (value) {
                    if (_tipoChavePix == value && (value == null || value.isEmpty)) {
                      return 'Por favor, insira a chave Pix';
                    }
                    return null;
                  },
                ),
              ],
            ],
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



