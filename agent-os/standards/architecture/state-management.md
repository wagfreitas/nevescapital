# State Management

Uses `ChangeNotifier` + `ListenableBuilder` pattern. No Riverpod, no BLoC, no Provider package.

## Controller Pattern

Controllers extend `ChangeNotifier` and manage UI state:

```dart
class AuthController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> loginWithCpf({required String cpf, required String password}) async {
    _setLoading(true);
    _clearError();
    try {
      final result = await useCase(cpf: cpf);
      if (result.isError) {
        _setError(result.errorMessage ?? 'Erro');
        return false;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }
}
```

## Rules

- Always check `_isDisposed` before calling `notifyListeners()`
- Cancel `StreamSubscription` in `dispose()`
- Use `_setLoading(true/false)` wrapper to ensure consistent state
- Use `_setError()` / `_clearError()` helpers
- Loading states: set `true` at start, `false` in `finally`
- Return `bool` from async methods to indicate success/failure
- Enum states for complex flows (e.g., `LoginProgress.idle|searchingUser|authenticating|success|error`)

## DI Pattern

Manual factories -- no injection framework:

```dart
class AuthUseCaseFactory {
  static Future<GetUserByCpfUseCase> createGetUserByCpfUseCase() async {
    // Wire up dependencies manually
    return GetUserByCpfUseCase(repository: AuthRepositoryImpl());
  }
}
```

## UI Binding

Use `ListenableBuilder` (Flutter 3.10+) in widgets:

```dart
ListenableBuilder(
  listenable: authController,
  builder: (context, child) {
    if (authController.isLoading) return CustomLoading();
    return YourWidget();
  },
)
```
