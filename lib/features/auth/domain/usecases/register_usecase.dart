import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/utils/result.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<User>> call({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? document,
  }) async {
    if (email.isEmpty) {
      return const Error(message: 'Email é obrigatório');
    }

    if (!_isValidEmail(email)) {
      return const Error(message: 'Email inválido');
    }

    if (password.length < 6) {
      return const Error(message: 'Senha deve ter pelo menos 6 caracteres');
    }

    if (name.trim().isEmpty) {
      return const Error(message: 'Nome é obrigatório');
    }

    final sanitizedPhone = phone?.trim();
    final formattedDocument = document?.replaceAll(RegExp(r'\D'), '');

    return _repository.register(
      email: email,
      password: password,
      name: name,
      phone: sanitizedPhone != null && sanitizedPhone.isNotEmpty ? sanitizedPhone : null,
      document: formattedDocument?.isNotEmpty == true ? formattedDocument : null,
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
