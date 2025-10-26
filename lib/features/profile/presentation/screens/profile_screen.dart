import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../auth/presentation/controllers/auth_controller_real.dart';
import '../../../auth/presentation/screens/onboarding_screen.dart';

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
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();

    // Escutar mudanças no controller para detectar logout e forçar
    // a navegação para Onboarding limpando a pilha.
    widget.authController.addListener(_authListener);
  }

  void _authListener() {
    if (!mounted) return;

    final isLoggedIn = widget.authController.currentUser != null;

    if (!isLoggedIn && !_didNavigate) {
      _didNavigate = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => OnboardingScreen(authController: widget.authController),
          ),
          (route) => false,
        );
      });
    }
  }

  @override
  void dispose() {
    widget.authController.removeListener(_authListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = widget.authController;

    // Verificar se o controller ainda está ativo antes de usar
    if (authController.isDisposed) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Perfil'),
          centerTitle: true,
        ),
        body: Center(
          child: Text('Sessão expirada'),
        ),
      );
    }

    final user = authController.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Perfil'),
          centerTitle: true,
        ),
        body: Center(
          child: Text('Usuário não encontrado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Avatar e informações básicas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.green.shade100,
                      child: user.photoURL != null
                          ? ClipOval(
                              child: Image.network(
                                user.photoURL!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.green.shade700,
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.displayName ?? 'Usuário',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.email ?? '',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Opções do perfil
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Editar Perfil'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: Navegar para edição de perfil
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Alterar Senha'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: Navegar para alteração de senha
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notificações'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: Navegar para configurações de notificação
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Ajuda'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: Navegar para ajuda
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Política de Privacidade'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () {
                      _openPrivacyPolicy();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Botão de logout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showLogoutDialog(context);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
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
              
              // Fazer logout - o AppWrapper já gerencia o redirecionamento
              await widget.authController.logout();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy() async {
    const url = 'https://www.pagpagbrasil.com.br/politica';
    final uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback caso não consiga abrir
        print('Não foi possível abrir a URL: $url');
      }
    } catch (e) {
      print('Erro ao abrir URL: $e');
    }
  }
}