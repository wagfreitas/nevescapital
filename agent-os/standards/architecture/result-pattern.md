# Result Pattern

All use cases and service methods that can fail MUST return `Result<T>` -- never throw for business logic.

```dart
// lib/core/utils/result.dart
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Error<T> extends Result<T> {
  final String message;
  final String? code;
  const Error({required this.message, this.code});
}
```

## Usage in Use Cases

```dart
// Correct
Future<Result<User>> execute({required String cpf}) async {
  final user = await repository.getUserByCpf(cpf);
  if (user == null) return Error(message: 'CPF nao cadastrado');
  return Success(user);
}

// Wrong -- never throw in use cases
Future<User> execute({required String cpf}) async {
  final user = await repository.getUserByCpf(cpf);
  if (user == null) throw Exception('CPF nao cadastrado');
  return user;
}
```

## Checking Results in Controllers

```dart
final result = await getUserUseCase(cpf: cpf);

if (result.isError) {
  _setError(result.errorMessage ?? 'Erro');
  return false;
}

final user = result.dataOrNull;
```

## Extension Methods

```dart
extension ResultExtensions<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;

  T? get dataOrNull => switch (this) {
    Success<T>(data: final data) => data,
    Error<T>() => null,
  };

  String? get errorMessage => switch (this) {
    Success<T>() => null,
    Error<T>(message: final message) => message,
  };
}
```

## Rules

- `sealed class` ensures exhaustive pattern matching (Dart 3.0+)
- Infrastructure errors (network, DB) may still throw -- catch at controller level
- Error has optional `code` field for categorized errors
- Use Dart 3 `switch` expressions for pattern matching
