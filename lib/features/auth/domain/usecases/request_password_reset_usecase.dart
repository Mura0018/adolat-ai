import '../../../../core/network/result.dart';
import '../repositories/auth_repository.dart';

/// Parolni tiklash so'rovini boshlaydi (docs/UI.md, "Parolni tiklash
/// oqimi").
class RequestPasswordResetUseCase {
  const RequestPasswordResetUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String identifier}) {
    return _repository.requestPasswordReset(identifier: identifier);
  }
}
