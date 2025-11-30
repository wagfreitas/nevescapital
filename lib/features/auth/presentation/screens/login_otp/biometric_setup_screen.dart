import 'package:flutter/material.dart';
import 'package:neves_capital/shared/services/biometric_service.dart';
import 'package:neves_capital/shared/services/secure_storage_service.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

/// Tela para configurar biometria facial após login bem-sucedido
class BiometricSetupScreen extends StatefulWidget {
  final AuthController authController;
  final ThemeController? themeController;
  final String cpf;

  const BiometricSetupScreen({
    super.key,
    required this.authController,
    this.themeController,
    required this.cpf,
  });

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  bool _isLoading = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await BiometricService.isAvailable();
    final faceIdAvailable = await BiometricService.isFaceIdAvailable();
    
    setState(() {
      _biometricAvailable = available && faceIdAvailable;
    });
  }

  Future<void> _handleEnableBiometric() async {
    if (!_biometricAvailable) {
      _handleSkip();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Testar biometria primeiro
      final authenticated = await BiometricService.authenticate(
        reason: 'Confirme sua identidade para ativar o login por biometria',
      );

      if (!mounted) return;

      if (authenticated) {
        // Segundo fator (biometria) validado com sucesso
        AppLogger.info('Biometria: Segundo fator validado com sucesso');
        
        // Salvar preferência de biometria
        await SecureStorageService.setBiometricEnabled(true);
        await SecureStorageService.saveLastCpf(widget.cpf);
        
        // Completar login (ambos os fatores validados: OTP + Biometria)
        AppLogger.debug('Completando login após validação dos dois fatores');
        final loginSuccess = await widget.authController.loginWithOtpMock(widget.cpf);
        
        if (!mounted) return;
        
        if (!loginSuccess) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.authController.errorMessage ?? 'Erro ao completar login'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        AppLogger.info('Login completo! Ambos os fatores validados (OTP + Biometria)');
        
        // Navegar de volta para AppWrapper (que vai mostrar Dashboard automaticamente)
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        // Usuário cancelou ou falhou - perguntar se quer tentar novamente ou pular
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Erro ao configurar biometria', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao configurar biometria: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSkip() async {
    // Usuário optou por pular o segundo fator (biometria)
    // Mas ainda precisamos completar o login (OTP já foi validado)
    AppLogger.debug('Biometria: Usuário optou por pular o segundo fator');
    
    // Salvar preferências (sem biometria)
    await SecureStorageService.saveLastCpf(widget.cpf);
    await SecureStorageService.setBiometricEnabled(false);
    
    // Completar login mesmo sem biometria (OTP já foi validado)
    AppLogger.debug('Completando login após validação do primeiro fator (OTP)');
    final loginSuccess = await widget.authController.loginWithOtpMock(widget.cpf);
    
    if (!mounted) return;
    
    if (!loginSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.authController.errorMessage ?? 'Erro ao completar login'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    AppLogger.info('Login completo! Primeiro fator validado (OTP), segundo fator pulado');
    
    // Navegar de volta para AppWrapper (que vai mostrar Dashboard automaticamente)
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              
              // Ícone de biometria
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.face,
                    size: 60,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              const Text(
                'Segundo Fator de Autenticação',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                _biometricAvailable
                    ? 'Para completar seu login, confirme sua identidade usando biometria facial (Face ID).\n\nIsso adiciona uma camada extra de segurança ao seu acesso.'
                    : 'Biometria facial não está disponível no seu dispositivo. Você pode pular esta etapa.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              
              const Spacer(),
              
              // Botão Ativar
              if (_biometricAvailable)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleEnableBiometric,
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
                            'Confirmar com Face ID',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Botão Pular
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _handleSkip,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Pular por enquanto',
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
}

