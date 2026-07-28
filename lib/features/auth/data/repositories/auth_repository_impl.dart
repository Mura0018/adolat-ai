import '../../../../core/error/failure.dart';
import '../../../../core/network/result.dart';
import '../../../../services/supabase/supabase_exception_mapper.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/organization_details.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/organization_profile_model.dart';
import '../models/profile_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  /// `profiles` va (kerak bo'lsa) `organization_profiles`ni birlashtirib
  /// to'liq `AppUser` quradi — ikkita jadval, bitta domain entity.
  Future<AppUser> _resolveAppUser(String userId) async {
    final profile = await _remote.fetchProfile(userId);
    if (profile == null) {
      throw StateError(
        'Profil topilmadi ($userId) — hisob hali to\'liq faollashmagan '
        'bo\'lishi mumkin.',
      );
    }

    OrganizationDetails? organizationDetails;
    if (profile.role == 'organization') {
      final organization = await _remote.fetchOrganizationProfile(userId);
      organizationDetails = organization?.toEntity();
    }

    return profile.toEntity(organizationDetails: organizationDetails);
  }

  @override
  Future<Result<void>> registerCitizen({
    required String password,
    required String fullName,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      await _remote.signUpCitizen(
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        email: email,
      );
      return const Result.ok(null);
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void>> registerOrganization({
    required String password,
    required String fullName,
    required String legalName,
    required String taxId,
    required String legalAddress,
    String? phoneNumber,
    String? email,
    String? contactEmail,
  }) async {
    try {
      await _remote.signUpOrganization(
        password: password,
        fullName: fullName,
        legalName: legalName,
        taxId: taxId,
        legalAddress: legalAddress,
        phoneNumber: phoneNumber,
        email: email,
        contactEmail: contactEmail,
      );
      return const Result.ok(null);
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<AppUser>> verifyPhoneOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      final response = await _remote.verifyPhoneOtp(
        phoneNumber: phoneNumber,
        otpCode: otpCode,
      );
      final userId = response.user?.id;
      if (userId == null) {
        return const Result.error(
          Failure.server(
            message: 'Tasdiqlashdan keyin foydalanuvchi topilmadi',
          ),
        );
      }
      final appUser = await _resolveAppUser(userId);
      return Result.ok(appUser);
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void>> resendPhoneOtp({required String phoneNumber}) async {
    try {
      await _remote.resendPhoneOtp(phoneNumber: phoneNumber);
      return const Result.ok(null);
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<AppUser>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await _remote.login(
        identifier: identifier,
        password: password,
      );
      final userId = response.user?.id;
      if (userId == null) {
        return const Result.error(
          Failure.server(message: 'Kirishdan keyin foydalanuvchi topilmadi'),
        );
      }
      final appUser = await _resolveAppUser(userId);
      return Result.ok(appUser);
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void>> requestPasswordReset({required String identifier}) async {
    try {
      await _remote.requestPasswordReset(identifier: identifier);
      return const Result.ok(null);
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void>> confirmPasswordReset({
    required String identifier,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      await _remote.confirmPasswordReset(
        identifier: identifier,
        otpCode: otpCode,
        newPassword: newPassword,
      );
      return const Result.ok(null);
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _remote.logout();
      return const Result.ok(null);
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<AppUser?>> restoreSession() async {
    try {
      final userId = _remote.currentSession?.user.id;
      if (userId == null) {
        return const Result.ok(null);
      }
      final appUser = await _resolveAppUser(userId);
      return Result.ok(appUser);
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _remote.onAuthStateChange.asyncMap((state) async {
      final userId = state.session?.user.id;
      if (userId == null) return null;
      try {
        return await _resolveAppUser(userId);
      } catch (_) {
        return null;
      }
    });
  }
}
