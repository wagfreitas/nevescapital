import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/features/auth/data/services/local_registration_storage.dart';
import 'package:neves_capital/features/auth/data/services/registration_service.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

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
  final bool isPep;
  final String occupation;
  final String incomeRange;
  final String selfiePath;

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
    required this.isPep,
    required this.occupation,
    required this.incomeRange,
    required this.selfiePath,
  });

  @override
  State<Step8DocumentScreen> createState() => _Step8DocumentScreenState();
}

class _Step8DocumentScreenState extends State<Step8DocumentScreen> {
  File? _frontDocumentFile;
  File? _backDocumentFile;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickDocument(bool isFront) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao capturar foto. Tente novamente.';
        });
      }
      AppLogger.error('Erro ao capturar documento: $e');
    }
  }

  Future<void> _handleFinalize() async {
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

      // Primeiro, verificar se o usuário já existe (criado na tela de email)
      final existingUser = await FirestoreService.getUserByCpf(widget.cpf);

      if (existingUser != null) {
        AppLogger.info(
            'Step8DocumentScreen: Usuário encontrado, atualizando dados...');
        AppLogger.debug('UserId: ${existingUser['id']}');

        // Atualizar usuário com dados completos
        final success = await FirestoreService.updateUser(
          userId: existingUser['id'] as String,
          email: widget.email,
          fullName: widget.fullName,
          cpf: widget.cpf,
          phone: widget.phone,
          birthDate: widget.birthDate,
          motherName: widget.motherName,
          isPep: widget.isPep,
          occupation: widget.occupation,
          incomeRange: widget.incomeRange,
          // TODO: Upload selfie e documentos para Firebase Storage
          // selfiePath: widget.selfiePath,
          // frontDocumentPath: _frontDocumentFile!.path,
          // backDocumentPath: _backDocumentFile!.path,
        );

        if (success) {
          AppLogger.info(
              'Step8DocumentScreen: Usuário atualizado com sucesso!');
        } else {
          AppLogger.error('Step8DocumentScreen: Falha ao atualizar usuário');
          throw Exception('Falha ao atualizar dados do usuário');
        }
      } else {
        AppLogger.warning(
            'Step8DocumentScreen: Usuário não encontrado, criando novo...');
        // Criar usuário completo (fallback)
        await FirestoreService.createUser(
          email: widget.email,
          fullName: widget.fullName,
          cpf: widget.cpf,
          phone: widget.phone,
          birthDate: widget.birthDate,
          motherName: widget.motherName,
          isPep: widget.isPep,
          occupation: widget.occupation,
          incomeRange: widget.incomeRange,
        );
        AppLogger.info('Step8DocumentScreen: Usuário criado com sucesso!');
      }

      AppLogger.info('Step8DocumentScreen: Cadastro finalizado no Firestore!');

      // Limpar progresso local e do Firestore (cadastro completo!)
      AppLogger.debug('Limpando progresso de cadastro (local + Firestore)...');
      await LocalRegistrationStorage.clearLocal();
      await RegistrationService.deleteProgress(widget.cpf);
      AppLogger.info('Progresso de cadastro limpo com sucesso');

      if (!mounted) return;

      // Marcar como logado
      if (widget.authController != null) {
        await widget.authController!.loginWithOtpMock(widget.cpf);
      }

      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro realizado com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Voltar para onboarding (que vai redirecionar para dashboard se logado)
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao finalizar cadastro. Tente novamente.';
        });
        AppLogger.error('Erro ao finalizar cadastro: $e');
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
                'Envie Documento com Foto',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Precisamos de fotos da frente e verso do seu documento',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              // Foto da Frente
              _buildDocumentButton(
                title: 'Foto da Frente do Documento',
                file: _frontDocumentFile,
                onTap: () => _pickDocument(true),
              ),
              const SizedBox(height: 24),
              // Foto do Verso
              _buildDocumentButton(
                title: 'Foto do Verso do Documento',
                file: _backDocumentFile,
                onTap: () => _pickDocument(false),
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
              // Botão Finalizar Cadastro
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleFinalize,
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
                child: Text(
                  'Ao Finalizar o Cadastro você Concorda com os\nTermos de Uso e com a Política de Privacidade',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
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

  Widget _buildDocumentButton({
    required String title,
    required File? file,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: file != null
              ? const Color(0xFF22C55E).withOpacity(0.1)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null
                ? const Color(0xFF22C55E)
                : Colors.white.withOpacity(0.2),
            width: file != null ? 2 : 1,
          ),
        ),
        child: file != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      file,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF22C55E),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Padding(
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
}
