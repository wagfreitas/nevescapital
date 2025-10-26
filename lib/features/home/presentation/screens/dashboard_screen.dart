import 'package:flutter/material.dart';
import '../../../auth/presentation/controllers/auth_controller_real.dart';
import '../../../auth/presentation/screens/onboarding_screen.dart';
import '../../../payment/presentation/screens/payment_step1_screen.dart';
import 'sales_history_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_controller.dart';

/// Tela principal do dashboard moderna baseada no React
class DashboardScreen extends StatefulWidget {
  final AuthController authController;
  final ThemeController themeController;
  
  const DashboardScreen({
    super.key,
    required this.authController,
    required this.themeController,
  });
  
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Conteúdo principal
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mensagem de boas-vindas
                    _buildWelcomeMessage(context),
                    
                    const SizedBox(height: 60),
                    
                    // Botões principais
                    _buildMainButtons(context),
                  ],
                ),
              ),
            ),
            
            // Barra de navegação inferior
            _buildBottomNavigation(context),
          ],
        ),
      ),
    );
  }
  
  /// Mensagem de boas-vindas
  Widget _buildWelcomeMessage(BuildContext context) {
    String userName = 'Daniel';
    
    // Verificar se o controller ainda está ativo antes de usar
    try {
      if (!widget.authController.isDisposed) {
        userName = widget.authController.currentUser?.displayName ?? 'Daniel';
      }
    } catch (e) {
      print('⚠️ Erro ao acessar authController: $e');
    }
    
    return Column(
      children: [
        Text(
          'Olá, $userName 👋',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Receba sua venda em segundos no PIX!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  /// Botões principais da tela
  Widget _buildMainButtons(BuildContext context) {
    return Column(
      children: [
        // Botão "Nova Venda"
        _buildMainButton(
          context,
          title: 'Nova Venda',
          icon: Icons.credit_card,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaymentStep1Screen(),
              ),
            );
          },
        ),
        
        const SizedBox(height: 20),
        
        // Botão "Histórico"
        _buildMainButton(
          context,
          title: 'Histórico',
          icon: Icons.description,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SalesHistoryScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
  
  /// Botão principal estilizado
  Widget _buildMainButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppTheme.primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  /// Barra de navegação inferior
  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Botão Vendas (ativo)
              _buildNavButton(
                context,
                icon: Icons.check_circle,
                label: 'Vendas',
                isActive: true,
                onTap: () {
                  // Já estamos na tela de vendas
                },
              ),
              
              // Botão Conta
              _buildNavButton(
                context,
                icon: Icons.person,
                label: 'Conta',
                isActive: false,
                onTap: () {
                  try {
                    // Verificar se o controller ainda está ativo antes de navegar
                    if (widget.authController.isDisposed) {
                      // Sessão expirada - navegar para onboarding
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => OnboardingScreen(
                            authController: widget.authController,
                            themeController: widget.themeController,
                          ),
                        ),
                        (route) => false,
                      );
                      return;
                    }
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          authController: widget.authController,
                        ),
                      ),
                    );
                  } catch (e) {
                    print('⚠️ Erro ao navegar para ProfileScreen: $e');
                    // Em caso de erro, navegar para onboarding
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => OnboardingScreen(
                          authController: widget.authController,
                          themeController: widget.themeController,
                        ),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Botão de navegação inferior
  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryColor : Colors.grey[600],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? AppTheme.primaryColor : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
}
