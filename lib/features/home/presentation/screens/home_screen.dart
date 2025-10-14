import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller_real.dart';

class HomeScreen extends StatelessWidget {
  final AuthController authController;
  final ThemeController themeController;

  const HomeScreen({
    super.key,
    required this.authController,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Pag Pag'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authController.logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24.0),
            _buildBalanceCard(),
            const SizedBox(height: 24.0),
            _buildQuickActions(context),
            const SizedBox(height: 24.0),
            _buildRecentTransactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bem-vindo ao Pag Pag!',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Olá, ${authController.currentUser?.displayName ?? 'Usuário'}!',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Seu cadastro foi realizado com sucesso e está em análise.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo Disponível',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.backgroundColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'R\$ 0,00',
            style: AppTheme.lightTheme.textTheme.headlineLarge?.copyWith(
              color: AppTheme.backgroundColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Aguarde a aprovação do seu cadastro para começar a usar o Pag Pag.',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.backgroundColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.pix,
                label: 'PIX',
                onTap: () => _showComingSoon(context),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: _buildActionButton(
                icon: Icons.credit_card,
                label: 'Cartão',
                onTap: () => _showComingSoon(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.qr_code,
                label: 'QR Code',
                onTap: () => _showComingSoon(context),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: _buildActionButton(
                icon: Icons.history,
                label: 'Histórico',
                onTap: () => _showComingSoon(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.cardColor,
        foregroundColor: AppTheme.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 0,
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8.0),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transações Recentes',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long,
                size: 48,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 8.0),
              Text(
                'Nenhuma transação ainda',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Suas transações aparecerão aqui',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}