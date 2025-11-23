import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/config/env_service.dart';
import 'core/utils/app_logger.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/home/presentation/screens/dashboard_screen.dart';
import 'features/auth/data/services/local_registration_storage.dart';
import 'features/auth/data/services/registration_service.dart';
import 'features/auth/domain/entities/registration_progress.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carregar variáveis de ambiente
  await EnvService.load();

  // Validar chaves obrigatórias
  if (!EnvService.validateRequiredKeys()) {
    AppLogger.error('Falha ao validar variáveis de ambiente');
  }

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  AppLogger.info('App inicializado com sucesso');

  runApp(const NevesCapitalApp());
}

class NevesCapitalApp extends StatefulWidget {
  const NevesCapitalApp({super.key});

  @override
  State<NevesCapitalApp> createState() => _NevesCapitalAppState();
}

class _NevesCapitalAppState extends State<NevesCapitalApp> {
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController();
    _themeController.initialize();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, child) {
        return MaterialApp(
          title: 'Pag Pag',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeController.themeMode,
          home: AppWrapper(themeController: _themeController),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AppWrapper extends StatefulWidget {
  final ThemeController themeController;

  const AppWrapper({
    super.key,
    required this.themeController,
  });

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  AuthController? _authController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAuthController();
  }

  Future<void> _setupAuthController() async {
    _authController = AuthController();
    await _authController!.initialize();
    AppLogger.debug('AuthController inicializado');
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    AppLogger.info('🔔 [GLOBAL] Lifecycle mudou para: $state');

    // Sincroniza progresso local com Firestore quando app vai para background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      AppLogger.info(
          '🔔 [GLOBAL] Detectado app indo para background - iniciando sincronização');
      // Não podemos await aqui, mas a função é executada
      _syncRegistrationProgress();
    }
  }

  Future<void> _syncRegistrationProgress() async {
    try {
      AppLogger.info('🔄 [GLOBAL] Buscando progresso local...');

      final progress = await LocalRegistrationStorage.getLocal();

      if (progress == null) {
        AppLogger.debug(
            '🔄 [GLOBAL] Nenhum progresso local encontrado - nada a sincronizar');
        return;
      }

      AppLogger.info(
          '🔄 [GLOBAL] Progresso encontrado: step=${progress.currentStep}, status=${progress.status}');

      if (progress.status != RegistrationStatus.inProgress) {
        AppLogger.debug(
            '🔄 [GLOBAL] Progresso não está in_progress - ignorando sincronização');
        return;
      }

      AppLogger.info('🔄 [GLOBAL] INICIANDO sincronização com Firestore...');
      await RegistrationService.saveProgress(progress);
      AppLogger.info('✅ [GLOBAL] Progresso sincronizado com SUCESSO!');
    } catch (e, stackTrace) {
      AppLogger.error(
          '❌ [GLOBAL] ERRO ao sincronizar progresso: $e', stackTrace);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_authController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Verificar se o controller ainda está ativo antes de usar
    if (_authController!.isDisposed) {
      return const Scaffold(
        body: Center(
          child: Text('Sessão expirada'),
        ),
      );
    }

    return ListenableBuilder(
      listenable: _authController!,
      builder: (context, child) {
        // Debug: verificar estado de autenticação
        AppLogger.debug(
            'AppWrapper reconstruindo - isLoggedIn: ${_authController!.isLoggedIn}');

        // Mostrar a tela correspondente ao estado atual
        if (_authController!.isLoggedIn) {
          AppLogger.debug('Navegando para DashboardScreen');
          return DashboardScreen(
            authController: _authController!,
            themeController: widget.themeController,
          );
        }

        AppLogger.debug('Navegando para OnboardingScreen (usuário deslogado)');
        return OnboardingScreen(
          authController: _authController!,
          themeController: widget.themeController,
        );
      },
    );
  }
}
