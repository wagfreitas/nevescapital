import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller_real.dart';

class SelfieVerificationScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const SelfieVerificationScreen({
    super.key,
    required this.userData,
  });

  @override
  State<SelfieVerificationScreen> createState() => _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState extends State<SelfieVerificationScreen> {
  String? _selfiePath;
  bool _isLoading = false;
  late final AuthController _authController;
  
  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _authController.initialize();
  }
  
  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Selfie de Verificação'),
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
                  _buildSelfieUpload(),
                  const SizedBox(height: 24.0),
                  _buildFinalizeButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildSelfieUpload() {
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
            'Tire uma Selfie para Confirmar sua Identidade',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),
          _buildSelfiePreview(),
          const SizedBox(height: 24.0),
          _buildSelfieInstructions(),
          const SizedBox(height: 24.0),
          _buildSelfieButton(),
        ],
      ),
    );
  }

  Widget _buildSelfiePreview() {
    return Container(
      height: 200,
      width: 200,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary,
          width: 2.0,
        ),
      ),
      child: _selfiePath != null
          ? ClipOval(
              child: Image.asset(
                _selfiePath!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return _buildSelfiePlaceholder();
                },
              ),
            )
          : _buildSelfiePlaceholder(),
    );
  }

  Widget _buildSelfiePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.person,
          size: 80,
          color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.6),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Selfie',
          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.lightTheme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSelfieInstructions() {
    return Column(
      children: [
        _buildInstructionBullet('Deixe seu rosto bem iluminado'),
        _buildInstructionBullet('Não use óculos escuros ou boné'),
        _buildInstructionBullet('Olhe diretamente para a câmera'),
      ],
    );
  }

  Widget _buildInstructionBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            '• ',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _captureSelfie,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
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
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt),
                const SizedBox(width: 8.0),
                Text(_selfiePath != null ? 'Tirar Nova Selfie' : 'Tirar Selfie'),
              ],
            ),
    );
  }

  Widget _buildFinalizeButton() {
    final bool canFinalize = _selfiePath != null;

    return ElevatedButton(
      onPressed: canFinalize && !_isLoading ? _handleFinalize : null,
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
          : const Text('Confirmar e Finalizar Cadastro'),
    );
  }

  Future<void> _captureSelfie() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simular captura de selfie
      await Future.delayed(const Duration(seconds: 1));
      
      // Simular caminho da selfie capturada
      setState(() {
        _selfiePath = 'selfie_captured.jpg';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selfie capturada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao capturar selfie: $e'),
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

  Future<void> _handleFinalize() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Extrair dados do usuário
      final email = widget.userData['email'] as String;
      final password = widget.userData['password'] as String;
      final fullName = widget.userData['fullName'] as String;
      final cpf = widget.userData['cpf'] as String;
      final phone = widget.userData['phone'] as String? ?? '';
      final cep = widget.userData['cep'] as String? ?? '';
      final street = widget.userData['street'] as String? ?? '';
      final neighborhood = widget.userData['neighborhood'] as String? ?? '';
      final city = widget.userData['city'] as String? ?? '';
      final state = widget.userData['state'] as String? ?? '';
      final number = widget.userData['number'] as String? ?? '';
      final complement = widget.userData['complement'] as String? ?? '';

      // Registrar usuário no Firebase + PostgreSQL
      final success = await _authController.register(
        email: email,
        password: password,
        fullName: fullName,
        cpf: cpf,
        phone: phone,
        cep: cep,
        address: street,
        neighborhood: neighborhood,
        city: city,
        state: state,
        number: number,
        complement: complement,
      );

      if (success && mounted) {
        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navegar para a tela principal
        await Future.delayed(const Duration(seconds: 2));
        
        if (mounted) {
          // A navegação será feita automaticamente pelo AppWrapper
          // quando o usuário estiver autenticado no Firebase
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else if (mounted) {
        // Mostrar erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_authController.errorMessage ?? 'Erro no cadastro'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao finalizar cadastro: $e'),
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

  Future<bool> _validateSelfie() async {
    // Simular validação da selfie
    // Em uma implementação real, aqui seria feita a validação facial
    // e comparação com o documento enviado
    
    await Future.delayed(const Duration(seconds: 1));
    
    // Simular 95% de chance de sucesso
    return DateTime.now().millisecond % 20 != 0;
  }
}
