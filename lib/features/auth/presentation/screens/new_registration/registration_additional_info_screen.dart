import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:neves_capital/shared/screens/terms_of_use_screen.dart';
import 'package:neves_capital/shared/screens/privacy_policy_screen.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/features/auth/data/services/local_registration_storage.dart';
import 'package:neves_capital/features/auth/presentation/helpers/registration_progress_indicator.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/home/presentation/screens/main_tab_screen.dart';
import 'registration_address_screen.dart';

/// Cadastro - Informacoes Pessoais
/// Coleta PEP, ocupacao e faixa de renda. Ultima tela antes da finalizacao.
class RegistrationAdditionalInfoScreen extends StatefulWidget {
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

  const RegistrationAdditionalInfoScreen({
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
  State<RegistrationAdditionalInfoScreen> createState() =>
      _RegistrationAdditionalInfoScreenState();
}

class _RegistrationAdditionalInfoScreenState
    extends State<RegistrationAdditionalInfoScreen> {
  bool? _isPep;
  String? _occupation;
  String? _incomeRange;
  bool _isLoading = false;
  String? _errorMessage;

  static const List<String> _occupations = [
    'Administrador', 'Advogado', 'Ajudante Geral', 'Analista de Sistemas',
    'Arquiteto', 'Artista', 'Atendente', 'Autônomo', 'Babá', 'Cabeleireiro',
    'Bombeiro Civil', 'Comerciante', 'Contador', 'Cozinheiro',
    'Criador de Conteúdo', 'Dentista', 'Designer', 'Desenvolvedor de Software',
    'Gestor', 'Economista', 'Eletricista', 'Empresário', 'Enfermeiro',
    'Engenheiro', 'Esteticista', 'Estudante', 'Farmacêutico', 'Faxineiro',
    'Fisioterapeuta', 'Fotógrafo', 'Freelancer', 'Garçom', 'Gerente',
    'Instrutor', 'Jardineiro', 'Jornalista', 'Marceneiro', 'Mecânico',
    'Médico', 'Militar', 'Motorista', 'Motorista de Aplicativo',
    'Operador de Caixa', 'Operador de Máquinas', 'Pedreiro', 'Personal Trainer',
    'Pintor', 'Policial', 'Produtor de Eventos', 'Produtor Rural', 'Professor',
    'Psicólogo', 'Publicitário', 'Recepcionista', 'Representante Comercial',
    'Segurança', 'Soldador', 'Supervisor', 'Tatuador', 'Técnico de Enfermagem',
    'Técnico de Informática', 'Técnico de Manutenção', 'Terapeuta',
    'Trabalhador Rural', 'Vendedor', 'Vigia', 'Outros',
  ];

  static const List<String> _incomeRanges = [
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
    _isPep = widget.initialIsPep ?? false;
    _occupation = widget.initialOccupation;
    _incomeRange = widget.initialIncomeRange;
  }

  // =========================================================
  // PERSISTENCIA
  // =========================================================

  Future<void> _saveProgressLocally() async {
    final existing = await LocalRegistrationStorage.getLocal();
    final keepStep = RegistrationProgress.furthestStep(
      existing?.currentStep ?? 'personal2', 'personal2',
    );
    final progress = (existing ?? RegistrationProgress(
      cpf: widget.cpf,
      currentStep: keepStep,
      status: RegistrationStatus.inProgress,
      lastUpdated: DateTime.now(),
    )).copyWith(
      currentStep: keepStep,
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
    await LocalRegistrationStorage.saveLocal(progress);
  }

  // =========================================================
  // NAVEGACAO
  // =========================================================

  Future<void> _handleNext() async {
    if (_isPep == null) {
      setState(() => _errorMessage = 'Selecione se você é uma Pessoa Politicamente Exposta');
      return;
    }
    if (_occupation == null || _occupation!.isEmpty) {
      setState(() => _errorMessage = 'Selecione sua ocupação');
      return;
    }
    if (_incomeRange == null || _incomeRange!.isEmpty) {
      setState(() => _errorMessage = 'Selecione sua faixa de renda');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _saveProgressLocally();
      if (!mounted) return;
      await _completeRegistration();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeRegistration() async {
    final existingUser = await FirestoreService.getUserByCpf(widget.cpf);

    String userId;
    if (existingUser != null) {
      userId = existingUser['id'] as String;
      final success = await FirestoreService.updateUser(
        userId: userId,
        email: widget.email,
        fullName: widget.fullName,
        cpf: widget.cpf,
        phone: widget.phone,
        birthDate: widget.birthDate,
        motherName: widget.motherName,
        isPep: _isPep,
        occupation: _occupation,
        incomeRange: _incomeRange,
        cep: widget.cep,
        address: widget.street,
        number: widget.number,
        complement: widget.complement,
        neighborhood: widget.neighborhood,
        city: widget.city,
        state: widget.state,
      );
      if (!success) throw Exception('Falha ao atualizar dados do usuário');
    } else {
      userId = await FirestoreService.createUser(
        email: widget.email,
        fullName: widget.fullName,
        cpf: widget.cpf,
        phone: widget.phone,
        birthDate: widget.birthDate,
        motherName: widget.motherName,
        isPep: _isPep,
        occupation: _occupation,
        incomeRange: _incomeRange,
        cep: widget.cep,
        address: widget.street,
        number: widget.number,
        complement: widget.complement,
        neighborhood: widget.neighborhood,
        city: widget.city,
        state: widget.state,
      );
    }

    // Limpar progresso local
    await LocalRegistrationStorage.clearLocal();

    if (!mounted) return;

    // Login automatico
    try {
      if (widget.authController != null) {
        await widget.authController!.loginWithOtp(widget.cpf);
      }
    } catch (e) {
      AppLogger.error('Erro ao fazer login automatico: $e');
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cadastro realizado com sucesso!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => MainTabScreen(
            authController: widget.authController ?? AuthController(),
            themeController: widget.themeController ?? ThemeController(),
          ),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _handleBack() async {
    await _saveProgressLocally();
    if (!mounted) return;

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationAddressScreen(
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
  }

  Future<void> _showOccupationSearch() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => _OccupationSearchScreen(
          occupations: _occupations,
          selectedOccupation: _occupation,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _occupation = result;
        _errorMessage = null;
      });
    }
  }

  Future<void> _showIncomeRangePicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Faixa de Renda',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ..._incomeRanges.map((range) {
                final isSelected = range == _incomeRange;
                return ListTile(
                  title: Text(
                    range,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppTheme.primaryColor)
                      : null,
                  onTap: () => Navigator.pop(ctx, range),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _incomeRange = result;
        _errorMessage = null;
      });
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          title: const Text(
            'Informações Pessoais',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          bottom: RegistrationProgressIndicator.preferredSize(3),
          onBackPressed: _handleBack,
        ),
        body: SafeArea(
          top: false,
          child: KeyboardDismissWrapper(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: EdgeInsets.fromLTRB(
                24.0,
                MediaQuery.of(context).padding.top + kToolbarHeight + 16 + 40,
                24.0,
                MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                      Expanded(child: _buildPepButton('Não', false)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPepButton('Sim', true)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Ocupacao
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
                    onTap: _showOccupationSearch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
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
                          const Icon(Icons.keyboard_arrow_down,
                              color: Colors.white70),
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
                  GestureDetector(
                    onTap: _showIncomeRangePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_money,
                              color: Colors.white70),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _incomeRange ?? 'Opções',
                              style: TextStyle(
                                color: _incomeRange != null
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
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.backgroundColor,
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
                                    AppTheme.backgroundColor),
                              ),
                            )
                          : const Text(
                              'Finalizar Cadastro',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                        children: [
                          const TextSpan(
                            text:
                                'Ao finalizar o cadastro você concorda com os ',
                          ),
                          TextSpan(
                            text: 'Termos de Uso',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const TermsOfUseScreen()));
                              },
                          ),
                          const TextSpan(text: ' e com a '),
                          TextSpan(
                            text: 'Política de Privacidade',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const PrivacyPolicyScreen()));
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
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
              ? AppTheme.primaryColor
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.backgroundColor : Colors.white,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tela de busca de ocupacao com filtro accent-insensitive.
class _OccupationSearchScreen extends StatefulWidget {
  final List<String> occupations;
  final String? selectedOccupation;

  const _OccupationSearchScreen({
    required this.occupations,
    this.selectedOccupation,
  });

  @override
  State<_OccupationSearchScreen> createState() =>
      _OccupationSearchScreenState();
}

class _OccupationSearchScreenState extends State<_OccupationSearchScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.occupations;
    _searchController.addListener(_filterOccupations);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterOccupations);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  static String _removeAccents(String text) {
    const accented =
        'àáâãäåèéêëìíîïòóôõöùúûüýñçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝÑÇ';
    const unaccented =
        'aaaaaaeeeeiiiioooooouuuuyncAAAAAAEEEEIIIIOOOOOUUUUYNC';
    return text.split('').map((char) {
      final index = accented.indexOf(char);
      return index >= 0 ? unaccented[index] : char;
    }).join();
  }

  void _filterOccupations() {
    final query = _removeAccents(_searchController.text.toLowerCase());
    setState(() {
      _filtered = query.isEmpty
          ? widget.occupations
          : widget.occupations
              .where((o) => _removeAccents(o.toLowerCase()).contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, widget.selectedOccupation),
        ),
        title: const Text(
          'Selecione a Ocupação',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 4.0),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: false,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _searchFocusNode.unfocus(),
                    decoration: InputDecoration(
                      hintText: 'Digite o nome da ocupação',
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
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'Nenhuma ocupação encontrada',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final occupation = _filtered[index];
                      final isSelected = occupation == widget.selectedOccupation;
                      return ListTile(
                        title: Text(
                          occupation,
                          style: TextStyle(
                            color: isSelected ? AppTheme.primaryColor : Colors.white,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: AppTheme.primaryColor)
                            : null,
                        onTap: () => Navigator.pop(context, occupation),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
