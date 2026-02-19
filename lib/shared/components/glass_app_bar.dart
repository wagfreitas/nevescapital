import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Scaffold com AppBar 100% transparente integrada.
///
/// Em vez de usar o parâmetro `appBar` do Scaffold (que pode renderizar
/// overlays internos no Material 3), coloca a GlassAppBar como overlay
/// via Stack, garantindo transparência total.
///
/// Uso direto como substituto do Scaffold + GlassAppBar:
/// ```dart
/// GlassScaffold(
///   onBackPressed: () => Navigator.pop(context),
///   body: SafeArea(child: ...),
/// )
/// ```
class GlassScaffold extends StatelessWidget {
  final Widget body;
  final VoidCallback? onBackPressed;
  final Widget? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  const GlassScaffold({
    super.key,
    required this.body,
    this.onBackPressed,
    this.title,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: Stack(
          children: [
            // Conteúdo principal (com padding top para ficar abaixo da AppBar)
            Padding(
              padding: EdgeInsets.only(top: statusBarHeight + kToolbarHeight),
              child: body,
            ),
            // AppBar transparente sobre o conteúdo
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: statusBarHeight + kToolbarHeight,
                child: Padding(
                  padding: EdgeInsets.only(top: statusBarHeight),
                  child: Row(
                    children: [
                      if (showBackButton)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Center(
                            child: LiquidBackButton(
                              onPressed: onBackPressed ??
                                  () => Navigator.of(context).pop(),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 56),
                      Expanded(
                        child: title != null
                            ? Center(child: title!)
                            : const SizedBox.shrink(),
                      ),
                      if (actions != null && actions!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!,
                        )
                      else
                        const SizedBox(width: 56),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AppBar 100% transparente com botão de voltar estilo Liquid.
///
/// Mantida para compatibilidade — usa `AppBar` nativo com `forceMaterialTransparency`.
/// Requer `extendBodyBehindAppBar: true` no Scaffold.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBackPressed;
  final Widget? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool automaticallyImplyLeading;

  const GlassAppBar({
    super.key,
    this.onBackPressed,
    this.title,
    this.actions,
    this.showBackButton = true,
    this.automaticallyImplyLeading = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      forceMaterialTransparency: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      centerTitle: true,
      automaticallyImplyLeading: automaticallyImplyLeading,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      leading: showBackButton
          ? Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Center(
                child: LiquidBackButton(
                  onPressed:
                      onBackPressed ?? () => Navigator.of(context).pop(),
                ),
              ),
            )
          : null,
      title: title,
      actions: actions,
    );
  }
}

/// Botão de voltar estilo Liquid: ícone dentro de um círculo translúcido
/// com efeito de desfoque (glass/frosted).
class LiquidBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;

  const LiquidBackButton({
    super.key,
    required this.onPressed,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
