import 'package:flutter/material.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../payment/presentation/screens/payment_step1_screen.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'sales_history_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/services/firestore_service.dart';
import '../../../../shared/services/secure_storage_service.dart';
import '../../../auth/presentation/screens/onboarding_screen.dart';

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
  String? _userDisplayName;
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  /// Carregar nome do usuário do Firestore
  Future<void> _loadUserName() async {
    try {
      // Buscar CPF do SecureStorage
      final cpf = await SecureStorageService.getLastCpf();
      if (cpf == null || cpf.isEmpty) {
        AppLogger.warning('CPF não encontrado - fazendo logout e redirecionando');
        await _handleUserNotFound();
        return;
      }

      // Buscar dados do usuário no Firestore
      final userData = await FirestoreService.getUserByCpf(cpf);
      
      if (userData == null) {
        AppLogger.warning('Usuário não encontrado no Firestore - fazendo logout e redirecionando');
        await _handleUserNotFound();
        return;
      }
      
      if (userData['displayName'] != null) {
        final displayName = userData['displayName'] as String;
        // Pegar os dois primeiros nomes
        final nameParts = displayName.trim().split(' ');
        final twoFirstNames = nameParts.length >= 2 
            ? '${nameParts[0]} ${nameParts[1]}'
            : nameParts[0];
        
        setState(() {
          _userDisplayName = twoFirstNames;
          _isLoadingName = false;
        });
        AppLogger.debug('Nome do usuário carregado: $twoFirstNames');
      } else {
        AppLogger.warning('DisplayName não encontrado no Firestore');
        setState(() {
          _userDisplayName = null;
          _isLoadingName = false;
        });
      }
    } catch (e) {
      AppLogger.error('Erro ao carregar nome do usuário', e);
      // Se houver erro crítico, fazer logout
      await _handleUserNotFound();
    }
  }

  /// Lidar com usuário não encontrado - fazer logout e redirecionar
  Future<void> _handleUserNotFound() async {
    if (!mounted) return;
    
    AppLogger.info('DashboardScreen: Usuário não encontrado - fazendo logout e redirecionando');
    
    try {
      // Fazer logout
      if (!widget.authController.isDisposed) {
        await widget.authController.logout();
      }
    } catch (e) {
      AppLogger.error('Erro ao fazer logout', e);
    }
    
    // Aguardar um pouco
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Redirecionar para OnboardingScreen
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => OnboardingScreen(
            authController: widget.authController,
            themeController: widget.themeController,
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loading enquanto os dados do usuário estão sendo carregados
    if (_isLoadingName) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
              const SizedBox(height: 24),
              Text(
                'Carregando...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return SafeArea(
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
    );
  }
  
  /// Mensagem de boas-vindas
  Widget _buildWelcomeMessage(BuildContext context) {
    String userName = 'Usuário';
    
    // Usar nome carregado do Firestore se disponível
    if (_userDisplayName != null && _userDisplayName!.isNotEmpty) {
      userName = _userDisplayName!;
    } else {
      // Se não carregou do Firestore, tentar do Firebase Auth como fallback
      try {
        if (!widget.authController.isDisposed && widget.authController.currentUser != null) {
          final user = widget.authController.currentUser!;
          
          if (user.displayName != null && user.displayName!.isNotEmpty) {
            final nameParts = user.displayName!.trim().split(' ');
            userName = nameParts.length >= 2 
                ? '${nameParts[0]} ${nameParts[1]}'
                : nameParts[0];
          } else if (user.email != null) {
            userName = user.email!.split('@').first;
          }
        }
      } catch (e) {
        AppLogger.warning('Erro ao obter nome do Firebase Auth: $e');
      }
    }
    
    return Column(
      children: [
        // Usar FittedBox para garantir que o texto não quebre a linha
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Olá, $userName 👋',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
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
          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
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
  
}
