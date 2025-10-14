import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/kyc_image_picker.dart';
import 'package:neves_capital/features/auth/presentation/screens/selfie_verification_screen.dart';

class DocumentUploadScreen extends StatefulWidget {
  final Map<String, String> userData;

  const DocumentUploadScreen({
    super.key,
    required this.userData,
  });

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  String? _frontDocumentPath;
  String? _backDocumentPath;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Verificação de Identidade'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  _buildDocumentUpload(),
                  const SizedBox(height: 24.0),
                  _buildContinueButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildDocumentUpload() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Envie uma foto da sua CNH ou RG',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),
          // Upload da frente do documento
          KycDocumentPicker(
            title: 'Frente do Documento',
            imagePath: _frontDocumentPath,
            onImageSelected: (path) {
              setState(() {
                _frontDocumentPath = path;
              });
            },
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
          const SizedBox(height: 16.0),
          // Upload do verso do documento
          KycDocumentPicker(
            title: 'Verso do Documento',
            imagePath: _backDocumentPath,
            onImageSelected: (path) {
              setState(() {
                _backDocumentPath = path;
              });
            },
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    final bool canContinue = _frontDocumentPath != null && _backDocumentPath != null;

    return ElevatedButton(
      onPressed: canContinue && !_isLoading ? _handleContinue : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Continuar'),
    );
  }

  Future<void> _handleContinue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simular processamento dos documentos
      await Future.delayed(const Duration(seconds: 2));

      // Simular validação dos documentos
      bool documentsValid = await _validateDocuments();
      
      if (!documentsValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documentos inválidos. Por favor, tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Preparar dados para próxima tela
      final userData = Map<String, dynamic>.from(widget.userData);
      userData['frontDocumentPath'] = _frontDocumentPath;
      userData['backDocumentPath'] = _backDocumentPath;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelfieVerificationScreen(userData: userData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar documentos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _validateDocuments() async {
    // Simular validação dos documentos
    // Em uma implementação real, aqui seria feita a validação com OCR
    // e verificação de autenticidade dos documentos
    
    await Future.delayed(const Duration(seconds: 1));
    
    // Simular 90% de chance de sucesso
    return DateTime.now().millisecond % 10 != 0;
  }
}
