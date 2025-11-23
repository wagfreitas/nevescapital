import 'package:flutter/material.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
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

  @override
  void initState() {
    super.initState();
    _checkPendingRegistration();
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
        RegistrationNavigator.navigateToStep(
          context: context,
          progress: progress,
          authController: widget.authController,
          themeController: widget.themeController,
        );
      } else {
        // Recomeçar - deletar progresso local e do Firestore
        await LocalRegistrationStorage.clearLocal();
        await RegistrationService.deleteProgress(progress.cpf);
        AppLogger.info('Usuário optou por recomeçar - progresso deletado');
      }
    } catch (e) {
      AppLogger.error('Erro ao verificar cadastro pendente', e);
      // Não bloqueia o fluxo normal em caso de erro
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                              builder: (context) => UnifiedCpfScreen(
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
                              builder: (context) => UnifiedCpfScreen(
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
    );
  }
}
