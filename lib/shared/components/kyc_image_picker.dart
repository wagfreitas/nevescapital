import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:neves_capital/core/theme/app_theme.dart';

/// Componente para captura de imagens no processo KYC
class KycImagePicker extends StatefulWidget {
  final String title;
  final String description;
  final String? imagePath;
  final bool isRequired;
  final bool allowGallery;
  final bool allowCamera;
  final Function(String? imagePath) onImageSelected;
  final Function(String error)? onError;

  const KycImagePicker({
    super.key,
    required this.title,
    required this.description,
    this.imagePath,
    this.isRequired = true,
    this.allowGallery = true,
    this.allowCamera = true,
    required this.onImageSelected,
    this.onError,
  });

  @override
  State<KycImagePicker> createState() => _KycImagePickerState();
}

class _KycImagePickerState extends State<KycImagePicker> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          Text(
            widget.description,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16.0),
          _buildImagePreview(),
          const SizedBox(height: 16.0),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.primary,
            width: 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.file(
            File(widget.imagePath!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary,
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: 60,
            color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Nenhuma imagem selecionada',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (widget.allowGallery) ...[
          Expanded(
            child: _buildActionButton(
              icon: Icons.photo_library,
              label: 'Galeria',
              onTap: () => _pickImage(ImageSource.gallery),
            ),
          ),
          const SizedBox(width: 8.0),
        ],
        if (widget.allowCamera) ...[
          Expanded(
            child: _buildActionButton(
              icon: Icons.camera_alt,
              label: 'Câmera',
              onTap: () => _pickImage(ImageSource.camera),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8.0),
                Text(label),
              ],
            ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar permissões
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          _showError('Permissão de câmera negada');
          return;
        }
      } else {
        final photosStatus = await Permission.photos.request();
        if (!photosStatus.isGranted) {
          _showError('Permissão de galeria negada');
          return;
        }
      }

      // Capturar imagem
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        widget.onImageSelected(image.path);
      }
    } catch (e) {
      _showError('Erro ao capturar imagem: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    if (widget.onError != null) {
      widget.onError!(message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
    }
  }
}

/// Componente específico para selfie (apenas câmera)
class KycSelfiePicker extends StatelessWidget {
  final String? imagePath;
  final Function(String? imagePath) onImageSelected;
  final Function(String error)? onError;

  const KycSelfiePicker({
    super.key,
    this.imagePath,
    required this.onImageSelected,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return KycImagePicker(
      title: 'Tire uma Selfie para Confirmar sua Identidade',
      description: 'Para sua segurança, tire uma selfie clara do seu rosto.',
      imagePath: imagePath,
      allowGallery: false, // Selfie deve ser tirada no momento
      allowCamera: true,
      onImageSelected: onImageSelected,
      onError: onError,
    );
  }
}

/// Componente específico para documentos (galeria e câmera)
class KycDocumentPicker extends StatelessWidget {
  final String title;
  final String? imagePath;
  final Function(String? imagePath) onImageSelected;
  final Function(String error)? onError;

  const KycDocumentPicker({
    super.key,
    required this.title,
    this.imagePath,
    required this.onImageSelected,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return KycImagePicker(
      title: title,
      description: 'Envie uma foto do seu documento de identidade.',
      imagePath: imagePath,
      allowGallery: true,
      allowCamera: true,
      onImageSelected: onImageSelected,
      onError: onError,
    );
  }
}
