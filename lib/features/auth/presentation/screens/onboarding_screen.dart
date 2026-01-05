import 'package:flutter/material.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/unified_cpf_screen.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/features/auth/data/services/registration_service.dart';
import 'package:neves_capital/features/auth/data/services/local_registration_storage.dart';
import 'package:neves_capital/features/auth/presentation/helpers/registration_navigator.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/shared/services/biometric_service.dart';
import 'package:neves_capital/features/home/presentation/screens/main_tab_screen.dart';

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
  bool _hasCheckedBiometric = false;
  bool _isCheckingBiometric = false;
  bool _resumedRegistration = false;
  bool _isProcessingBiometric = false; // Flag para evitar múltiplas chamadas simultâneas

  @override
  void initState() {
    super.initState();
    // Aguardar um frame para garantir que o AuthController foi totalmente inicializado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricAndPendingRegistration();
    });
  }

  /// Verifica biometria se usuário está logado, depois verifica cadastro pendente
  Future<void> _checkBiometricAndPendingRegistration() async {
    // Proteção contra múltiplas chamadas simultâneas
    if (_isProcessingBiometric) {
      AppLogger.warning('Verificação de biometria já em andamento - ignorando chamada duplicada');
      return;
    }
    
    // Aguardar um pouco para garantir que o AuthController foi totalmente inicializado
    await Future.delayed(const Duration(milliseconds: 150));
    
    // Primeiro: se existe cadastro incompleto, retomar antes de qualquer biometria/dashboard
    await _checkPendingRegistration();
    if (_resumedRegistration) {
      AppLogger.info('Cadastro incompleto retomado - biometria/dashboard cancelados');
      return;
    }

    // 1. Primeiro verificar se usuário está logado - SEMPRE pedir biometria se disponível
    // IMPORTANTE: Não limpar estado de login aqui - ele deve ser mantido quando o app é fechado
    // O estado só deve ser limpo quando o usuário clica explicitamente em "Sair"
    AppLogger.info('🔐 [ONBOARDING] Verificando estado de login:');
    AppLogger.info('  - isLoggedIn: ${widget.authController.isLoggedIn}');
    AppLogger.info('  - currentUser: ${widget.authController.currentUser != null}');
    AppLogger.info('  - isLoading: ${widget.authController.isLoading}');
    
    // Verificar novamente após um pequeno delay para evitar race condition
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Verificar múltiplas vezes para garantir que o estado está estável
    // (evita race condition após logout)
    bool isLoggedIn = widget.authController.isLoggedIn;
    await Future.delayed(const Duration(milliseconds: 50));
    final isLoggedInSecondCheck = widget.authController.isLoggedIn;
    
    // Se o estado mudou entre as verificações, aguardar mais um pouco
    if (isLoggedIn != isLoggedInSecondCheck) {
      AppLogger.warning('Estado de login instável detectado - aguardando estabilização...');
      await Future.delayed(const Duration(milliseconds: 100));
      isLoggedIn = widget.authController.isLoggedIn;
    }
    
    AppLogger.info('🔐 [ONBOARDING] Estado final verificado: isLoggedIn = $isLoggedIn');
    
    if (isLoggedIn) {
      final isBiometricAvailable = await BiometricService.isAvailable();
      
      if (isBiometricAvailable && !_hasCheckedBiometric && !_isProcessingBiometric) {
        _isProcessingBiometric = true;
        _hasCheckedBiometric = true;
        _isCheckingBiometric = true;
        
        AppLogger.info('Usuário logado - solicitando autenticação biométrica...');
        
        if (mounted) {
          setState(() {});
        }

        // IMPORTANTE (iOS): garantir que a tela de fundo (verde) seja pintada
        // antes do prompt nativo do Face ID aparecer. Sem isso, o iOS pode
        // capturar um frame "em branco" como snapshot do app.
        await WidgetsBinding.instance.endOfFrame;
        
        try {
          // Solicitar biometria (com fallback para senha do dispositivo)
          // O iOS mostrará opção de usar senha se biometria falhar
          final authenticated = await BiometricService.authenticate(
            reason: 'Use sua biometria para acessar o app',
          );
          
          // Manter tela verde escuro até processar resultado
          if (mounted) {
            setState(() {
              _isCheckingBiometric = false;
            });
          }
          
          // Verificar novamente se ainda está logado após biometria
          // (pode ter sido feito logout durante a biometria)
          if (!mounted || !widget.authController.isLoggedIn) {
            AppLogger.info('Estado de login mudou durante biometria - cancelando redirecionamento');
            _isProcessingBiometric = false;
            return;
          }
          
          if (authenticated) {
            AppLogger.info('✅ Biometria ou senha validada - redirecionando para Dashboard');
            // Autenticação validada (biometria ou senha) - redirecionar para Dashboard
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => MainTabScreen(
                    authController: widget.authController,
                    themeController: widget.themeController ?? ThemeController(),
                  ),
                ),
              );
            }
            _isProcessingBiometric = false;
            return; // Não verificar cadastro pendente se autenticação foi validada
          } else {
            AppLogger.warning('❌ Biometria e senha falharam ou foram canceladas - fazendo logout e redirecionando para login');
            // Se biometria E senha falharam ou foram canceladas, fazer logout para evitar loop
            // e redirecionar para login
            if (mounted) {
              await widget.authController.logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => PhoneLoginScreen(
                    authController: widget.authController,
                    themeController: widget.themeController,
                  ),
                ),
              );
            }
            _isProcessingBiometric = false;
            return; // Não verificar cadastro pendente se autenticação falhou
          }
        } catch (e) {
          AppLogger.error('Erro durante autenticação biométrica', e);
          if (mounted) {
            setState(() {
              _isCheckingBiometric = false;
            });
            // Em caso de erro, fazer logout para evitar loop
            await widget.authController.logout();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PhoneLoginScreen(
                  authController: widget.authController,
                  themeController: widget.themeController,
                ),
              ),
            );
          }
          _isProcessingBiometric = false;
          return;
        }
      } else if (!isBiometricAvailable && isLoggedIn) {
        // Biometria não disponível mas usuário está logado - ir direto para dashboard
        // Verificar novamente antes de redirecionar
        if (widget.authController.isLoggedIn) {
          AppLogger.info('Usuário logado mas biometria não disponível - redirecionando para Dashboard');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => MainTabScreen(
                  authController: widget.authController,
                  themeController: widget.themeController ?? ThemeController(),
                ),
              ),
            );
          }
        }
        return;
      }
    }
    
    // 2. Verificar cadastro pendente (apenas se não passou pela biometria)
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
    // Mostrar loading enquanto verifica biometria
    // IMPORTANTE: Esta tela deve permanecer visível durante TODA a autenticação
    // (biometria + fallback para senha do dispositivo)
    if (_isCheckingBiometric) {
      return Scaffold(
        backgroundColor: const Color(0xFF02391E), // Verde escuro PagPag
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo PagPag centralizado
                Image.asset(
                  'assets/icons/PagPag_icon.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                // Indicador de loading
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Aguardando autenticação...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      // Evita flash branco (asset de fundo pode demorar 1 frame para pintar)
      backgroundColor: const Color(0xFF02391E),
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
    );
  }
}
