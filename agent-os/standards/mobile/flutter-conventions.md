# Flutter Conventions

## SDK & Environment

- Dart SDK: `>=3.5.0 <4.0.0`
- Flutter: latest stable
- Target: iOS & Android
- Brand: "Pag Pag" (payment/POS app)

## Theme System

Single theme defined in `lib/core/theme/app_theme.dart`. Always dark mode (green-on-black):

```dart
class AppTheme {
  static const Color primaryColor = Color(0xFF28CC28);      // Green buttons
  static const Color backgroundColor = Color(0xFF122118);   // Dark green background
  static const Color surfaceColor = Color(0xFF1A2B1F);      // Surface
  static const Color textPrimary = Color(0xFFFFFFFF);       // White
  static const Color textSecondary = Color(0xFFA1A1AA);     // Zinc-400
}
```

- `lightTheme` and `darkTheme` are identical (always dark)
- Material 3 enabled (`useMaterial3: true`)
- Glass effect colors for cards: `glassBackground`, `glassBorder`

## Design System Tokens

`lib/core/design_system/design_system.dart` defines spacing, radius, and button standards:

```dart
class DesignSystem {
  static const double buttonHeight = 56.0;
  static const double buttonBorderRadius = 12.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double radiusLG = 12.0;
}
```

## Navigation

Imperative navigation (no GoRouter, no auto_route):

```dart
Navigator.push(context, MaterialPageRoute(builder: (_) => NextScreen()));
Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
Navigator.pushAndRemoveUntil(context, route, (route) => false);
```

## Shared Components

Reusable widgets in `lib/shared/components/`:
- `CustomButton` -- primary/secondary/destructive variants
- `CustomTextField` / `SmartTextFormField` -- themed inputs
- `GlassCard` / `GlassAppBar` -- glass morphism effects
- `CustomModal` -- bottom sheet modals
- `CustomLoading` -- loading indicator
- `CpfInputField`, `PhoneInputField`, `CepInputField` -- formatted inputs

## Rules

- Use `AppTheme` constants for all colors -- never hardcode hex values
- Use `DesignSystem` tokens for spacing and sizing
- Screens go in `features/<feature>/presentation/screens/`
- Shared widgets go in `shared/components/`
- All text in Portuguese (pt-BR)
- Button text: capitalize first letter of each word ("Salvar Alteracoes")
