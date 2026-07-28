import '../../../../core/network/result.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Telefon/email va parol bilan kiradi (docs/UI.md, "Kirish (login)
/// ekrani").
class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser>> call({
    required String identifier,
    required String password,
  }) {
    return _repository.login(identifier: identifier, password: password);
  }
}
