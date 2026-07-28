import '../../../../core/network/result.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Telefon raqamini SMS kodi bilan tasdiqlaydi (docs/UI.md, "Telefon
/// tasdiqlash (SMS) ekrani") — registratsiya oqimida sessiya birinchi
/// marta shu yerda o'rnatiladi, shuning uchun `AppUser` qaytaradi.
class VerifyPhoneOtpUseCase {
  const VerifyPhoneOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser>> call({
    required String phoneNumber,
    required String otpCode,
  }) {
    return _repository.verifyPhoneOtp(
      phoneNumber: phoneNumber,
      otpCode: otpCode,
    );
  }
}
