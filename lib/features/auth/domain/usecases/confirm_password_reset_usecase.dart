import '../../../../core/network/result.dart';
import '../repositories/auth_repository.dart';

/// Parolni tiklash so'rovini tasdiqlash kodi bilan yakunlaydi va yangi
/// parol o'rnatadi (docs/UI.md, "Parolni tiklash oqimi").
class ConfirmPasswordResetUseCase {
  const ConfirmPasswordResetUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String identifier,
    required String otpCode,
    required String newPassword,
  }) {
    return _repository.confirmPasswordReset(
      identifier: identifier,
      otpCode: otpCode,
      newPassword: newPassword,
    );
  }
}
