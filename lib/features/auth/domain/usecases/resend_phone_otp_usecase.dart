import '../../../../core/network/result.dart';
import '../repositories/auth_repository.dart';

/// SMS tasdiqlash kodini qayta yuboradi (docs/UI.md: "kodni qayta
/// yuborish... aniq ko'rsatiladi").
class ResendPhoneOtpUseCase {
  const ResendPhoneOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String phoneNumber}) {
    return _repository.resendPhoneOtp(phoneNumber: phoneNumber);
  }
}
