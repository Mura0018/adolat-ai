import '../../../../core/network/result.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Tashkilot sifatida ro'yxatdan o'tkazadi (docs/UI.md, "Authentication
/// Screens" — "Tashkilot ro'yxatdan o'tish shakli").
class RegisterOrganizationUseCase {
  const RegisterOrganizationUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser>> call({
    required String password,
    required String fullName,
    required String legalName,
    required String taxId,
    required String legalAddress,
    String? phoneNumber,
    String? email,
    String? contactEmail,
  }) {
    return _repository.registerOrganization(
      password: password,
      fullName: fullName,
      legalName: legalName,
      taxId: taxId,
      legalAddress: legalAddress,
      phoneNumber: phoneNumber,
      email: email,
      contactEmail: contactEmail,
    );
  }
}
