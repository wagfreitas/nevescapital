/// Classe para representar o resultado de operações que podem falhar
sealed class Result<T> {
  const Result();
}

/// Resultado de sucesso
class Success<T> extends Result<T> {
  final T data;
  
  const Success(this.data);
}

/// Resultado de falha
class Error<T> extends Result<T> {
  final String message;
  final String? code;
  
  const Error({
    required this.message,
    this.code,
  });
}

/// Extensões para facilitar o uso do Result
extension ResultExtensions<T> on Result<T> {
  /// Verifica se é sucesso
  bool get isSuccess => this is Success<T>;
  
  /// Verifica se é erro
  bool get isError => this is Error<T>;
  
  /// Obtém os dados se for sucesso, null caso contrário
  T? get dataOrNull => switch (this) {
    Success<T>(data: final data) => data,
    Error<T>() => null,
  };
  
  /// Obtém a mensagem de erro se for erro, null caso contrário
  String? get errorMessage => switch (this) {
    Success<T>() => null,
    Error<T>(message: final message) => message,
  };
}
