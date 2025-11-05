import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/home/presentation/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

class _AppWrapperState extends State<AppWrapper> {
  AuthController? _authController;

  @override
  void initState() {
    super.initState();
    _setupAuthController();
  }

  Future<void> _setupAuthController() async {
    _authController = AuthController();
    await _authController!.initialize();
    print('🔍 AppWrapper - AuthController inicializado');
    print('🔍 AppWrapper - isLoggedIn: ${_authController!.isLoggedIn}');
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
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
        print('');
        print('🏗️ AppWrapper - RECONSTRUINDO');
        print('🏗️ isLoggedIn: ${_authController!.isLoggedIn}');
        print('🏗️ currentUser: ${_authController!.currentUser?.uid}');

        // Mostrar a tela correspondente ao estado atual
        if (_authController!.isLoggedIn) {
          print('🏗️ RETORNANDO: DashboardScreen');
          print('');
          return DashboardScreen(
            authController: _authController!,
            themeController: widget.themeController,
          );
        }

        print('🏗️ RETORNANDO: OnboardingScreen (usuário deslogado)');
        print('');
        return OnboardingScreen(
          authController: _authController!,
          themeController: widget.themeController,
        );
      },
    );
  }
}