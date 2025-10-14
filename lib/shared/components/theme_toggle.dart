import 'package:flutter/material.dart';
import '../../core/theme/theme_controller.dart';

/// Widget para alternar entre temas
class ThemeToggle extends StatelessWidget {
  final ThemeController themeController;
  final bool showLabel;
  
  const ThemeToggle({
    super.key,
    required this.themeController,
    this.showLabel = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, child) {
        return PopupMenuButton<ThemeMode>(
          icon: Icon(
            themeController.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          tooltip: 'Alterar tema',
          onSelected: (ThemeMode mode) {
            themeController.setThemeMode(mode);
          },
          itemBuilder: (context) => [
            PopupMenuItem<ThemeMode>(
              value: ThemeMode.light,
              child: Row(
                children: [
                  Icon(
                    Icons.light_mode,
                    color: ThemeMode.light == themeController.themeMode
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Claro',
                    style: TextStyle(
                      color: ThemeMode.light == themeController.themeMode
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<ThemeMode>(
              value: ThemeMode.dark,
              child: Row(
                children: [
                  Icon(
                    Icons.dark_mode,
                    color: ThemeMode.dark == themeController.themeMode
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Escuro',
                    style: TextStyle(
                      color: ThemeMode.dark == themeController.themeMode
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<ThemeMode>(
              value: ThemeMode.system,
              child: Row(
                children: [
                  Icon(
                    Icons.settings_system_daydream,
                    color: ThemeMode.system == themeController.themeMode
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sistema',
                    style: TextStyle(
                      color: ThemeMode.system == themeController.themeMode
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Botão simples para alternar tema
class ThemeToggleButton extends StatelessWidget {
  final ThemeController themeController;
  
  const ThemeToggleButton({
    super.key,
    required this.themeController,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, child) {
        return IconButton(
          onPressed: () {
            themeController.toggleTheme();
          },
          icon: Icon(
            themeController.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          tooltip: themeController.isDarkMode ? 'Tema claro' : 'Tema escuro',
        );
      },
    );
  }
}
