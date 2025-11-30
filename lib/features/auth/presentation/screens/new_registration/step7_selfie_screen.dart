import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:neves_capital/features/auth/presentation/controllers/auth_controller.dart';
import 'package:neves_capital/core/theme/theme_controller.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'step8_document_screen.dart';

/// Tela 7 do Cadastro: Tire uma Selfie
class Step7SelfieScreen extends StatefulWidget {
  final AuthController? authController;
  final ThemeController? themeController;
  final String cpf;
  final String phone;
  final String email;
  final String fullName;
  final DateTime birthDate;
  final String motherName;
  final bool isPep;
  final String occupation;
  final String incomeRange;

  const Step7SelfieScreen({
    super.key,
    this.authController,
    this.themeController,
    required this.cpf,
    required this.phone,
    required this.email,
    required this.fullName,
    required this.birthDate,
    required this.motherName,
    required this.isPep,
    required this.occupation,
    required this.incomeRange,
  });

  @override
  State<Step7SelfieScreen> createState() => _Step7SelfieScreenState();
}

class _Step7SelfieScreenState extends State<Step7SelfieScreen> {
  File? _selfieFile;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _takeSelfie() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        setState(() {
          _selfieFile = File(image.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao capturar foto. Tente novamente.';
        });
      }
      AppLogger.error('Erro ao capturar selfie: $e');
    }
  }

  Future<void> _handleNext() async {
    if (_selfieFile == null) {
      setState(() {
        _errorMessage = 'Por favor, tire uma selfie antes de continuar';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!mounted) return;

      // Navegar para próxima tela (documentos)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Step8DocumentScreen(
            authController: widget.authController,
            themeController: widget.themeController,
            cpf: widget.cpf,
            phone: widget.phone,
            email: widget.email,
            fullName: widget.fullName,
            birthDate: widget.birthDate,
            motherName: widget.motherName,
            isPep: widget.isPep,
            occupation: widget.occupation,
            incomeRange: widget.incomeRange,
            selfiePath: _selfieFile!.path,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Tire uma Selfie!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Precisamos de uma foto sua para confirmar sua identidade',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Preview da Selfie com Oval
              SizedBox(
                height: 400,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Fundo escurecido
                    Container(
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                    // Oval Guide
                    CustomPaint(
                      size: const Size(280, 360),
                      painter: _selfieFile != null ? null : _OvalGuidePainter(),
                    ),
                    // Preview da foto ou placeholder
                    if (_selfieFile != null)
                      ClipPath(
                        clipper: _OvalClipper(),
                        child: SizedBox(
                          width: 280,
                          height: 360,
                          child: Image.file(
                            _selfieFile!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: 280,
                        height: 360,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 120,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Posicione seu rosto\nno centro do oval',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Instruções
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instruções:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInstruction('• Deixe seu rosto bem iluminado'),
                    _buildInstruction('• Não use óculos escuros ou boné'),
                    _buildInstruction('• Olhe diretamente para a câmera'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Botão Tirar Foto / Alterar Foto
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _takeSelfie,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF22C55E), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selfieFile == null ? Icons.camera_alt : Icons.refresh,
                        color: const Color(0xFF22C55E),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selfieFile == null ? 'Tirar Foto' : 'Alterar Foto',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
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
                          style:
                              const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Botão Avançar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _isLoading || _selfieFile == null ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: const Color(0xFF122118),
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
                                Color(0xFF122118)),
                          ),
                        )
                      : const Text(
                          'Avançar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Custom Painter para desenhar o guia oval
class _OvalGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Desenhar oval
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.width / 2),
    );

    canvas.drawRRect(rrect, paint);

    // Desenhar linhas de guia (opcional)
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Linha horizontal central
    canvas.drawLine(
      Offset(size.width * 0.2, size.height / 2),
      Offset(size.width * 0.8, size.height / 2),
      dashPaint,
    );

    // Linha vertical central
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.2),
      Offset(size.width / 2, size.height * 0.8),
      dashPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Clipper para recortar a imagem em formato oval
class _OvalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.width / 2),
    );
    path.addRRect(rrect);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
