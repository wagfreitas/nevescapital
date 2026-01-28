import 'package:flutter/material.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/unified_cpf_screen.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/features/auth/data/services/registration_service.dart';
import 'package:neves_capital/features/auth/data/services/local_registration_storage.dart';
import 'package:neves_capital/features/auth/presentation/helpers/registration_navigator.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

class OnboardingScreen extends StatefulWidget {
  final AuthController authController;
  final ThemeController? themeController;

  const OnboardingScreen({
    super.key,
    required this.authController,
    this.themeController,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _hasCheckedResume = false;
  bool _resumedRegistration = false;

  @override
  void initState() {
    super.initState();
    // Fechar teclado se estiver aberto de alguma tela anterior
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
      _checkPendingRegistration();
    });
  }


  Future<void> _checkPendingRegistration() async {
    if (_hasCheckedResume) return;
    _hasCheckedResume = true;

    try {
      AppLogger.debug('Verificando cadastro pendente...');

      // 1. Primeiro tenta buscar do storage LOCAL (rápido)
      var progress = await LocalRegistrationStorage.getLocal();

      if (progress == null) {
        // 2. Se não encontrou local, verifica se tem CPF salvo e busca no Firestore
        final lastCpf = await LocalRegistrationStorage.getLastCpf();
        if (lastCpf != null) {
          AppLogger.debug(
              'CPF encontrado localmente, buscando no Firestore...');
          progress = await RegistrationService.getProgress(lastCpf);

          // Se encontrou no Firestore, salva localmente para próxima vez
          if (progress != null) {
            await LocalRegistrationStorage.saveLocal(progress);
            AppLogger.debug(
                'Progresso do Firestore copiado para storage local');
          }
        }
      }

      if (progress == null || progress.isComplete || progress.isStale) {
        // Limpar armazenamento se cadastro completo ou expirado
        await LocalRegistrationStorage.clearLocal();
        if (progress == null) {
          AppLogger.debug('Nenhum cadastro pendente encontrado');
        } else {
          AppLogger.debug(
              'Cadastro ${progress.isComplete ? "completo" : "expirado"} - limpando storage');
        }
        return;
      }

      // Cadastro incompleto encontrado
      AppLogger.info(
          'Cadastro incompleto encontrado - step: ${progress.currentStep}');
      AppLogger.debug('Dados do progresso:');
      AppLogger.debug('  - CPF: ${progress.cpf.substring(0, 3)}***');
      AppLogger.debug(
          '  - Telefone: ${progress.phone?.substring(0, 2) ?? 'null'}***');
      AppLogger.debug(
          '  - Email: ${progress.email?.substring(0, 3) ?? 'null'}***');
      AppLogger.debug('  - Status: ${progress.status}');
      AppLogger.debug('  - Última atualização: ${progress.lastUpdated}');

      if (!mounted) return;

      // Aguardar frame seguinte para evitar conflito com build
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      // Mostrar diálogo perguntando se quer retomar
      final shouldResume = await RegistrationNavigator.showResumeDialog(
        context,
        progress.currentStep,
      );

      if (!mounted) return;

      if (shouldResume) {
        // Retomar cadastro
        _resumedRegistration = true;
        RegistrationNavigator.navigateToStep(
          context: context,
          progress: progress,
          authController: widget.authController,
          themeController: widget.themeController,
        );
      } else {
        // Recomeçar - obter telefone do progresso ANTES de deletar
        // O progresso sempre terá o telefone se o usuário já passou pela etapa de telefone
        String? authenticatedPhone = progress.phone;
        
        if (authenticatedPhone == null || authenticatedPhone.isEmpty) {
          // Se o progresso não tem telefone, tentar obter do usuário autenticado no Firebase
          try {
            final currentUser = widget.authController.currentUser;
            AppLogger.debug('Progresso não tem telefone, tentando obter do Firebase - currentUser: ${currentUser != null}, phoneNumber: ${currentUser?.phoneNumber}');
            
            if (currentUser != null && currentUser.phoneNumber != null) {
              authenticatedPhone = currentUser.phoneNumber!;
              AppLogger.info('Telefone obtido do Firebase: ${authenticatedPhone.substring(0, 4)}****');
            }
          } catch (e) {
            AppLogger.error('Erro ao obter telefone do usuário autenticado', e);
          }
        } else {
          AppLogger.info('Telefone obtido do progresso: ${authenticatedPhone.substring(0, 4)}****');
        }
        
        // Deletar progresso local e do Firestore
        await LocalRegistrationStorage.clearLocal();
        await RegistrationService.deleteProgress(progress.cpf);
        AppLogger.info('Usuário optou por recomeçar - progresso deletado');
        
        // Navegar para a tela de cadastro de CPF para iniciar novo cadastro
        // O usuário já fez a autenticação normal, então pode iniciar o cadastro
        // Passar o telefone autenticado para pular a tela de telefone
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => UnifiedCpfScreen(
                authController: widget.authController,
                themeController: widget.themeController,
                initialPhone: authenticatedPhone,
              ),
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Erro ao verificar cadastro pendente', e);
      // Não bloqueia o fluxo normal em caso de erro
    }
  }

  @override
  Widget build(BuildContext context) {
    // Garantir que não há foco ativo ao construir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
    
    return Scaffold(
      // Evita flash branco (asset de fundo pode demorar 1 frame para pintar)
      backgroundColor: const Color(0xFF02391E),
      resizeToAvoidBottomInset: false, // Evitar que o teclado apareça
      body: GestureDetector(
        onTap: () {
          // Fechar teclado ao tocar em qualquer lugar da tela
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fundo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Título principal
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Transforme seu celular em uma\n',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      TextSpan(
                        text: 'maquininha de cartão',
                        style: TextStyle(
                          color: Color(0xFF2D574D),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Botões
                Column(
                  children: [
                    // Botão "Já Sou Cliente" - vai para tela unificada
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhoneLoginScreen(
                                authController: widget.authController,
                                themeController: widget.themeController,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF28CC28), // Verde Vivo
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Já Sou Cliente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Botão "Abrir Conta" - vai para MESMA tela unificada
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhoneLoginScreen(
                                authController: widget.authController,
                                themeController: widget.themeController,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF02391E), // Verde Escuro
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Abrir Conta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
