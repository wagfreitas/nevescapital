import 'package:flutter/material.dart';
import 'package:neves_capital/features/auth/presentation/helpers/registration_progress_indicator.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/screens/terms_of_use_screen.dart';
import 'package:neves_capital/shared/screens/privacy_policy_screen.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
// import 'package:neves_capital/shared/services/firebase_storage_service.dart'; // TODO: Reativar quando upload for implementado
import 'package:neves_capital/features/auth/data/services/local_registration_storage.dart';
import 'package:neves_capital/features/auth/data/services/registration_service.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/presentation/controllers/registration_lifecycle_observer.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/features/home/presentation/screens/main_tab_screen.dart';

/// Tela 8 do Cadastro: Envie Documento com Foto
class Step8DocumentScreen extends StatefulWidget {
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
  final bool isPep;
  final String occupation;
  final String incomeRange;
  final String selfiePath;
  final String? initialFrontDocumentPath;
  final String? initialBackDocumentPath;
  final String? initialDocumentType;

  const Step8DocumentScreen({
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
    required this.isPep,
    required this.occupation,
    required this.incomeRange,
    required this.selfiePath,
    this.initialFrontDocumentPath,
    this.initialBackDocumentPath,
    this.initialDocumentType,
  });

  @override
  State<Step8DocumentScreen> createState() => _Step8DocumentScreenState();
}

class _Step8DocumentScreenState extends State<Step8DocumentScreen> {
  File? _frontDocumentFile;
  File? _backDocumentFile;
  String? _selectedDocumentType; // 'RG', 'CNH', 'RNE'
  bool _isLoading = false;
  String? _errorMessage;
  late RegistrationLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();

    // Restaurar fotos dos documentos se existirem (ANTES de criar o observer)
    if (widget.initialFrontDocumentPath != null) {
      _frontDocumentFile = File(widget.initialFrontDocumentPath!);
    }
    if (widget.initialBackDocumentPath != null) {
      _backDocumentFile = File(widget.initialBackDocumentPath!);
    }
    
    // Restaurar tipo de documento se existir
    _selectedDocumentType = widget.initialDocumentType;

    _lifecycleObserver = RegistrationLifecycleObserver(
      getCurrentProgress: () => RegistrationProgress(
        cpf: widget.cpf,
        currentStep: 'document',
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
        isPep: widget.isPep,
        occupation: widget.occupation,
        incomeRange: widget.incomeRange,
        selfiePath: widget.selfiePath,
        documentFrontPath: _frontDocumentFile?.path,
        documentBackPath: _backDocumentFile?.path,
        documentType: _selectedDocumentType,
      ),
      shouldSaveProgress: () => ModalRoute.of(context)?.isCurrent ?? false,
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    // Persistir o passo imediatamente para permitir retomada exata
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lifecycleObserver.saveNow(localOnly: false);
    });
  }

  @override
  void dispose() {
    _lifecycleObserver.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  Future<void> _showImageSourceDialog(bool isFront) async {
    if (!mounted) return;

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1A2F25),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Escolha uma opção',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppTheme.primaryColor, size: 28),
              title: const Text(
                'Tirar Foto',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.primaryColor, size: 28),
              title: const Text(
                'Escolher da Galeria',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickDocument(isFront, source);
    }
  }

  Future<void> _pickDocument(bool isFront, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = source == ImageSource.camera
          ? await picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 90,
            )
          : await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 90,
            );

      if (image != null) {
        setState(() {
          if (isFront) {
            _frontDocumentFile = File(image.path);
          } else {
            _backDocumentFile = File(image.path);
          }
          _errorMessage = null;
        });

        // Salvar progresso com o documento capturado
        await _lifecycleObserver.saveNow(localOnly: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = source == ImageSource.camera
              ? 'Erro ao capturar foto. Tente novamente.'
              : 'Erro ao selecionar foto. Tente novamente.';
        });
      }
      AppLogger.error('Erro ao ${source == ImageSource.camera ? "capturar" : "selecionar"} documento: $e');
    }
  }

  Future<void> _handleFinalize() async {
    if (_selectedDocumentType == null) {
      setState(() {
        _errorMessage = 'Por favor, selecione o tipo de documento';
      });
      return;
    }
    
    if (_frontDocumentFile == null || _backDocumentFile == null) {
      setState(() {
        _errorMessage = 'Por favor, tire foto da frente e verso do documento';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Criar/atualizar usuário no Firestore com todos os dados
      AppLogger.debug(
          'Step8DocumentScreen: Finalizando cadastro no Firestore...');
      AppLogger.debug('Step8DocumentScreen: Dados a serem salvos');
      AppLogger.sensitive('CPF', widget.cpf);
      AppLogger.sensitive('Email', widget.email);
      AppLogger.debug('Nome: ${widget.fullName}');
      AppLogger.sensitive('Telefone', widget.phone);
      AppLogger.debug('Data Nascimento: ${widget.birthDate}');
      AppLogger.debug('Nome da Mãe: ${widget.motherName}');
      AppLogger.debug('PEP: ${widget.isPep}');
      AppLogger.debug('Ocupação: ${widget.occupation}');
      AppLogger.debug('Renda: ${widget.incomeRange}');
      AppLogger.debug('Tipo de Documento: $_selectedDocumentType');

      // Primeiro, verificar se o usuário já existe (criado na tela de email)
      final existingUser = await FirestoreService.getUserByCpf(widget.cpf);

      String userId;
      if (existingUser != null) {
        AppLogger.info(
            'Step8DocumentScreen: Usuário encontrado, preparando upload...');
        userId = existingUser['id'] as String;
        AppLogger.debug('UserId: $userId');
      } else {
        AppLogger.warning(
            'Step8DocumentScreen: Usuário não encontrado, criando temporariamente...');
        // Criar usuário base para obter userId (incluindo endereço)
        AppLogger.debug('Step8DocumentScreen: Criando usuário com endereço completo');
        AppLogger.debug('CEP: ${widget.cep}');
        AppLogger.debug('Rua: ${widget.street}');
        AppLogger.debug('Número: ${widget.number}');
        AppLogger.debug('Bairro: ${widget.neighborhood}');
        AppLogger.debug('Cidade: ${widget.city}');
        AppLogger.debug('Estado: ${widget.state}');
        
        userId = await FirestoreService.createUser(
          email: widget.email,
          fullName: widget.fullName,
          cpf: widget.cpf,
          phone: widget.phone,
          birthDate: widget.birthDate,
          motherName: widget.motherName,
          isPep: widget.isPep,
          occupation: widget.occupation,
          incomeRange: widget.incomeRange,
          // Dados de endereço
          cep: widget.cep,
          address: widget.street,
          number: widget.number,
          complement: widget.complement,
          neighborhood: widget.neighborhood,
          city: widget.city,
          state: widget.state,
        );
        AppLogger.info('Step8DocumentScreen: Usuário base criado com endereço: $userId');
      }

      // TODO: Upload dos documentos para Firebase Storage
      // Comentado temporariamente para permitir finalização do cadastro sem upload
      // Será reativado após resolver problemas de permissão/configuração do Storage
      /*
      AppLogger.info('Step8DocumentScreen: Iniciando upload de documentos...');
      final uploadResults = await FirebaseStorageService.uploadKycDocuments(
        userId: userId,
        selfiePath: widget.selfiePath,
        frontDocumentPath: _frontDocumentFile!.path,
        backDocumentPath: _backDocumentFile!.path,
      );

      final selfieUrl = uploadResults['selfieUrl'];
      final frontDocumentUrl = uploadResults['frontDocumentUrl'];
      final backDocumentUrl = uploadResults['backDocumentUrl'];

      AppLogger.info('Step8DocumentScreen: Upload concluído');
      AppLogger.debug('Selfie URL: $selfieUrl');
      AppLogger.debug('Front Document URL: $frontDocumentUrl');
      AppLogger.debug('Back Document URL: $backDocumentUrl');

      // Validar se todos os uploads foram bem-sucedidos
      if (selfieUrl == null ||
          frontDocumentUrl == null ||
          backDocumentUrl == null) {
        final List<String> missingDocs = [];
        if (selfieUrl == null) missingDocs.add('selfie');
        if (frontDocumentUrl == null) missingDocs.add('frente do documento');
        if (backDocumentUrl == null) missingDocs.add('verso do documento');
        
        AppLogger.error('❌ Falha no upload dos seguintes documentos: ${missingDocs.join(", ")}');
        throw Exception('Falha ao fazer upload de: ${missingDocs.join(", ")}. Verifique sua conexão e tente novamente.');
      }
      */

      // URLs temporárias (serão substituídas quando upload for reativado)
      final String? selfieUrl = null;
      final String? frontDocumentUrl = null;
      final String? backDocumentUrl = null;

      AppLogger.info('Step8DocumentScreen: Salvando dados do usuário (upload de documentos desabilitado temporariamente)...');
      AppLogger.warning('⚠️ Upload de documentos desabilitado - apenas dados do usuário serão salvos');

      // Atualizar usuário com dados completos (sem URLs dos documentos por enquanto)
      AppLogger.info('Step8DocumentScreen: Atualizando usuário com dados pessoais, endereço e tipo de documento...');
      AppLogger.debug('Step8DocumentScreen: Dados de endereço a serem salvos:');
      AppLogger.debug('CEP: ${widget.cep}');
      AppLogger.debug('Rua: ${widget.street}');
      AppLogger.debug('Número: ${widget.number}');
      AppLogger.debug('Complemento: ${widget.complement}');
      AppLogger.debug('Bairro: ${widget.neighborhood}');
      AppLogger.debug('Cidade: ${widget.city}');
      AppLogger.debug('Estado: ${widget.state}');
      
      final success = await FirestoreService.updateUser(
        userId: userId,
        email: widget.email,
        fullName: widget.fullName,
        cpf: widget.cpf,
        phone: widget.phone,
        birthDate: widget.birthDate,
        motherName: widget.motherName,
        isPep: widget.isPep,
        occupation: widget.occupation,
        incomeRange: widget.incomeRange,
        // Dados de endereço
        cep: widget.cep,
        address: widget.street,
        number: widget.number,
        complement: widget.complement,
        neighborhood: widget.neighborhood,
        city: widget.city,
        state: widget.state,
        selfieUrl: selfieUrl, // null por enquanto
        frontDocumentUrl: frontDocumentUrl, // null por enquanto
        backDocumentUrl: backDocumentUrl, // null por enquanto
        documentType: _selectedDocumentType,
      );

      if (!success) {
        AppLogger.error('Step8DocumentScreen: Falha ao atualizar usuário');
        throw Exception('Falha ao atualizar dados do usuário');
      }

      AppLogger.info('Step8DocumentScreen: Usuário atualizado com sucesso!');

      AppLogger.info('Step8DocumentScreen: Cadastro finalizado no Firestore!');

      // Limpar progresso local e do Firestore (cadastro completo!)
      // Não crítico se falhar - o cadastro já foi concluído
      try {
        AppLogger.debug('Limpando progresso de cadastro (local + Firestore)...');
        await LocalRegistrationStorage.clearLocal();
        await RegistrationService.deleteProgress(widget.cpf);
        AppLogger.info('✅ Progresso de cadastro limpo com sucesso');
      } catch (cleanupError) {
        AppLogger.warning('⚠️ Erro ao limpar progresso (não crítico): $cleanupError');
        // Não bloquear o fluxo se a limpeza falhar
      }

      if (!mounted) return;

      // Marcar como logado (não crítico se falhar)
      try {
        if (widget.authController != null) {
          await widget.authController!.loginWithOtpMock(widget.cpf);
          AppLogger.info('✅ Login automático realizado com sucesso');
        }
      } catch (loginError) {
        AppLogger.warning('⚠️ Erro ao fazer login automático (não crítico): $loginError');
        // Não bloquear o fluxo se o login automático falhar
        // O usuário pode fazer login manualmente depois
      }

      // Mostrar mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Redirecionar para MainTabScreen após cadastro completo
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MainTabScreen(
              authController: widget.authController!,
              themeController: widget.themeController!,
            ),
          ),
          (route) => false, // Remove todas as rotas anteriores
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        String errorMessage = 'Erro ao finalizar cadastro. Tente novamente.';
        
        // Mensagens de erro mais específicas
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('permission') || errorString.contains('permissão')) {
          errorMessage = 'Erro de permissão. Verifique as configurações do Firestore.';
        } else if (errorString.contains('network') || errorString.contains('conexão')) {
          errorMessage = 'Erro de conexão. Verifique sua internet e tente novamente.';
        } else if (errorString.contains('upload') || errorString.contains('storage')) {
          errorMessage = 'Erro ao fazer upload dos documentos. Tente novamente.';
        } else if (errorString.contains('firestore') || errorString.contains('firebase')) {
          errorMessage = 'Erro ao salvar no banco de dados. Tente novamente.';
        }
        
        setState(() {
          _errorMessage = errorMessage;
        });
        AppLogger.error('❌ Erro ao finalizar cadastro: $e', e, stackTrace);
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
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: const Text(
          'Documento com Foto',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: RegistrationProgressIndicator.preferredSize(3),
        onBackPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 28 + 40;
            return SingleChildScrollView(
              reverse: true,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: topPadding,
                bottom: bottomInset + 32.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - topPadding),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seleção de tipo de documento
                      const Text(
                        'Qual documento você irá enviar ?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDocumentTypeButton('RG'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDocumentTypeButton('CNH'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDocumentTypeButton('RNE'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Envie uma foto do documento:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Foto da Frente
                      _buildDocumentButton(
                        title: 'Foto da Frente do Documento',
                        file: _frontDocumentFile,
                        onTap: () => _showImageSourceDialog(true),
                      ),
                      const SizedBox(height: 24),
                      // Foto do Verso
                      _buildDocumentButton(
                        title: 'Foto do Verso do Documento',
                        file: _backDocumentFile,
                        onTap: () => _showImageSourceDialog(false),
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
                      const Spacer(),
                      // Botão Finalizar Cadastro
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleFinalize,
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
                      // Termos e Política
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
                                text: 'Ao finalizar o cadastro você concorda com os ',
                              ),
                              TextSpan(
                                text: 'Termos de Uso',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _showTermsModal(context),
                              ),
                              const TextSpan(text: ' e com a '),
                              TextSpan(
                                text: 'Política de Privacidade',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _showPrivacyModal(context),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildDocumentTypeButton(String type) {
    final isSelected = _selectedDocumentType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDocumentType = type;
          _errorMessage = null;
        });
        // Salvar progresso com o tipo selecionado
        _lifecycleObserver.saveNow(localOnly: false);
      },
      child: Container(
        height: 48,
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
            type,
            style: TextStyle(
              color: isSelected ? AppTheme.backgroundColor : Colors.white,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentButton({
    required String title,
    required File? file,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: file != null
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: file != null
              ? AppTheme.primaryColor
              : Colors.white.withValues(alpha: 0.2),
          width: file != null ? 2 : 1,
        ),
      ),
      child: file != null
          ? Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.file(
                    file,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text(
                      'Trocar Foto',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : GestureDetector(
              onTap: onTap,
              child: Container(
                height: 120,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt,
                      color: Colors.white70,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showTermsModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsOfUseScreen()),
    );
  }

  void _showPrivacyModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
    );
  }
}
