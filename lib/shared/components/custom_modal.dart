import 'package:flutter/material.dart';

/// Modal customizado da aplicação
class CustomModal extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool isDismissible;
  final bool showCloseButton;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;
  final double? maxHeight;
  final BorderRadius? borderRadius;
  
  const CustomModal({
    super.key,
    required this.child,
    this.title,
    this.isDismissible = true,
    this.showCloseButton = true,
    this.padding,
    this.maxWidth,
    this.maxHeight,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? 400,
          maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null || showCloseButton) _buildHeader(context),
            Flexible(
              child: Padding(
                padding: padding ?? const EdgeInsets.all(24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (title != null)
            Expanded(
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (showCloseButton)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              iconSize: 20,
            ),
        ],
      ),
    );
  }
}

/// Modal de confirmação
class ConfirmationModal extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;
  final Color? cancelColor;
  final bool isLoading;
  
  const ConfirmationModal({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    this.onConfirm,
    this.onCancel,
    this.confirmColor,
    this.cancelColor,
    this.isLoading = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomModal(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : onCancel ?? () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cancelColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(cancelText),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(confirmText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Modal de informações
class InfoModal extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? iconColor;
  
  const InfoModal({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.onPressed,
    this.icon,
    this.iconColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomModal(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 48,
              color: iconColor ?? Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed ?? () => Navigator.of(context).pop(),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet customizado
class CustomBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool isDismissible;
  final bool showDragHandle;
  final EdgeInsetsGeometry? padding;
  final double? maxHeight;
  
  const CustomBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.isDismissible = true,
    this.showDragHandle = true,
    this.padding,
    this.maxHeight,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle) _buildDragHandle(),
          if (title != null) _buildTitle(),
          Flexible(
            child: Padding(
              padding: padding ?? const EdgeInsets.all(24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
  
  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        title!,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
