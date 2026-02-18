import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/presentation/controllers/registration_lifecycle_observer.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/features/auth/presentation/helpers/registration_navigation_helper.dart';
import 'step8_document_screen.dart';

/// Tela 7 do Cadastro: Tire uma Selfie
class Step7SelfieScreen extends StatefulWidget {
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

  const Step7SelfieScreen({
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
  });

  @override
  State<Step7SelfieScreen> createState() => _Step7SelfieScreenState();
}

class _Step7SelfieScreenState extends State<Step7SelfieScreen> {
  File? _selfieFile;
  bool _isLoading = false;
  String? _errorMessage;
  late RegistrationLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();

    _lifecycleObserver = RegistrationLifecycleObserver(
      getCurrentProgress: () => RegistrationProgress(
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
        isPep: widget.isPep,
        occupation: widget.occupation,
        incomeRange: widget.incomeRange,
        selfiePath: _selfieFile?.path,
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

  Future<void> _takeSelfie() async {
    if (!mounted) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        setState(() {
          _selfieFile = File(image.path);
          _errorMessage = null;
        });

        // Salvar progresso com a selfie capturada
        await _lifecycleObserver.saveNow(localOnly: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao capturar foto. Tente novamente.';
        });
      }
      AppLogger.error('Erro ao capturar selfie: $e');
    }
  }

  Future<void> _handleNext() async {
    if (_selfieFile == null) {
      setState(() {
        _errorMessage = 'Por favor, tire uma selfie antes de continuar';
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
        currentStep: 'document', // Avançar para próxima etapa
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
        selfiePath: _selfieFile!.path, // Selfie completada
      );

      // Salvar e buscar progresso completo (garante que dados de outras telas sejam preservados)
      final completeProgress = await RegistrationNavigationHelper.saveAndGetCompleteProgress(
        currentProgress: currentProgress,
      );

      if (!mounted) return;

      // Navegar para próxima tela (documentos)
      // Usar dados do progresso completo para restaurar tudo que já foi preenchido
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Step8DocumentScreen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: widget.cpf,
            phone: completeProgress?.phone ?? widget.phone,
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
            isPep: completeProgress?.isPep ?? widget.isPep,
            occupation: completeProgress?.occupation ?? widget.occupation,
            incomeRange: completeProgress?.incomeRange ?? widget.incomeRange,
            selfiePath: completeProgress?.selfiePath ?? _selfieFile!.path,
            initialFrontDocumentPath: completeProgress?.documentFrontPath,
            initialBackDocumentPath: completeProgress?.documentBackPath,
            initialDocumentType: completeProgress?.documentType,
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
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Tire uma Selfie!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Precisamos de uma foto sua para confirmar sua identidade',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Preview da Selfie - Layout simplificado
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: _selfieFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _selfieFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 56,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tire uma foto sua',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              // Instruções
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instruções:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInstruction('• Deixe seu rosto bem iluminado'),
                    _buildInstruction('• Não use óculos escuros ou boné'),
                    _buildInstruction('• Olhe diretamente para a câmera'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Botão Tirar Foto / Alterar Foto
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _takeSelfie,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: AppTheme.primaryColor, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selfieFile == null ? Icons.camera_alt : Icons.refresh,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selfieFile == null ? 'Tirar Foto' : 'Tirar Nova Foto',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                          style:
                              const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Botão Avançar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _isLoading || _selfieFile == null ? null : _handleNext,
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
                          'Avançar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }
}
