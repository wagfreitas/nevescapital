import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'edit_personal_data_screen.dart';
import 'edit_store_data_screen.dart';
import 'edit_pix_keys_screen.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import '../../../auth/presentation/screens/onboarding_screen.dart';
import '../../../../core/theme/theme_controller.dart';

/// Tela de perfil do usuário
class ProfileScreen extends StatefulWidget {
  final AuthController authController;
  final bool showAppBar;
  
  const ProfileScreen({
    super.key,
    required this.authController,
    this.showAppBar = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    AppLogger.debug('ProfileScreen - BUILD iniciado');
    
    // Tentar acessar o controller apenas quando necessário
    // Se houver erro, mostrar mensagem de erro mas não redirecionar automaticamente
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título "Conta" quando AppBar não está visível
            if (!widget.showAppBar) ...[
              const SizedBox(height: 20),
              const Text(
                'Conta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ] else
              const SizedBox(height: 40),
              
              // Pergunta
              const Text(
                'O que deseja alterar?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Opções do perfil
              _buildOptionCard(
                context,
                icon: Icons.person,
                title: 'Dados Pessoais',
                subtitle: 'Email, telefone, endereço',
                showLeftIcon: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPersonalDataScreen(
                        authController: widget.authController,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildOptionCard(
                context,
                icon: Icons.store,
                title: 'Dados da Loja',
                subtitle: 'Nome, ramo de atividade',
                showLeftIcon: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditStoreDataScreen(
                        authController: widget.authController,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildOptionCard(
                context,
                icon: Icons.pix,
                title: 'Chave Pix',
                subtitle: 'Gerenciar chaves cadastradas',
                showLeftIcon: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditPixKeysScreen(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // Botão de logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
  }
  
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Saída'),
        content: const Text('Tem certeza que deseja sair da aplicação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Fechar dialog primeiro
              Navigator.of(context).pop();
              
              // Aguardar um frame para garantir que o dialog foi fechado
              await Future.delayed(const Duration(milliseconds: 100));
              
              if (!context.mounted) return;
              
              AppLogger.info('ProfileScreen: Iniciando logout...');
              
              // Forçar logout de forma mais direta
              try {
                // 1. Limpar SharedPreferences diretamente
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('is_logged_in_otp');
                await prefs.clear();
                AppLogger.info('SharedPreferences limpo');
                
                // 2. Fazer logout no controller
                if (!widget.authController.isDisposed) {
                  await widget.authController.logout().timeout(
                    const Duration(seconds: 5),
                    onTimeout: () {
                      AppLogger.warning('Logout timeout - continuando mesmo assim');
                    },
                  );
                }
                
                // 3. Forçar limpeza do estado
                widget.authController.clearState();
                
              } catch (e) {
                AppLogger.error('Erro no logout', e);
                // Continuar mesmo com erro
              }
              
              // Aguardar um pouco para garantir que tudo foi processado
              await Future.delayed(const Duration(milliseconds: 500));
              
              // Navegar SEMPRE para OnboardingScreen
              if (context.mounted) {
                AppLogger.info('ProfileScreen: Navegando para OnboardingScreen');
                
                // Criar novo controller para garantir estado limpo
                final newAuthController = AuthController();
                await newAuthController.initialize();
                
                // Se ainda estiver logado, forçar logout
                if (newAuthController.isLoggedIn) {
                  await newAuthController.logout();
                  await Future.delayed(const Duration(milliseconds: 200));
                }
                
                // Navegar usando rootNavigator para garantir que remove todas as rotas
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => OnboardingScreen(
                      authController: newAuthController,
                      themeController: ThemeController(),
                    ),
                  ),
                  (route) => false,
                );
              }
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showLeftIcon = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Ícone à esquerda (se solicitado) - substitui o container
              if (showLeftIcon)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    icon,
                    color: const Color(0xFF22C55E), // Verde vibrante
                    size: 32,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

}