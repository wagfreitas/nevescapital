import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:neves_capital/shared/screens/terms_of_use_screen.dart';
import 'package:neves_capital/shared/screens/privacy_policy_screen.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/features/auth/presentation/controllers/registration_lifecycle_observer.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/features/auth/presentation/helpers/registration_navigation_helper.dart';
import 'package:neves_capital/core/config/feature_flags.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/features/auth/data/services/registration_service.dart';
import 'package:neves_capital/features/auth/data/services/local_registration_storage.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/home/presentation/screens/main_tab_screen.dart';
import 'step7_selfie_screen.dart';

/// Tela de teste: mesmo conteúdo de Informações Pessoais com layout que mantém
/// o conteúdo abaixo da status bar (GlassAppBar + padding top).
class TestTransparentBarScreen extends StatefulWidget {
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

  const TestTransparentBarScreen({
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
  State<TestTransparentBarScreen> createState() => _TestTransparentBarScreenState();
}

class _TestTransparentBarScreenState extends State<TestTransparentBarScreen> {
  bool? _isPep;
  String? _occupation;
  String? _incomeRange;
  bool _isLoading = false;
  String? _errorMessage;
  late RegistrationLifecycleObserver _lifecycleObserver;

  static const List<String> _occupations = [
    'Administrador', 'Advogado', 'Ajudante Geral', 'Analista de Sistemas', 'Arquiteto',
    'Artista', 'Atendente', 'Autônomo', 'Babá', 'Cabeleireiro', 'Bombeiro Civil',
    'Comerciante', 'Contador', 'Cozinheiro', 'Criador de Conteúdo', 'Dentista',
    'Designer', 'Desenvolvedor de Software', 'Gestor', 'Economista', 'Eletricista',
    'Empresário', 'Enfermeiro', 'Engenheiro', 'Esteticista', 'Estudante', 'Farmacêutico',
    'Faxineiro', 'Fisioterapeuta', 'Fotógrafo', 'Freelancer', 'Garçom', 'Gerente',
    'Instrutor', 'Jardineiro', 'Jornalista', 'Marceneiro', 'Mecânico', 'Médico',
    'Militar', 'Motorista', 'Motorista de Aplicativo', 'Operador de Caixa',
    'Operador de Máquinas', 'Pedreiro', 'Personal Trainer', 'Pintor', 'Policial',
    'Produtor de Eventos', 'Produtor Rural', 'Professor', 'Psicólogo', 'Publicitário',
    'Recepcionista', 'Representante Comercial', 'Segurança', 'Soldador', 'Supervisor',
    'Tatuador', 'Técnico de Enfermagem', 'Técnico de Informática', 'Técnico de Manutenção',
    'Terapeuta', 'Trabalhador Rural', 'Vendedor', 'Vigia', 'Outros',
  ];

  final List<String> _incomeRanges = [
    'Até R\$ 1.000', 'R\$ 1.000 - R\$ 2.000', 'R\$ 2.000 - R\$ 5.000',
    'R\$ 5.000 - R\$ 10.000', 'R\$ 10.000 - R\$ 20.000', 'Acima de R\$ 20.000',
  ];

  @override
  void initState() {
    super.initState();
    _isPep = widget.initialIsPep ?? false;
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
      if (!mounted) return;
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
      final completeProgress = await RegistrationNavigationHelper.saveAndGetCompleteProgress(currentProgress: currentProgress);
      if (!mounted) return;

      if (FeatureFlags.skipPhotoAndDocuments) {
        AppLogger.info('🚩 Feature flag ativa: pulando telas de foto e documentos');
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
            selfieUrl: null,
            frontDocumentUrl: null,
            backDocumentUrl: null,
            documentType: null,
          );
          if (!success) throw Exception('Falha ao atualizar dados do usuário no Firestore');
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
        try {
          await LocalRegistrationStorage.clearLocal();
          await RegistrationService.deleteProgress(widget.cpf);
        } catch (_) {}
        if (!mounted) return;
        try {
          if (widget.authController != null) {
            await widget.authController!.loginWithOtpMock(widget.cpf);
          }
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cadastro realizado com sucesso!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
          );
        }
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
        return;
      }

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
      if (mounted) setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showOccupationSearch(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => _OccupationSearchScreen(
          occupations: _occupations,
          selectedOccupation: _occupation,
        ),
      ),
    );
    if (result != null) setState(() {
      _occupation = result;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Container(
        color: AppTheme.backgroundColor,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24 + topPadding, 24, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Informações Pessoais',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Container(width: 32, height: 4, decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(2))),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Você é uma Pessoa Politicamente Exposta?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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
              const Text(
                'Informe sua Ocupação:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showOccupationSearch(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.work, color: Colors.white70),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _occupation ?? 'Buscar ocupação',
                          style: TextStyle(color: _occupation != null ? Colors.white : Colors.white.withValues(alpha: 0.5), fontSize: 16),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Informe sua Faixa de Renda:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _incomeRange,
                    isExpanded: true,
                    hint: Text('Opções', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                    dropdownColor: const Color(0xFF1a2d24),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    items: _incomeRanges.map((String range) {
                      return DropdownMenuItem<String>(value: range, child: Text(range));
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _incomeRange = value;
                        _errorMessage = null;
                      });
                    },
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
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14))),
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
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.backgroundColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.black)))
                      : const Text('Finalizar Cadastro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                    children: [
                      const TextSpan(text: 'Ao finalizar o cadastro você concorda com os '),
                      TextSpan(
                        text: 'Termos de Uso',
                        style: const TextStyle(color: AppTheme.primaryColor, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfUseScreen())),
                      ),
                      const TextSpan(text: ' e com a '),
                      TextSpan(
                        text: 'Política de Privacidade',
                        style: const TextStyle(color: AppTheme.primaryColor, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Conteúdo extra para testar scroll e verificar se a AppBar continua transparente
              Text(
                'Role para cima para ver o conteúdo passando por baixo da barra transparente.',
                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),
              ...List.generate(6, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Center(
                    child: Text(
                      'Bloco ${i + 1} — role para testar a AppBar',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPepButton(String label, bool value) {
    final isSelected = _isPep == value;
    return GestureDetector(
      onTap: () => setState(() {
        _isPep = value;
        _errorMessage = null;
      }),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.2),
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

/// Tela de busca de ocupação (cópia da usada em step7).
class _OccupationSearchScreen extends StatefulWidget {
  final List<String> occupations;
  final String? selectedOccupation;

  const _OccupationSearchScreen({required this.occupations, this.selectedOccupation});

  @override
  State<_OccupationSearchScreen> createState() => _OccupationSearchScreenState();
}

class _OccupationSearchScreenState extends State<_OccupationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _filteredOccupations = [];

  @override
  void initState() {
    super.initState();
    _filteredOccupations = widget.occupations;
    _searchController.addListener(_filterOccupations);
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterOccupations);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterOccupations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredOccupations = widget.occupations;
      } else {
        _filteredOccupations = widget.occupations.where((o) => o.toLowerCase().contains(query)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        onBackPressed: () => Navigator.pop(context, widget.selectedOccupation),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Buscar ocupação',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
          ),
        ),
      ),
      body: Container(
        color: AppTheme.backgroundColor,
        child: ListView.builder(
          itemCount: _filteredOccupations.length,
          itemBuilder: (context, index) {
            final occupation = _filteredOccupations[index];
            final isSelected = occupation == widget.selectedOccupation;
            return ListTile(
              title: Text(
                occupation,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: isSelected ? Icon(Icons.check, color: AppTheme.primaryColor) : null,
              onTap: () => Navigator.pop(context, occupation),
            );
          },
        ),
      ),
    );
  }
}
