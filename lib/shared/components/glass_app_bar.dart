import 'dart:ui';
import 'package:flutter/material.dart';

/// AppBar transparente com efeito de desfoque (glass/frosted)
///
/// O conteúdo do body passa por baixo do AppBar, e a área
/// atrás dele fica com blur. Requer `extendBodyBehindAppBar: true`
/// no Scaffold.
///
/// Exemplo de uso:
/// ```dart
/// Scaffold(
///   extendBodyBehindAppBar: true,
///   appBar: GlassAppBar(
///     onBackPressed: () => Navigator.of(context).pop(),
///   ),
///   body: ...
/// )
/// ```
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBackPressed;
  final Widget? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final double blurSigma;
  final bool automaticallyImplyLeading;

  const GlassAppBar({
    super.key,
    this.onBackPressed,
    this.title,
    this.actions,
    this.showBackButton = true,
    this.blurSigma = 10.0,
    this.automaticallyImplyLeading = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: automaticallyImplyLeading,
          leading: showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                )
              : null,
          title: title,
          actions: actions,
        ),
      ),
    );
  }
}
