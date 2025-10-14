import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/controllers/auth_controller_real.dart';
import 'features/auth/presentation/screens/login_screen_new.dart';
import 'features/home/presentation/screens/home_screen.dart';

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

    return ListenableBuilder(
      listenable: _authController!,
      builder: (context, child) {
        if (_authController!.isLoggedIn) {
          return HomeScreen(
            authController: _authController!,
            themeController: widget.themeController,
          );
        }

        return LoginScreenNew(authController: _authController!);
      },
    );
  }
}