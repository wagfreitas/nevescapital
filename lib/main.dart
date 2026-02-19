import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/config/env_service.dart';
import 'core/utils/app_logger.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/data/services/local_registration_storage.dart';
import 'features/auth/data/services/registration_service.dart';
import 'features/auth/domain/entities/registration_progress.dart';
import 'shared/services/keyboard_accessory_service.dart';
import 'shared/screens/splash_screen.dart';

void main() async {
  // Garantir que o binding está inicializado primeiro
  WidgetsFlutterBinding.ensureInitialized();
  
  // Bloquear rotação de tela - manter apenas portrait (em pé)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Forçar status bar transparente globalmente
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

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

  // Executar runApp IMEDIATAMENTE para não bloquear o Dart VM Service
  debugPrint('🚀 [MAIN] Chamando runApp()...');
  runApp(const NevesCapitalApp());
  debugPrint('✅ [MAIN] runApp() concluído');

  // Inicializações em background (não bloqueiam o app)
  _initializeAppInBackground();
}

/// Inicializa componentes do app em background (não bloqueia o startup)
void _initializeAppInBackground() {
  // Executar em background sem bloquear
  Future.microtask(() async {
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

      // Inicializar Firebase (evitar duplicação) - com timeout mais curto
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ).timeout(
            const Duration(seconds: 5),
          );
        }
      } on TimeoutException {
        debugPrint('Firebase initialization timeout - continuando sem Firebase');
      } catch (e) {
        debugPrint('Erro ao inicializar Firebase: $e');
        // Continuar mesmo se Firebase falhar - o app pode funcionar parcialmente
      }

      // Inicializar keyboard accessory nativo (iOS) - não crítico
      try {
        await KeyboardAccessoryService.instance.initialize().timeout(
          const Duration(seconds: 2),
        );
        // Configurar com o tema do app - cor que combina com o teclado numérico
        await KeyboardAccessoryService.instance.configure(
          buttonText: 'OK',
          buttonColor: '#007AFF', // Azul iOS padrão
          toolbarColor: '#D1D1D6', // Cinza que combina com o teclado numérico (sem bordas arredondadas)
        ).timeout(
          const Duration(seconds: 1),
        );
        await KeyboardAccessoryService.instance.enable().timeout(
          const Duration(seconds: 1),
        );
        debugPrint('✅ Keyboard accessory inicializado e ativado');
      } on TimeoutException {
        debugPrint('Keyboard accessory timeout - continuando');
      } catch (e) {
        debugPrint('Aviso: Erro ao inicializar keyboard accessory: $e');
      }

      AppLogger.info('App inicializado com sucesso');
    } catch (e) {
      debugPrint('Erro na inicialização em background: $e');
    }
  });
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
    // Restaurar orientações quando o app for fechado
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 [THEME] Construindo NevesCapitalApp - isThemeInitialized: $_isThemeInitialized');
    // Mostrar loading enquanto tema não está inicializado
    if (!_isThemeInitialized) {
      debugPrint('🎨 [THEME] Mostrando SplashScreen enquanto tema carrega');
      return MaterialApp(
        title: 'Pag Pag',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        // Localização pt-BR para DatePicker, TimePicker, etc.
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pt', 'BR'),
          Locale('en', 'US'),
        ],
        locale: const Locale('pt', 'BR'),
        // Builder global para fechar teclado ao tocar em qualquer parte do body
        builder: (context, child) {
          return GestureDetector(
            onTap: () {
              // Fechar teclado ao tocar em qualquer área vazia
              FocusScope.of(context).unfocus();
            },
            behavior: HitTestBehavior.translucent,
            child: child ?? const SizedBox.shrink(),
          );
        },
      );
    }

    debugPrint('🎨 [THEME] Tema inicializado, mostrando AppWrapper');
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
          // Localização pt-BR para DatePicker, TimePicker, etc.
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('en', 'US'),
          ],
          locale: const Locale('pt', 'BR'),
          // Builder global para fechar teclado ao tocar em qualquer parte do body
          builder: (context, child) {
            return GestureDetector(
              onTap: () {
                // Fechar teclado ao tocar em qualquer área vazia
                FocusScope.of(context).unfocus();
              },
              behavior: HitTestBehavior.translucent,
              child: child ?? const SizedBox.shrink(),
            );
          },
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
      // Reduzir timeout para 5 segundos e continuar mesmo se falhar
      await _authController!.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          AppLogger.warning('AuthController initialization timeout - continuando sem inicialização completa');
          // Não lançar exceção, apenas continuar
        },
      ).catchError((error) {
        AppLogger.warning('AuthController initialization error - continuando: $error');
        // Continuar mesmo com erro
      });
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

    // NÃO usar ListenableBuilder aqui!
    // O SplashScreen é o ponto de entrada único — ele verifica login + biometria
    // e faz navegação imperativa (pushReplacement) para Dashboard ou Onboarding.
    // Se usarmos ListenableBuilder no AuthController, qualquer notifyListeners()
    // recria o SplashScreen, causando loop de verificação/biometria.
    AppLogger.debug('AppWrapper: Exibindo SplashScreen (entrada única)');
    return SplashScreen(
      authController: _authController!,
      themeController: widget.themeController,
    );
  }
}
