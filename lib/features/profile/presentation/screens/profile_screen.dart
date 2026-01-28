import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'edit_personal_data_screen.dart';
import 'edit_store_data_screen.dart';
import 'bank_account_screen.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import '../../../auth/presentation/screens/onboarding_screen.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/services/auth_service.dart';

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
                subtitle: 'Email & Endereço',
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
                subtitle: 'Nome & Ramo de Atuação',
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
                icon: Icons.account_balance,
                title: 'Dados Bancários',
                subtitle: 'Gerenciar Dados Bancários',
                showLeftIcon: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BankAccountScreen(),
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
    // Capturar o contexto do widget ANTES de qualquer operação assíncrona
    final widgetContext = context;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Saída'),
        content: const Text('Tem certeza que deseja sair da aplicação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Fechar dialog primeiro usando o contexto do dialog
              Navigator.of(dialogContext).pop();
              
              // Aguardar um frame para garantir que o dialog foi fechado
              await Future.delayed(const Duration(milliseconds: 100));
              
              // Usar o contexto do widget (ProfileScreen) que é mais estável
              if (!widgetContext.mounted) {
                AppLogger.warning('Context não está montado - tentando usar rootNavigator');
                // Se o contexto não estiver montado, tentar usar o rootNavigator diretamente
                final navigator = Navigator.maybeOf(widgetContext, rootNavigator: true);
                if (navigator == null) {
                  AppLogger.error('Não foi possível obter Navigator');
                  return;
                }
              }
              
              AppLogger.info('ProfileScreen: Iniciando logout...');
              
              // 1. GARANTIR que a flag is_logged_in_otp está FALSE no SharedPreferences (PRIMEIRO PASSO)
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_logged_in_otp', false);
                AppLogger.info('✅ Flag is_logged_in_otp definida como FALSE no SharedPreferences');
              } catch (e) {
                AppLogger.error('Erro ao definir flag', e);
              }
              
              // 2. Fazer logout completo no controller
              try {
                if (!widget.authController.isDisposed) {
                  await widget.authController.logout();
                  AppLogger.info('✅ Logout realizado no controller');
                }
              } catch (e) {
                AppLogger.error('Erro no logout do controller', e);
              }
              
              // 3. GARANTIR que o Firebase também está limpo
              try {
                await AuthService.signOut();
                AppLogger.info('✅ Firebase signOut realizado');
              } catch (e) {
                AppLogger.error('Erro ao fazer signOut do Firebase', e);
              }
              
              // 4. Criar NOVO AuthController limpo ANTES de navegar
              final newAuthController = AuthController();
              await newAuthController.initialize();
              
              // 5. Verificar se a flag está realmente FALSE
              final prefs = await SharedPreferences.getInstance();
              final flagValue = prefs.getBool('is_logged_in_otp') ?? false;
              AppLogger.info('Verificação final da flag: $flagValue');
              
              // 6. NAVEGAR DIRETAMENTE para OnboardingScreen usando rootNavigator
              // Usar rootNavigator sempre para garantir que funciona independente do contexto
              AppLogger.info('ProfileScreen: Navegando DIRETAMENTE para OnboardingScreen');
              
              // Obter o Navigator do root sempre, independente do contexto atual
              final rootNavigator = Navigator.maybeOf(widgetContext, rootNavigator: true) ??
                                   Navigator.of(widgetContext, rootNavigator: true);
              
              rootNavigator.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => OnboardingScreen(
                    authController: newAuthController,
                    themeController: ThemeController(),
                  ),
                ),
                (route) => false,
              );
              
              AppLogger.info('✅ Navegação para OnboardingScreen concluída');
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
                    color: AppTheme.primaryColor, // Verde vibrante
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