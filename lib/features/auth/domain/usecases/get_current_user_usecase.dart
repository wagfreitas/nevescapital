import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/utils/result.dart';

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<User?>> call() {
    return _repository.getCurrentUser();
  }
}
