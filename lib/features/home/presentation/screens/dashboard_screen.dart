import 'package:flutter/material.dart';
import '../../../auth/presentation/controllers/auth_controller_real.dart';
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
    // Verificar se o controller ainda está ativo antes de usar
    if (widget.authController.isDisposed) {
      return const Text(
        'Bem-Vindo',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
        textAlign: TextAlign.center,
      );
    }
    
    final userName = widget.authController.currentUser?.displayName ?? 'Daniel';
    return Text(
      'Bem-Vindo, $userName',
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      textAlign: TextAlign.center,
    );
  }
  
  /// Botões principais da tela
  Widget _buildMainButtons(BuildContext context) {
    return Column(
      children: [
        // Botão "Faça uma Venda"
        _buildMainButton(
          context,
          title: 'Faça uma Venda',
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
        
        // Botão "Histórico de Vendas"
        _buildMainButton(
          context,
          title: 'Histórico de Vendas',
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
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppTheme.primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        authController: widget.authController,
                      ),
                    ),
                  );
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
