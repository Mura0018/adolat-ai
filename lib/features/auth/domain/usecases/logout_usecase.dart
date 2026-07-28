import '../../../../core/network/result.dart';
import '../repositories/auth_repository.dart';

/// Joriy sessiyani tugatadi (docs/UI.md, "Chiqish (logout) tasdiqlashi").
class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() {
    return _repository.logout();
  }
}
