import 'package:flutter/material.dart';

/// Splash screen usando a mesma tela verde escura do reconhecimento facial
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02391E), // Verde escuro PagPag
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo PagPag centralizado
              Image.asset(
                'assets/icons/PagPag_icon.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

