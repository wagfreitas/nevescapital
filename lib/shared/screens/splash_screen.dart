import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:neves_capital/features/home/presentation/screens/main_tab_screen.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/shared/services/biometric_service.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/core/theme/app_theme.dart';

/// Splash screen - ponto de entrada da aplicação
/// Verifica estado de login e navega conforme necessário
class SplashScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;

  const SplashScreen({
    super.key,
    this.authController,
    this.themeController,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isChecking = true;
  bool _isProcessingBiometric = false;

  @override
  void initState() {
    super.initState();
    // Aguardar dois frames para garantir que o logo seja renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkLoginAndNavigate();
      });
    });
  }

  /// Verifica estado de login e navega conforme necessário
  Future<void> _checkLoginAndNavigate() async {
    // Aguardar um pouco para garantir que o logo apareça na tela
    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      // Verificar isLoggedIn do SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in_otp') ?? false;

      AppLogger.info('🔐 [SPLASH] Verificando estado de login...');
      AppLogger.info('  - is_logged_in_otp: $isLoggedIn');

      if (!mounted) return;

      if (isLoggedIn) {
        // Usuário está logado - verificar e fazer autenticação biométrica
        AppLogger.info('🔐 [SPLASH] Usuário está logado - verificando biometria');
        await _handleBiometricAuth();
      } else {
        // Usuário não está logado - ir para onboarding
        AppLogger.info('🔐 [SPLASH] Usuário não está logado - redirecionando para onboarding');
        _navigateToOnboarding();
      }
    } catch (e) {
      AppLogger.error('Erro ao verificar estado de login', e);
      if (mounted) {
        _navigateToOnboarding();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  /// Gerencia autenticação biométrica ou senha do dispositivo
  Future<void> _handleBiometricAuth() async {
    if (_isProcessingBiometric) {
      AppLogger.warning('Processamento de biometria já em andamento');
      return;
    }

    _isProcessingBiometric = true;

    try {
      // 1. Verificar se há qualquer tipo de biometria disponível
      final isBiometricAvailable = await BiometricService.isAvailable();
      final isFaceIdAvailable = await BiometricService.isFaceIdAvailable();
      final isTouchIdAvailable = await BiometricService.isTouchIdAvailable();
      
      AppLogger.info('🔐 [SPLASH] Biometria disponível: $isBiometricAvailable');
      AppLogger.info('🔐 [SPLASH] Face ID disponível: $isFaceIdAvailable');
      AppLogger.info('🔐 [SPLASH] Touch ID disponível: $isTouchIdAvailable');

      if (!mounted) return;

      // 2. Se há biometria disponível (face ou fingerprint), tentar usar biometria primeiro
      // Se não há biometria, usar senha do dispositivo diretamente
      if (isBiometricAvailable && (isFaceIdAvailable || isTouchIdAvailable)) {
        AppLogger.info('🔐 [SPLASH] Biometria disponível - tentando autenticação biométrica');
        await _performBiometricAuth();
      } else {
        // Sem biometria disponível - usar senha do dispositivo diretamente
        AppLogger.info('🔐 [SPLASH] Nenhuma biometria disponível - usando senha do dispositivo');
        await _performDevicePasswordAuth();
      }
    } catch (e) {
      AppLogger.error('Erro ao processar autenticação', e);
      if (mounted) {
        await _logoutAndNavigateToOnboarding();
      }
    } finally {
      _isProcessingBiometric = false;
    }
  }

  /// Realiza autenticação biométrica
  /// Se falhar, tenta senha do dispositivo
  Future<void> _performBiometricAuth() async {
    if (!mounted) return;

    try {
      // Tentar biometria com fallback para senha do dispositivo habilitado
      // No iOS, isso permite que a opção de senha apareça imediatamente após falha do Face ID
      AppLogger.info('🔐 [SPLASH] Tentando autenticação biométrica com fallback para senha...');
      final authenticated = await BiometricService.authenticate(
        reason: 'Use sua biometria para acessar o app',
        allowDevicePassword: true, // Permitir fallback para senha imediatamente
      );

      if (!mounted) return;

      // Verificar novamente se ainda está logado
      final prefs = await SharedPreferences.getInstance();
      final isStillLoggedIn = prefs.getBool('is_logged_in_otp') ?? false;

      if (!isStillLoggedIn) {
        AppLogger.info('🔐 [SPLASH] Estado de login mudou durante autenticação');
        _navigateToOnboarding();
        return;
      }

      if (authenticated) {
        // Autenticação biométrica bem-sucedida - ir para dashboard
        AppLogger.info('✅ [SPLASH] Autenticação biométrica bem-sucedida - redirecionando para dashboard');
        _navigateToDashboard();
      } else {
        // Biometria falhou ou foi cancelada - tentar senha do dispositivo
        AppLogger.warning('❌ [SPLASH] Autenticação biométrica falhou - tentando senha do dispositivo');
        await _performDevicePasswordAuth();
      }
    } catch (e) {
      AppLogger.error('Erro durante autenticação biométrica', e);
      // Se houver erro na biometria, tentar senha do dispositivo
      if (mounted) {
        AppLogger.info('🔄 [SPLASH] Erro na biometria - tentando senha do dispositivo');
        await _performDevicePasswordAuth();
      }
    }
  }

  /// Realiza autenticação com senha do dispositivo
  /// Se falhar, vai para onboarding
  Future<void> _performDevicePasswordAuth() async {
    if (!mounted) return;

    try {
      // Solicitar autenticação com senha do dispositivo
      // O iOS mostrará a tela nativa de senha quando biometricOnly = false
      AppLogger.info('🔐 [SPLASH] Solicitando autenticação com senha do dispositivo...');
      final authenticated = await BiometricService.authenticate(
        reason: 'Use a senha do seu celular para acessar o app',
        allowDevicePassword: true, // Permitir senha do dispositivo
      );

      if (!mounted) return;

      // Verificar novamente se ainda está logado
      final prefs = await SharedPreferences.getInstance();
      final isStillLoggedIn = prefs.getBool('is_logged_in_otp') ?? false;

      if (!isStillLoggedIn) {
        AppLogger.info('🔐 [SPLASH] Estado de login mudou durante autenticação');
        _navigateToOnboarding();
        return;
      }

      if (authenticated) {
        // Autenticação bem-sucedida - ir para dashboard
        AppLogger.info('✅ [SPLASH] Autenticação com senha bem-sucedida - redirecionando para dashboard');
        _navigateToDashboard();
      } else {
        // Autenticação com senha falhou ou foi cancelada - ir para onboarding
        AppLogger.warning('❌ [SPLASH] Autenticação com senha falhou ou foi cancelada - redirecionando para onboarding');
        await _logoutAndNavigateToOnboarding();
      }
    } catch (e) {
      AppLogger.error('Erro durante autenticação com senha', e);
      // Se houver erro na senha também, ir para onboarding
      if (mounted) {
        AppLogger.warning('❌ [SPLASH] Erro na autenticação com senha - redirecionando para onboarding');
        await _logoutAndNavigateToOnboarding();
      }
    }
  }


  /// Faz logout e navega para onboarding
  Future<void> _logoutAndNavigateToOnboarding() async {
    try {
      // Limpar flag de login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in_otp', false);

      // Fazer logout no controller se disponível
      if (widget.authController != null) {
        await widget.authController!.logout();
      }
    } catch (e) {
      AppLogger.error('Erro ao fazer logout', e);
    }

    if (mounted) {
      _navigateToOnboarding();
    }
  }

  /// Navega para tela de onboarding
  void _navigateToOnboarding() {
    if (!mounted) return;

    final authController = widget.authController ?? AuthController();
    final themeController = widget.themeController ?? ThemeController();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OnboardingScreen(
          authController: authController,
          themeController: themeController,
        ),
      ),
    );
  }

  /// Navega para dashboard
  void _navigateToDashboard() {
    if (!mounted) return;

    final authController = widget.authController ?? AuthController();
    final themeController = widget.themeController ?? ThemeController();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainTabScreen(
          authController: authController,
          themeController: themeController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 [SPLASH] Construindo SplashScreen');
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo PagPag centralizado
                    Image.asset(
                      'assets/icons/PagPag_icon.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        AppLogger.error('Erro ao carregar logo: $error', error);
                        return Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.payment,
                            size: 80,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    // Indicador de loading
                    if (_isChecking)
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
