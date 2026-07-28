import '../../../../core/network/result.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Ilova ishga tushganda mahalliy sessiyani tiklashga urinadi
/// (docs/UI.md, "App Entry Flow", 2–4-qadamlar).
class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser?>> call() {
    return _repository.restoreSession();
  }
}
