import 'package:flutter/material.dart';

/// Splash screen usando a mesma tela verde escura do reconhecimento facial
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundo verde escuro PagPag - mesmo da tela de onboarding
      backgroundColor: const Color(0xFF02391E),
      body: Container(
        // Adicionar imagem de fundo se disponível (opcional)
        decoration: const BoxDecoration(
          color: Color(0xFF02391E), // Verde escuro PagPag
        ),
        child: SafeArea(
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
                  errorBuilder: (context, error, stackTrace) {
                    // Se a imagem não carregar, mostrar um ícone placeholder
                    return const Icon(
                      Icons.payment,
                      size: 150,
                      color: Colors.white,
                    );
                  },
                ),
                const SizedBox(height: 40),
                // Indicador de loading
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

