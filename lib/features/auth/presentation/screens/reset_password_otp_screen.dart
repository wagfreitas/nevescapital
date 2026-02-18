import 'package:flutter/material.dart';
import 'package:neves_capital/shared/services/database_service.dart';
import 'package:neves_capital/core/theme/app_theme.dart';
import 'package:neves_capital/shared/components/glass_app_bar.dart';
import 'package:neves_capital/features/auth/presentation/screens/change_password_screen.dart';
import 'package:neves_capital/shared/components/keyboard_dismiss_button.dart';

class ResetPasswordOtpScreen extends StatefulWidget {
  final String cpf;

  const ResetPasswordOtpScreen({
    super.key,
    required this.cpf,
  });

  @override
  State<ResetPasswordOtpScreen> createState() => _ResetPasswordOtpScreenState();
}

class _ResetPasswordOtpScreenState extends State<ResetPasswordOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _codeSent = false;
  bool _codeVerified = false;
  String? _resetToken;
  int _resendCountdown = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _requestOtp();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await DatabaseService.requestPasswordResetOtp(widget.cpf);

      if (!mounted) return;

      setState(() {
        _codeSent = true;
        _isLoading = false;
        _resendCountdown = 120; // 2 minutos
      });

      // Iniciar contador regressivo
      _startResendCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _startResendCountdown() {
    if (_resendCountdown > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _resendCountdown--;
          });
          _startResendCountdown();
        }
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final otpCode = _otpController.text.trim();
      final result =
          await DatabaseService.verifyPasswordResetOtp(widget.cpf, otpCode);

      if (!mounted) return;

      setState(() {
        _codeVerified = true;
        _resetToken = result['token'];
        _isLoading = false;
      });

      // Navegar para tela de mudança de senha
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChangePasswordScreen(
            resetToken: _resetToken!,
            cpf: widget.cpf,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(),
      body: SafeArea(
        child: KeyboardDismissWrapper(
          child: LayoutBuilder(
            builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SingleChildScrollView(
              reverse: true,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: bottomInset + 32.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 40.0),
                      _buildTitle(),
                      const SizedBox(height: 24.0),
                      if (_errorMessage != null) ...[
                        _buildErrorMessage(),
                        const SizedBox(height: 16.0),
                      ],
                      if (_codeSent && !_codeVerified) ...[
                        _buildSuccessMessage(),
                        const SizedBox(height: 24.0),
                        _buildOtpForm(),
                      ] else if (!_codeSent) ...[
                        _buildDescription(),
                        const SizedBox(height: 24.0),
                        if (_isLoading)
                          CircularProgressIndicator(color: AppTheme.primaryColor)
                        else
                          ElevatedButton(
                            onPressed: _requestOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: AppTheme.backgroundColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 32),
                            ),
                            child: const Text(
                              'Enviar Código',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/icons/PagPag_icon.png',
      width: 120,
      height: 120,
      fit: BoxFit.contain,
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Código de Verificação',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription() {
    return const Text(
      'Um código de verificação será enviado para o seu telefone cadastrado.',
      style: TextStyle(
        fontSize: 14,
        color: Colors.white70,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: Colors.red, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 32),
          const SizedBox(height: 8),
          Text(
            'Código enviado!',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Verifique seu WhatsApp ou SMS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _otpController,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: TextStyle(
                fontSize: 32,
                color: Colors.white.withValues(alpha: 0.3),
                letterSpacing: 8,
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
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Digite o código';
              }
              if (value.trim().length != 6) {
                return 'Código deve ter 6 dígitos';
              }
              return null;
            },
          ),
          const SizedBox(height: 24.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppTheme.backgroundColor),
                      ),
                    )
                  : const Text(
                      'Verificar Código',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 16.0),
          if (_resendCountdown > 0)
            Text(
              'Reenviar código em ${_resendCountdown}s',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            )
          else
            TextButton(
              onPressed: _requestOtp,
              child: const Text(
                'Reenviar código',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
