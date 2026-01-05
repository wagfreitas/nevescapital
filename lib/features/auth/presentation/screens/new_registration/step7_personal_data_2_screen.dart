import 'package:flutter/material.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/features/auth/presentation/controllers/registration_lifecycle_observer.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/features/auth/presentation/helpers/registration_navigation_helper.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'step6_address_screen.dart';
import 'step7_selfie_screen.dart';

/// Tela 7 do Cadastro: Informações Pessoais 2/2
class Step7PersonalData2Screen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;
  final String cpf;
  final String phone;
  final String email;
  final String fullName;
  final DateTime birthDate;
  final String motherName;
  final String cep;
  final String street;
  final String number;
  final String complement;
  final String neighborhood;
  final String city;
  final String state;
  final bool? initialIsPep;
  final String? initialOccupation;
  final String? initialIncomeRange;

  const Step7PersonalData2Screen({
    super.key,
    this.authController,
    this.themeController,
    required this.cpf,
    required this.phone,
    required this.email,
    required this.fullName,
    required this.birthDate,
    required this.motherName,
    required this.cep,
    required this.street,
    required this.number,
    required this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    this.initialIsPep,
    this.initialOccupation,
    this.initialIncomeRange,
  });

  @override
  State<Step7PersonalData2Screen> createState() =>
      _Step7PersonalData2ScreenState();
}

class _Step7PersonalData2ScreenState extends State<Step7PersonalData2Screen> {
  bool? _isPep;
  String? _occupation;
  String? _incomeRange;
  bool _isLoading = false;
  String? _errorMessage;
  late RegistrationLifecycleObserver _lifecycleObserver;

  static const List<String> _occupations = [
    'Administrador',
    'Advogado',
    'Ajudante Geral',
    'Analista de Sistemas',
    'Arquiteto',
    'Artista',
    'Atendente',
    'Autônomo',
    'Babá',
    'Cabeleireiro',
    'Bombeiro Civil',
    'Comerciante',
    'Contador',
    'Cozinheiro',
    'Criador de Conteúdo',
    'Dentista',
    'Designer',
    'Desenvolvedor de Software',
    'Gestor',
    'Economista',
    'Eletricista',
    'Empresário',
    'Enfermeiro',
    'Engenheiro',
    'Esteticista',
    'Estudante',
    'Farmacêutico',
    'Faxineiro',
    'Fisioterapeuta',
    'Fotógrafo',
    'Freelancer',
    'Garçom',
    'Gerente',
    'Instrutor',
    'Jardineiro',
    'Jornalista',
    'Marceneiro',
    'Mecânico',
    'Médico',
    'Militar',
    'Motorista',
    'Motorista de Aplicativo',
    'Operador de Caixa',
    'Operador de Máquinas',
    'Pedreiro',
    'Personal Trainer',
    'Pintor',
    'Policial',
    'Produtor de Eventos',
    'Produtor Rural',
    'Professor',
    'Psicólogo',
    'Publicitário',
    'Recepcionista',
    'Representante Comercial',
    'Segurança',
    'Soldador',
    'Supervisor',
    'Tatuador',
    'Técnico de Enfermagem',
    'Técnico de Informática',
    'Técnico de Manutenção',
    'Terapeuta',
    'Trabalhador Rural',
    'Vendedor',
    'Vigia',
    'Outros',
  ];

  final List<String> _incomeRanges = [
    'Até R\$ 1.000',
    'R\$ 1.000 - R\$ 2.000',
    'R\$ 2.000 - R\$ 5.000',
    'R\$ 5.000 - R\$ 10.000',
    'R\$ 10.000 - R\$ 20.000',
    'Acima de R\$ 20.000',
  ];

  @override
  void initState() {
    super.initState();

    // Restaurar valores salvos se existirem
    _isPep = widget.initialIsPep ?? false; // Padrão: false = Não
    _occupation = widget.initialOccupation;
    _incomeRange = widget.initialIncomeRange;

    _lifecycleObserver = RegistrationLifecycleObserver(
      getCurrentProgress: () => RegistrationProgress(
        cpf: widget.cpf,
        currentStep: 'personal2',
        status: RegistrationStatus.inProgress,
        lastUpdated: DateTime.now(),
        phone: widget.phone,
        email: widget.email,
        fullName: widget.fullName,
        birthDate: widget.birthDate,
        motherName: widget.motherName,
        cep: widget.cep,
        street: widget.street,
        number: widget.number,
        complement: widget.complement,
        neighborhood: widget.neighborhood,
        city: widget.city,
        state: widget.state,
        isPep: _isPep,
        occupation: _occupation,
        incomeRange: _incomeRange,
      ),
      shouldSaveProgress: () => ModalRoute.of(context)?.isCurrent ?? false,
    );

    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    // Garante que o passo atual fica salvo mesmo antes de novas interações
    // Mas apenas se houver valores restaurados
    if (widget.initialIsPep != null || widget.initialOccupation != null || widget.initialIncomeRange != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lifecycleObserver.saveNow(localOnly: false);
      });
    }
  }

  @override
  void dispose() {
    _lifecycleObserver.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

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

      // Criar progresso atual com dados preenchidos
      final currentProgress = RegistrationProgress(
        cpf: widget.cpf,
        currentStep: 'selfie',
        status: RegistrationStatus.inProgress,
        lastUpdated: DateTime.now(),
        phone: widget.phone,
        email: widget.email,
        fullName: widget.fullName,
        birthDate: widget.birthDate,
        motherName: widget.motherName,
        cep: widget.cep,
        street: widget.street,
        number: widget.number,
        complement: widget.complement,
        neighborhood: widget.neighborhood,
        city: widget.city,
        state: widget.state,
        isPep: _isPep,
        occupation: _occupation,
        incomeRange: _incomeRange,
      );

      // Salvar e buscar progresso completo (garante que dados de outras telas sejam preservados)
      final completeProgress = await RegistrationNavigationHelper.saveAndGetCompleteProgress(
        currentProgress: currentProgress,
      );

      if (!mounted) return;

      // Navegar para próxima tela (selfie)
      // Usar dados do progresso completo para restaurar tudo que já foi preenchido
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Step7SelfieScreen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: widget.cpf,
            phone: widget.phone,
            email: completeProgress?.email ?? widget.email,
            fullName: completeProgress?.fullName ?? widget.fullName,
            birthDate: completeProgress?.birthDate ?? widget.birthDate,
            motherName: completeProgress?.motherName ?? widget.motherName,
            cep: completeProgress?.cep ?? widget.cep,
            street: completeProgress?.street ?? widget.street,
            number: completeProgress?.number ?? widget.number,
            complement: completeProgress?.complement ?? widget.complement,
            neighborhood: completeProgress?.neighborhood ?? widget.neighborhood,
            city: completeProgress?.city ?? widget.city,
            state: completeProgress?.state ?? widget.state,
            isPep: completeProgress?.isPep ?? _isPep!,
            occupation: completeProgress?.occupation ?? _occupation!,
            incomeRange: completeProgress?.incomeRange ?? _incomeRange!,
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

  Future<void> _showOccupationSearch(BuildContext context) async {
    final result = await showSearch<String>(
      context: context,
      delegate: _OccupationSearchDelegate(_occupations, _occupation),
    );

    if (result != null) {
      setState(() {
        _occupation = result;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Tentar fazer pop primeiro (se houver tela anterior na pilha)
            // Se não houver, navegar explicitamente para a tela anterior
            // Isso garante que funciona tanto no fluxo normal quanto no "Recomeçar"
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Não há tela anterior na pilha (vem do fluxo de "Recomeçar")
              // Navegar explicitamente para a tela anterior (Endereço)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Step6AddressScreen(
                    authController: widget.authController,
                    themeController: widget.themeController,
                    cpf: widget.cpf,
                    phone: widget.phone,
                    email: widget.email,
                    fullName: widget.fullName,
                    birthDate: widget.birthDate,
                    motherName: widget.motherName,
                    initialCep: widget.cep,
                    initialStreet: widget.street,
                    initialNumber: widget.number,
                    initialComplement: widget.complement,
                    initialNeighborhood: widget.neighborhood,
                    initialCity: widget.city,
                    initialState: widget.state,
                  ),
                ),
              );
            }
          },
        ),
      ),
      body: SafeArea(
        child: KeyboardDismissWrapper(
          child: LayoutBuilder(
            builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SingleChildScrollView(
              reverse: true,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                bottom: bottomInset + 32.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        'Informações Pessoais',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 32,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 32,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Color(0xFF22C55E),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
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
                      GestureDetector(
                        onTap: () => _showOccupationSearch(context),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.work, color: Colors.white70),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _occupation ?? 'Buscar ocupação',
                                  style: TextStyle(
                                    color: _occupation != null
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const Icon(Icons.search, color: Colors.white70),
                            ],
                          ),
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
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _incomeRange,
                          decoration: InputDecoration(
                            hintText: 'Opções',
                            hintStyle:
                                TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                            filled: true,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            prefixIcon:
                                const Icon(Icons.attach_money, color: Colors.white70),
                          ),
                          dropdownColor: const Color(0xFF1a2d24),
                          style: const TextStyle(color: Colors.white),
                          icon:
                              const Icon(Icons.arrow_drop_down, color: Colors.white70),
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
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style:
                                      const TextStyle(color: Colors.red, fontSize: 14),
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF122118)),
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
          },
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
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF22C55E)
                : Colors.white.withValues(alpha: 0.2),
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

// Classe auxiliar para busca de ocupação
class _OccupationSearchDelegate extends SearchDelegate<String> {
  final List<String> occupations;
  final String? selectedOccupation;

  _OccupationSearchDelegate(this.occupations, this.selectedOccupation);

  @override
  String get searchFieldLabel => 'Buscar ocupação';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF122118),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, selectedOccupation ?? '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? occupations
        : occupations
            .where((occupation) =>
                occupation.toLowerCase().contains(query.toLowerCase()))
            .toList();

    return Container(
      color: const Color(0xFF122118),
      child: ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final occupation = suggestions[index];
          final isSelected = occupation == selectedOccupation;

          return ListTile(
            title: Text(
              occupation,
              style: TextStyle(
                color: isSelected ? const Color(0xFF22C55E) : Colors.white,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check, color: Color(0xFF22C55E))
                : null,
            onTap: () {
              close(context, occupation);
            },
          );
        },
      ),
    );
  }
}
