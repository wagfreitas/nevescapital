import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/config/env_service.dart';
import 'core/utils/app_logger.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/auth/data/services/local_registration_storage.dart';
import 'features/auth/data/services/registration_service.dart';
import 'features/auth/domain/entities/registration_progress.dart';
import 'shared/services/keyboard_accessory_service.dart';
import 'shared/screens/splash_screen.dart';

void main() async {
  // Garantir que o binding está inicializado primeiro
  WidgetsFlutterBinding.ensureInitialized();

  // Tratamento de erros global - configurar ANTES de qualquer outra coisa
  FlutterError.onError = (FlutterErrorDetails details) {
    // Verificar se é erro de overflow (são avisos visuais, não erros críticos)
    final exceptionString = details.exception.toString().toLowerCase();
    final stackString = details.stack?.toString().toLowerCase() ?? '';
    final isOverflowError = exceptionString.contains('overflow') ||
        stackString.contains('overflow') ||
        stackString.contains('debugoverflowindicatormixin');
    
    if (isOverflowError) {
      // Apenas logar como aviso, não mostrar erro crítico
      debugPrint('⚠️ Overflow detectado (não crítico): ${details.exception}');
      // Não chamar FlutterError.presentError para overflow
      return;
    }
    
    // Em modo debug, mostrar o erro normalmente
    FlutterError.presentError(details);
    // Tentar logar, mas não falhar se o logger não estiver pronto
    try {
      AppLogger.error('Erro Flutter não tratado', details.exception, details.stack);
    } catch (_) {
      // Se o logger falhar, pelo menos printar
      debugPrint('Erro Flutter: ${details.exception}');
    }
  };

  // Tratamento de erros assíncronos
  PlatformDispatcher.instance.onError = (error, stack) {
    try {
      AppLogger.error('Erro assíncrono não tratado', error, stack);
    } catch (_) {
      debugPrint('Erro assíncrono: $error');
    }
    return true;
  };

  try {
    // Carregar variáveis de ambiente (não crítico se falhar)
    try {
      await EnvService.load();
    } catch (e) {
      debugPrint('Aviso: Erro ao carregar .env: $e');
    }

    // Validar chaves obrigatórias (não crítico, apenas aviso)
    try {
      if (!EnvService.validateRequiredKeys()) {
        debugPrint('Aviso: Algumas variáveis de ambiente não estão configuradas');
      }
    } catch (e) {
      debugPrint('Aviso: Erro ao validar chaves: $e');
    }

    // Inicializar Firebase (evitar duplicação)
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Firebase initialization timeout');
          },
        );
      }
    } catch (e) {
      debugPrint('Erro ao inicializar Firebase: $e');
      // Continuar mesmo se Firebase falhar - o app pode funcionar parcialmente
    }

    // Inicializar keyboard accessory nativo (iOS)
    try {
      await KeyboardAccessoryService.instance.initialize();
      // Configurar com o tema do app - cor que combina com o teclado numérico
      await KeyboardAccessoryService.instance.configure(
        buttonText: 'OK',
        buttonColor: '#007AFF', // Azul iOS padrão
        toolbarColor: '#D1D1D6', // Cinza que combina com o teclado numérico (sem bordas arredondadas)
      );
      await KeyboardAccessoryService.instance.enable();
      debugPrint('✅ Keyboard accessory inicializado e ativado');
    } catch (e) {
      debugPrint('Aviso: Erro ao inicializar keyboard accessory: $e');
    }

    AppLogger.info('App inicializado com sucesso');

    runApp(const NevesCapitalApp());
  } catch (e, stackTrace) {
    // Último recurso: tentar rodar o app mesmo com erro
    debugPrint('Erro fatal na inicialização: $e');
    debugPrint('Stack trace: $stackTrace');
    
    try {
      AppLogger.error('Erro fatal na inicialização do app', e, stackTrace);
    } catch (_) {
      // Se até o logger falhar, continuar
    }
    
    // Em caso de erro fatal, ainda tentamos rodar o app com uma tela de erro
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Erro ao inicializar aplicativo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NevesCapitalApp extends StatefulWidget {
  const NevesCapitalApp({super.key});

  @override
  State<NevesCapitalApp> createState() => _NevesCapitalAppState();
}

class _NevesCapitalAppState extends State<NevesCapitalApp> {
  late final ThemeController _themeController;
  bool _isThemeInitialized = false;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController();
    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    try {
      await _themeController.initialize();
      if (mounted) {
        setState(() {
          _isThemeInitialized = true;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao inicializar tema', e, stackTrace);
      if (mounted) {
        setState(() {
          _isThemeInitialized = true; // Continua mesmo com erro
        });
      }
    }
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loading enquanto tema não está inicializado
    if (!_isThemeInitialized) {
      return MaterialApp(
        title: 'Pag Pag',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

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
    try {
      _authController = AuthController();
      AppLogger.info('🔐 [MAIN] Iniciando AuthController.initialize()...');
      // Adicionar timeout para evitar travamento
      await _authController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          AppLogger.warning('AuthController initialization timeout');
          throw TimeoutException('AuthController initialization timeout');
        },
      );
      AppLogger.info('🔐 [MAIN] AuthController inicializado com sucesso');
      AppLogger.info('🔐 [MAIN] Estado após inicialização:');
      AppLogger.info('  - isLoggedIn: ${_authController!.isLoggedIn}');
      AppLogger.info('  - currentUser: ${_authController!.currentUser != null}');
      if (mounted) {
        setState(() {});
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ [MAIN] Erro ao inicializar AuthController', e, stackTrace);
      // Criar um controller vazio para evitar tela branca
      // Tentar inicializar novamente sem timeout para garantir que funcione
      try {
        _authController = AuthController();
        // Tentar inicializar sem timeout, mas com tratamento de erro
        await _authController!.initialize().catchError((error) {
          AppLogger.error('Erro na segunda tentativa de inicialização', error);
        });
        AppLogger.info('🔐 [MAIN] AuthController inicializado na segunda tentativa');
      } catch (_) {
        // Se até isso falhar, criar um controller básico
        _authController = AuthController();
        AppLogger.warning('🔐 [MAIN] AuthController criado sem inicialização');
      }
      if (mounted) {
        setState(() {});
      }
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
          '❌ [GLOBAL] ERRO ao sincronizar progresso: $e', e, stackTrace);
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

        // SEMPRE passar pelo OnboardingScreen primeiro
        // O OnboardingScreen verifica biometria se usuário está logado
        // e redireciona para Dashboard apenas após validação biométrica
        AppLogger.debug('Navegando para OnboardingScreen (verificação de biometria e cadastro pendente)');
        return OnboardingScreen(
          authController: _authController!,
          themeController: widget.themeController,
        );
      },
    );
  }
}
