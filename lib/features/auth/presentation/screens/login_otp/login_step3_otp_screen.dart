import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/helpers/phone_helper.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/features/auth/presentation/screens/cpf_check_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/unified_cpf_screen.dart';
import 'package:neves_capital/features/auth/data/services/auth_api_service.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/features/home/presentation/screens/main_tab_screen.dart';
import 'package:neves_capital/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';

/// Tela 3 do Login OTP: Insira o código OTP (6 dígitos)
class LoginStep3OtpScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;

  const LoginStep3OtpScreen({
    super.key,
    this.authController,
    this.themeController,
  });

  @override
  State<LoginStep3OtpScreen> createState() => _LoginStep3OtpScreenState();
}

class _LoginStep3OtpScreenState extends State<LoginStep3OtpScreen> {
  static const int _otpLength = 6;
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  String? _phone;
  String? _formattedPhone; // Telefone formatado E.164 para reenvio
  int? _resendToken; // Token do Firebase para reenvio
  int _resendCountdown = 0;
  bool _isOtpComplete = false;
  bool _isFakeMode = false;
  int _failedAttempts = 0; // Contador de tentativas falhadas
  static const int _maxFailedAttempts = 3; // Máximo de tentativas antes de redirecionar para Onboarding

  // 🎭 OTP FAKE para testes
  static const String _fakeOtpCode = '123456';

  @override
  void initState() {
    super.initState();
    
    // Listener para habilitar/desabilitar botão
    _otpController.addListener(() {
      final hasFullCode = _otpController.text.trim().length == _otpLength;
      if (hasFullCode != _isOtpComplete) {
        setState(() {
          _isOtpComplete = hasFullCode;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inicializar argumentos quando o contexto estiver disponível
    _initializeFromArguments();
  }

  void _initializeFromArguments() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final phone = args?['phone'] as String?;
    final formattedPhone = args?['formattedPhone'] as String?;
    final resendToken = args?['resendToken'] as int?;
    final isFakeMode = args?['isFakeMode'] as bool? ?? false;

    // Só atualizar se os valores mudaram
    if (phone != _phone || formattedPhone != _formattedPhone || isFakeMode != _isFakeMode) {
      setState(() {
        _phone = phone;
        _formattedPhone = formattedPhone;
        _resendToken = resendToken;
        _isFakeMode = isFakeMode;
      });

      if (_isFakeMode) {
        AppLogger.info('🎭 MODO FAKE OTP - Use o código: $_fakeOtpCode');
      }

      AppLogger.debug('📱 Telefone recebido: ${_phone != null ? "${_phone!.substring(0, 2)}***" : "null"}');
      AppLogger.debug('📱 Telefone formatado: ${_formattedPhone != null ? "${_formattedPhone!.substring(0, 4)}***" : "null"}');
      AppLogger.debug('📱 ResendToken: ${_resendToken != null ? "disponível" : "não disponível"}');

      // Solicitar foco após receber os dados
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_otpFocusNode.hasFocus) {
          _otpFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _otpFocusNode.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final otpCode = _otpController.text.trim();

      // 🎭 MODO FAKE: Validar OTP fake
      if (_isFakeMode) {
        AppLogger.info('🎭 Verificando OTP FAKE...');

        // Simular delay de rede
        await Future.delayed(const Duration(milliseconds: 800));

        if (otpCode != _fakeOtpCode) {
          throw Exception('Código inválido. Use: $_fakeOtpCode');
        }

        AppLogger.info('✅ OTP FAKE validado com sucesso!');

        // No modo fake, vamos criar um usuário temporário ou pular direto para cadastro
        // Por enquanto, vamos apenas mostrar mensagem de sucesso e navegar
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        // Simular fluxo: ir para verificação de CPF
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CpfCheckScreen(
              authController: widget.authController,
              themeController: widget.themeController,
            ),
            settings: const RouteSettings(
              arguments: {
                'token': 'fake-token-for-testing',
              },
            ),
          ),
        );
        return;
      }

      // MODO REAL: Verificar no Firebase
      // Recuperar verificationId dos argumentos
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final verificationId = args?['verificationId'] as String?;

      if (verificationId == null) {
        throw Exception('ID de verificação inválido. Reinicie o processo.');
      }

      // 1. Verificar OTP no Firebase
      AppLogger.info('🔐 Verificando OTP no Firebase...');

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Falha na autenticação');
      }

      // 2. Obter Token
      final token = await user.getIdToken();
      AppLogger.info('✅ Autenticado no Firebase! Token obtido.');

      // Resetar contador de tentativas falhadas após sucesso
      _failedAttempts = 0;

      // 3. Verificar Status no Backend
      final result = await AuthApiService.checkUserStatus(token!);

      if (!mounted) return;

      final success = result['success'] as bool? ?? false;
      final status = result['status'] as String?;

      // PRIORIDADE ABSOLUTA: Se status for REGISTER, navegar IMEDIATAMENTE
      // Verificar ANTES de qualquer processamento
      if (success && status == 'REGISTER') {
        if (!mounted) return;

        // Não manter sessão autenticada quando cadastro está incompleto
        try {
          await FirebaseAuth.instance.signOut();
          AppLogger.info(
              'Sessão Firebase encerrada porque usuário ainda não concluiu cadastro');
        } catch (e) {
          AppLogger.warning(
              'Falha ao encerrar sessão Firebase antes do cadastro: $e');
        }

        AppLogger.info(
            '🚀 [NAVEGAÇÃO] Status REGISTER detectado - navegando IMEDIATAMENTE');

        // Garantir que _errorMessage está null ANTES de navegar
        _errorMessage = null;

        // Navegar de forma síncrona e garantida
        try {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) {
                AppLogger.info('🚀 [NAVEGAÇÃO] Construindo UnifiedCpfScreen');
                return UnifiedCpfScreen(
                  authController: widget.authController,
                  themeController: widget.themeController,
                  initialPhone: _phone,
                );
              },
            ),
            (route) {
              AppLogger.info(
                  '🚀 [NAVEGAÇÃO] Removendo rota: ${route.settings.name}');
              return false; // Remove todas as rotas
            },
          );
          AppLogger.info('🚀 [NAVEGAÇÃO] Navegação executada com sucesso');
        } catch (e, stack) {
          AppLogger.error('❌ [NAVEGAÇÃO] Erro ao navegar', e, stack);
          // Se falhar, tentar novamente sem rootNavigator
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => UnifiedCpfScreen(
                authController: widget.authController,
                themeController: widget.themeController,
                initialPhone: _phone,
              ),
            ),
            (route) => false,
          );
        }

        // Return IMEDIATO - nada abaixo executa
        return;
      }

      // A partir daqui, só processa outros status
      if (success) {
        if (status == 'LOGGED_IN') {
          if (!mounted) return;

          AppLogger.info(
              '✅ Status LOGGED_IN - usuário encontrado na collection users');

          // Obter userId do resultado para buscar CPF
          final userId = result['userId'] as String?;
          AppLogger.debug(
              'UserId retornado: ${userId != null ? "${userId.substring(0, 8)}..." : "null"}');

          String? cpf;

          if (userId != null && widget.authController != null) {
            try {
              // Garante que o documento reconhece este UID como proprietário
              await FirestoreService.linkUserDocumentToFirebaseUid(
                userId: userId,
                firebaseUid: user.uid,
              );
            } catch (e) {
              AppLogger.error(
                  'Erro ao vincular Firebase UID ao documento do usuário: $e');
            }

            // Buscar usuário no Firestore para obter CPF
            try {
              AppLogger.debug('Buscando usuário no Firestore pelo userId...');
              final userData =
                  await FirestoreService.getUserByDocumentId(userId);
              if (userData != null) {
                cpf = userData['cpf'] as String?;
                AppLogger.debug(
                    'CPF obtido do usuário: ${cpf != null ? "${cpf.substring(0, 3)}***" : "null"}');
              } else {
                AppLogger.warning(
                    'Usuário não encontrado no Firestore pelo userId');
              }
            } catch (e) {
              AppLogger.error('Erro ao buscar CPF do usuário: $e');
            }

            // Se conseguiu obter CPF, fazer login via OTP
            if (cpf != null) {
              AppLogger.info(
                  'Fazendo login com CPF: ${cpf.substring(0, 3)}***');
              final loginSuccess =
                  await widget.authController!.loginWithOtpMock(cpf);

              if (!loginSuccess) {
                AppLogger.error('Erro ao fazer login após OTP validado');
                setState(() {
                  _errorMessage = widget.authController?.errorMessage ??
                      'Erro ao fazer login';
                });
                return;
              }

              AppLogger.info(
                  '✅ Login realizado com sucesso - redirecionando para MainTabScreen');
              
              // Navegar diretamente para Dashboard quando usuário está logado e cadastro completo
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => MainTabScreen(
                      authController: widget.authController!,
                      themeController: widget.themeController ?? ThemeController(),
                    ),
                  ),
                  (route) => false, // Remove todas as rotas anteriores
                );
              }
              return;
            } else {
              // CPF não encontrado - redirecionar para cadastro
              AppLogger.warning(
                  'CPF não encontrado no cadastro - redirecionando para trilha de cadastro');
              if (mounted) {
                _errorMessage = null;
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => UnifiedCpfScreen(
                      authController: widget.authController!,
                      themeController: widget.themeController,
                      initialPhone: _phone,
                    ),
                  ),
                  (route) => false,
                );
              }
              return;
            }
          } else {
            // UserId não retornado - redirecionar para cadastro
            AppLogger.warning(
                'UserId não retornado pelo backend - redirecionando para cadastro');
            if (mounted) {
              _errorMessage = null;
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => UnifiedCpfScreen(
                    authController: widget.authController!,
                    themeController: widget.themeController,
                    initialPhone: _phone,
                  ),
                ),
                (route) => false,
              );
            }
            return;
          }
        } else if (status == 'REQUIRE_CPF_CHECK') {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CpfCheckScreen(
                authController: widget.authController,
                themeController: widget.themeController,
              ),
              settings: RouteSettings(
                arguments: {'token': token},
              ),
            ),
          );
          return;
        } else {
          // Status desconhecido
          if (mounted) {
            setState(() {
              _errorMessage = 'Status desconhecido: $status';
              _isLoading = false;
            });
          }
        }
      } else {
        // Erro na API ou usuário não encontrado - redirecionar para cadastro
        AppLogger.warning(
            '❌ Erro na API ou usuário não encontrado - redirecionando para cadastro');
        if (mounted) {
          // Limpar mensagem de erro antes de navegar
          _errorMessage = null;

          // Redirecionar para trilha de cadastro
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => UnifiedCpfScreen(
                authController: widget.authController,
                themeController: widget.themeController,
                initialPhone: _phone,
              ),
            ),
            (route) => false,
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        // Incrementar contador de tentativas falhadas
        _failedAttempts++;
        
        setState(() {
          if (e is FirebaseAuthException) {
            if (e.code == 'invalid-verification-code') {
              if (_failedAttempts >= _maxFailedAttempts) {
                // Após máximo de tentativas, redirecionar para Onboarding
                AppLogger.warning('Máximo de tentativas de OTP excedido - redirecionando para Onboarding');
                _redirectToOnboarding();
                return;
              }
              _errorMessage = 'Código inválido. Tentativas restantes: ${_maxFailedAttempts - _failedAttempts}';
            } else {
              _errorMessage = e.message;
            }
          } else {
            if (e.toString().contains('Código inválido')) {
              if (_failedAttempts >= _maxFailedAttempts) {
                // Após máximo de tentativas, redirecionar para Onboarding
                AppLogger.warning('Máximo de tentativas de OTP excedido - redirecionando para Onboarding');
                _redirectToOnboarding();
                return;
              }
              _errorMessage = 'Código inválido. Tentativas restantes: ${_maxFailedAttempts - _failedAttempts}';
            } else {
              _errorMessage = e.toString().replaceAll('Exception: ', '');
            }
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 🎭 MODO FAKE: Simular reenvio
      if (_isFakeMode) {
        AppLogger.info('🎭 MOCK: Reenviando OTP FAKE');
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _resendCountdown = 60; // 60 segundos de countdown
          });
          _startResendCountdown();
        }
        return;
      }

      // MODO REAL: Reenviar OTP via Firebase Phone Auth
      if (_formattedPhone == null || _formattedPhone!.isEmpty) {
        throw Exception('Telefone não disponível para reenvio');
      }

      AppLogger.info('🔄 Reenviando código OTP para: ${_formattedPhone!.substring(0, 4)}***');

      // Reenviar código usando Firebase Phone Auth
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _formattedPhone!,
        forceResendingToken: _resendToken, // Usar token de reenvio se disponível
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-verificação (geralmente não acontece no reenvio)
          AppLogger.debug('✅ Verificação automática no reenvio');
        },
        verificationFailed: (FirebaseAuthException e) {
          AppLogger.error('❌ Erro ao reenviar OTP: ${e.code} - ${e.message}');
          if (mounted) {
            setState(() {
              _isLoading = false;
              if (e.code == 'too-many-requests') {
                _errorMessage = 'Muitas tentativas. Aguarde alguns minutos.';
              } else if (e.code == 'quota-exceeded') {
                _errorMessage = 'Limite de SMS excedido. Tente mais tarde.';
              } else {
                _errorMessage = 'Erro ao reenviar código: ${e.message ?? e.code}';
              }
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          AppLogger.info('✅ Código reenviado com sucesso!');
          AppLogger.debug('📱 Novo VerificationId: $verificationId');
          AppLogger.debug('📱 Novo ResendToken: ${resendToken != null ? "disponível" : "não disponível"}');
          
          // Atualizar verificationId e resendToken para próximos reenvios
          _resendToken = resendToken;
          
          // Atualizar verificationId nos argumentos da rota (se necessário)
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            args['verificationId'] = verificationId;
            args['resendToken'] = resendToken;
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
              _resendCountdown = 60; // 60 segundos de countdown
            });
            _startResendCountdown();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          AppLogger.debug('⏰ Timeout de auto-retrieval no reenvio');
        },
      );
    } catch (e) {
      AppLogger.error('❌ Erro ao reenviar OTP', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao reenviar código: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  void _startResendCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
        _startResendCountdown();
      }
    });
  }

  /// Redireciona para Onboarding quando OTP não confere após várias tentativas
  void _redirectToOnboarding() {
    if (!mounted) return;
    
    AppLogger.info('Redirecionando para Onboarding após falhas no OTP');
    
    // Fazer logout para limpar estado
    widget.authController?.logout();
    
    // Redirecionar para Onboarding
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => OnboardingScreen(
          authController: widget.authController ?? AuthController(),
          themeController: widget.themeController,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            // Fechar teclado se estiver aberto
            if (FocusManager.instance.primaryFocus != null) {
              FocusScope.of(context).unfocus();
              // Aguardar um momento para o teclado fechar antes de navegar
              await Future.delayed(const Duration(milliseconds: 200));
            }

            if (!context.mounted) return;

            // Tentar voltar na pilha de navegação
            final didPop = await Navigator.of(context).maybePop();
            if (!didPop && context.mounted) {
              // Se não conseguiu voltar, redireciona para onboarding
              _redirectToOnboarding();
            }
          },
        ),
      ),
      body: KeyboardDismissWrapper(
        focusNodes: [_otpFocusNode],
        doneText: 'OK',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(top: 40, bottom: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Digite o código',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _phone != null && _phone!.isNotEmpty
                          ? 'Informe o código de verificação recebido no número ${PhoneHelper.formatPhone(_phone!)}'
                          : 'Informe o código de verificação recebido',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (_isFakeMode) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.science,
                                color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '🎭 MODO TESTE: Use o código $_fakeOtpCode',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _otpController,
                      focusNode: _otpFocusNode,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        _otpFocusNode.unfocus();
                        if (_otpController.text.length == _otpLength) {
                          _handleVerifyOtp();
                        }
                      },
                      textAlign: TextAlign.center,
                      maxLength: _otpLength,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 12,
                      ),
                      decoration: InputDecoration(
                        hintText: '000000',
                        hintStyle: TextStyle(
                          fontSize: 32,
                          color: Colors.white.withValues(alpha: 0.3),
                          letterSpacing: 12,
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: AppTheme.inputEditableBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryColor, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite o código';
                        }
                        if (value.trim().length != _otpLength) {
                          return 'Código deve ter $_otpLength dígitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            (_isLoading || !_isOtpComplete) ? null : _handleVerifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.backgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.backgroundColor),
                                ),
                              )
                            : const Text(
                                'Verificar Código',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: _resendCountdown > 0
                          ? Text(
                              'Reenviar código em ${_resendCountdown}s',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                            )
                          : TextButton(
                              onPressed: _isLoading ? null : _handleResendOtp,
                              child: const Text(
                                'Reenviar código',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
