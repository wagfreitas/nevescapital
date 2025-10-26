import 'package:flutter/material.dart';
import '../../../auth/presentation/controllers/auth_controller_real.dart';
import '../../../auth/presentation/screens/onboarding_screen.dart';
import '../../../../core/theme/theme_controller.dart';

/// Tela de perfil do usuário
class ProfileScreen extends StatefulWidget {
  final AuthController authController;
  
  const ProfileScreen({
    super.key,
    required this.authController,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Listener removido - o logout já navega explicitamente para Onboarding

  @override
  Widget build(BuildContext context) {
    print('');
    print('🟣 ProfileScreen - BUILD iniciado');
    print('🟣 authController.isDisposed: ${widget.authController.isDisposed}');
    print('🟣 authController.currentUser: ${widget.authController.currentUser?.uid}');
    print('🟣 authController.isLoggedIn: ${widget.authController.isLoggedIn}');
    
    // Verificar se o controller ainda está ativo antes de usar
    try {
      if (widget.authController.isDisposed) {
        print('🟣 Controller disposed - mostrando tela de erro');
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Conta'),
            centerTitle: true,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Sessão expirada',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        );
      }

      final user = widget.authController.currentUser;
      
      if (user == null) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Conta'),
            centerTitle: true,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Usuário não encontrado',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      print('⚠️ Erro ao acessar authController no build: $e');
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Conta'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Erro ao carregar perfil',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    // Se chegou aqui, tudo está ok
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Conta'),
        centerTitle: true,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavButton(
                  context,
                  icon: Icons.check_circle,
                  label: 'Vendas',
                  isActive: false,
                  onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                ),
                _buildNavButton(
                  context,
                  icon: Icons.person,
                  label: 'Conta',
                  isActive: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              onTap: () {
                // TODO: Navegar para edição de dados pessoais
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildOptionCard(
              context,
              icon: Icons.store,
              title: 'Dados da Loja',
              subtitle: 'Nome, ramo de atividade',
              onTap: () {
                // TODO: Navegar para edição de dados da loja
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildOptionCard(
              context,
              icon: Icons.pix,
              title: 'Chave Pix',
              subtitle: 'Gerenciar chaves cadastradas',
              onTap: () {
                // TODO: Navegar para gestão de chaves PIX
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
                );
              },
            ),
            
            const Spacer(),
            
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
              Navigator.of(context).pop(); // Fechar dialog
              
              try {
                // Fazer logout
                if (!widget.authController.isDisposed) {
                  await widget.authController.logout();
                }
                
                // Navegar para OnboardingScreen limpando a pilha
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => OnboardingScreen(
                        authController: widget.authController,
                        themeController: ThemeController(),
                      ),
                    ),
                    (route) => false,
                  );
                }
              } catch (e) {
                print('⚠️ Erro no logout: $e');
                // Mesmo em caso de erro, navegar para onboarding
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => OnboardingScreen(
                        authController: widget.authController,
                        themeController: ThemeController(),
                      ),
                    ),
                    (route) => false,
                  );
                }
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
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
          color: isActive ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Theme.of(context).primaryColor : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? Theme.of(context).primaryColor : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}