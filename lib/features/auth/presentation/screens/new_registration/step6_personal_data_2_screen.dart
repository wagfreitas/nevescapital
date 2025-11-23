import 'package:flutter/material.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'step7_selfie_screen.dart';

/// Tela 6 do Cadastro: Informações Pessoais 2/2
class Step6PersonalData2Screen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;
  final String cpf;
  final String phone;
  final String email;
  final String fullName;
  final DateTime birthDate;
  final String motherName;

  const Step6PersonalData2Screen({
    super.key,
    this.authController,
    this.themeController,
    required this.cpf,
    required this.phone,
    required this.email,
    required this.fullName,
    required this.birthDate,
    required this.motherName,
  });

  @override
  State<Step6PersonalData2Screen> createState() => _Step6PersonalData2ScreenState();
}

class _Step6PersonalData2ScreenState extends State<Step6PersonalData2Screen> {
  bool? _isPep; // null = não selecionado, false = Não, true = Sim
  String? _occupation;
  String? _incomeRange;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _occupations = [
    'Assalariado',
    'Autônomo',
    'Empresário',
    'Aposentado',
    'Estudante',
    'Desempregado',
    'Outro',
  ];

  final List<String> _incomeRanges = [
    'Até R\$ 1.000',
    'R\$ 1.000 - R\$ 2.000',
    'R\$ 2.000 - R\$ 5.000',
    'R\$ 5.000 - R\$ 10.000',
    'R\$ 10.000 - R\$ 20.000',
    'Acima de R\$ 20.000',
  ];

  Future<void> _handleNext() async {
    if (_isPep == null) {
      setState(() {
        _errorMessage = 'Selecione se você é uma Pessoa Politicamente Exposta';
      });
      return;
    }

    if (_occupation == null || _occupation!.isEmpty) {
      setState(() {
        _errorMessage = 'Selecione sua ocupação';
      });
      return;
    }

    if (_incomeRange == null || _incomeRange!.isEmpty) {
      setState(() {
        _errorMessage = 'Selecione sua faixa de renda';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!mounted) return;

      // Navegar para próxima tela (selfie)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Step7SelfieScreen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: widget.cpf,
            phone: widget.phone,
            email: widget.email,
            fullName: widget.fullName,
            birthDate: widget.birthDate,
            motherName: widget.motherName,
            isPep: _isPep!,
            occupation: _occupation!,
            incomeRange: _incomeRange!,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
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
      backgroundColor: const Color(0xFF122118),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Informações Pessoais 2/2',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Precisamos de mais algumas informações',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              // PEP
              const Text(
                'Você é uma Pessoa Politicamente Exposta?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPepButton('Não', false),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPepButton('Sim', true),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Ocupação
              const Text(
                'Informe sua Ocupação:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: _occupation,
                  decoration: InputDecoration(
                    hintText: 'Opções',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    prefixIcon: const Icon(Icons.work, color: Colors.white70),
                  ),
                  dropdownColor: const Color(0xFF1a2d24),
                  style: const TextStyle(color: Colors.white),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  items: _occupations.map((String occupation) {
                    return DropdownMenuItem<String>(
                      value: occupation,
                      child: Text(occupation),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _occupation = value;
                      _errorMessage = null;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Selecione sua ocupação';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 32),
              // Faixa de Renda
              const Text(
                'Informe sua Faixa de Renda:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: _incomeRange,
                  decoration: InputDecoration(
                    hintText: 'Opções',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    prefixIcon: const Icon(Icons.attach_money, color: Colors.white70),
                  ),
                  dropdownColor: const Color(0xFF1a2d24),
                  style: const TextStyle(color: Colors.white),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  items: _incomeRanges.map((String range) {
                    return DropdownMenuItem<String>(
                      value: range,
                      child: Text(range),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _incomeRange = value;
                      _errorMessage = null;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Selecione sua faixa de renda';
                    }
                    return null;
                  },
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: const Color(0xFF122118),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF122118)),
                          ),
                        )
                      : const Text(
                          'Avançar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPepButton(String label, bool value) {
    final isSelected = _isPep == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPep = value;
          _errorMessage = null;
        });
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF22C55E)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF22C55E)
                : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF122118) : Colors.white,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

