/// Classe base para todos os tipos de falhas na aplicação
abstract class Failure {
  final String message;
  final String? code;
  
  const Failure({
    required this.message,
    this.code,
  });
}

/// Falha de servidor
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
  });
}

/// Falha de rede
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
  });
}

/// Falha de cache
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
  });
}

/// Falha de validação
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
  });
}

/// Falha de autenticação
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });
}
