# Clean Architecture (Flutter)

Each feature lives under `lib/features/<feature>/` with 3 layers + presentation sublayers:

```
lib/features/<feature>/
  data/
    datasources/       # Remote/local data sources (abstract + impl)
    models/            # Data models (JSON serialization)
    repositories/      # Repository implementations
    services/          # External service integrations
  domain/
    entities/          # Business entities (pure Dart)
    repositories/      # Repository interfaces (abstract)
    usecases/          # Use cases (single responsibility)
  presentation/
    controllers/       # ChangeNotifier controllers (MVVM)
    factories/         # DI factories (manual, no Riverpod/BLoC)
    helpers/           # Presentation helpers
    screens/           # UI screens (widgets)
```

## Rules

- **Dependencies point inward only**: data -> domain <- presentation
- Domain never imports from data or presentation
- Use cases return `Result<T>` (sealed class) -- never throw for business logic
- Controllers extend `ChangeNotifier` and call use cases
- DI via manual factories (e.g., `AuthUseCaseFactory.createGetUserByCpfUseCase()`)

## Example: Auth Feature

```
features/auth/
  data/
    datasources/auth_remote_datasource.dart    # abstract
    datasources/firebase_auth_remote_datasource.dart  # impl
    models/user_model.dart
    repositories/auth_repository_impl.dart
    services/auth_api_service.dart             # NestJS backend calls
    services/registration_service.dart
  domain/
    entities/user.dart
    repositories/auth_repository.dart          # abstract
    usecases/login_with_otp_usecase.dart
    usecases/get_user_by_cpf_usecase.dart
    usecases/verify_otp_usecase.dart
  presentation/
    controllers/auth_controller.dart           # extends ChangeNotifier
    factories/auth_usecase_factory.dart         # manual DI
    screens/unified_cpf_screen.dart
```

## Shared Code

Cross-cutting concerns live in `lib/shared/` and `lib/core/`:

- `shared/services/` -- FirestoreService, BiometricService, EncryptionService, etc.
- `shared/helpers/` -- CPF validation, formatting, phone helpers
- `shared/components/` -- Reusable widgets (CustomButton, GlassCard, etc.)
- `shared/models/` -- Shared data models (Transaction, Balance)
- `core/utils/` -- Result class, AppLogger, validators
- `core/config/` -- EnvService, AppConfig, FeatureFlags
- `core/theme/` -- AppTheme
- `core/design_system/` -- DesignSystem tokens
