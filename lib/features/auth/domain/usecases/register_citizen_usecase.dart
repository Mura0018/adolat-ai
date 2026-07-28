import '../../../../core/network/result.dart';
import '../repositories/auth_repository.dart';

/// Fuqaro sifatida ro'yxatdan o'tkazadi (docs/UI.md, "Authentication
/// Screens" — "Fuqaro ro'yxatdan o'tish shakli"). `Result<void>` sababi:
/// `AuthRepository.registerCitizen`ga qarang.
class RegisterCitizenUseCase {
  const RegisterCitizenUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String password,
    required String fullName,
    String? phoneNumber,
    String? email,
  }) {
    return _repository.registerCitizen(
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
    );
  }
}
