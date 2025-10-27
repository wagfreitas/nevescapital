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
    String userName = 'Usuário';
    
    // Verificar se o controller ainda está ativo antes de usar
    try {
      if (!widget.authController.isDisposed && widget.authController.currentUser != null) {
        final user = widget.authController.currentUser!;
        
        // Tentar pegar o nome de várias formas
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          // Pegar apenas o primeiro nome
          userName = user.displayName!.split(' ').first;
          print('👤 Nome do usuário obtido do displayName: $userName');
        } else if (user.email != null) {
          // Se não tem displayName, usar a parte antes do @ do email
          userName = user.email!.split('@').first;
          print('⚠️ Nome obtido do email (displayName vazio): $userName');
          print('⚠️ displayName: "${user.displayName}", email: "${user.email}"');
        }
        
        print('👤 Nome final exibido: $userName');
      } else {
        print('⚠️ Usuário não encontrado no authController');
        print('⚠️ isDisposed: ${widget.authController.isDisposed}');
        print('⚠️ currentUser: ${widget.authController.currentUser?.uid}');
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
                  print('');
                  print('👤 CLICOU EM CONTA');
                  print('👤 authController.isDisposed: ${widget.authController.isDisposed}');
                  print('👤 authController.currentUser: ${widget.authController.currentUser?.uid}');
                  print('👤 authController.isLoggedIn: ${widget.authController.isLoggedIn}');
                  
                  // Verificar se o usuário está logado e o controller está válido
                  if (widget.authController.isLoggedIn && !widget.authController.isDisposed) {
                    print('👤 Navegando para ProfileScreen...');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          authController: widget.authController,
                        ),
                      ),
                    );
                    print('👤 Navegação para ProfileScreen concluída');
                  } else {
                    print('⚠️ Não é possível navegar - usuário não logado ou controller inválido');
                    print('⚠️ isLoggedIn: ${widget.authController.isLoggedIn}');
                    print('⚠️ isDisposed: ${widget.authController.isDisposed}');
                    // Não fazer nada - o AppWrapper vai lidar com o estado
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
