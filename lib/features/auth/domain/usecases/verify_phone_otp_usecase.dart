import '../../../../core/network/result.dart';
import '../repositories/auth_repository.dart';

/// Telefon raqamini SMS kodi bilan tasdiqlaydi (docs/UI.md, "Telefon
/// tasdiqlash (SMS) ekrani").
class VerifyPhoneOtpUseCase {
  const VerifyPhoneOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String phoneNumber,
    required String otpCode,
  }) {
    return _repository.verifyPhoneOtp(
      phoneNumber: phoneNumber,
      otpCode: otpCode,
    );
  }
}
