import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/components/glass_card.dart';

/// Tela principal do dashboard moderna baseada no React
class DashboardScreen extends StatelessWidget {
  final AuthController authController;
  final ThemeController themeController;
  
  const DashboardScreen({
    super.key,
    required this.authController,
    required this.themeController,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header com glass effect
            _buildHeader(context),
            
            // Conteúdo principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seção de boas-vindas
                    _buildWelcomeSection(context),
                    
                    const SizedBox(height: 32),
                    
                    // Grid de estatísticas
                    _buildStatsGrid(context),
                    
                    const SizedBox(height: 32),
                    
                    // Ações rápidas
                    _buildQuickActions(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Header moderno com glass effect
  Widget _buildHeader(BuildContext context) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 100),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.glassBackground,
          border: Border(
            bottom: BorderSide(color: AppTheme.glassBorder, width: 1),
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Logo e título
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.show_chart_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'Bem-vindo de volta!',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Botão de logout
                  IconButton(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppTheme.destructiveColor,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.destructiveColor.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Seção de boas-vindas com gradiente
  Widget _buildWelcomeSection(BuildContext context) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListenableBuilder(
            listenable: authController,
            builder: (context, child) {
              final userName = authController.currentUser?.name ?? 'Usuário';
              return RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Olá, ',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    TextSpan(
                      text: userName,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.accentColor],
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                      ),
                    ),
                    TextSpan(
                      text: '! 👋',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Aqui está um resumo das suas atividades hoje.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
  
  /// Grid de estatísticas com glass effect
  Widget _buildStatsGrid(BuildContext context) {
    final stats = [
      {
        'label': 'Usuários ativos',
        'value': '2.847',
        'icon': Icons.people_rounded,
        'trend': '+12%',
        'trendColor': AppTheme.successColor,
      },
      {
        'label': 'Receita mensal',
        'value': 'R\$ 48.2k',
        'icon': Icons.trending_up_rounded,
        'trend': '+8.3%',
        'trendColor': AppTheme.successColor,
      },
      {
        'label': 'Projetos',
        'value': '127',
        'icon': Icons.inventory_2_rounded,
        'trend': '+23%',
        'trendColor': AppTheme.successColor,
      },
      {
        'label': 'Performance',
        'value': '98.5%',
        'icon': Icons.analytics_rounded,
        'trend': '+2.1%',
        'trendColor': AppTheme.successColor,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return FadeInAnimation(
          delay: Duration(milliseconds: 300 + (index * 100)),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stat['label'] as String,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.primaryColor.withOpacity(0.1),
                      ),
                      child: Icon(
                        stat['icon'] as IconData,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  stat['value'] as String,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: stat['trendColor'] as Color,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stat['trend']} vs mês anterior',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: stat['trendColor'] as Color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// Seção de ações rápidas
  Widget _buildQuickActions(BuildContext context) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 700),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: AppTheme.primaryColor,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Ações Rápidas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Gerencie sua conta e configurações',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.people_rounded,
                    title: 'Gerenciar\nUsuários',
                    onTap: () {
                      // TODO: Implementar navegação
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.analytics_rounded,
                    title: 'Ver\nRelatórios',
                    onTap: () {
                      // TODO: Implementar navegação
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.settings_rounded,
                    title: 'Configurações',
                    onTap: () {
                      // TODO: Implementar navegação
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Botão de ação rápida
  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Método para logout
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(
          'Logout',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Tem certeza que deseja sair?',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              authController.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.destructiveColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
  
}
