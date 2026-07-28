import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/result.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/confirm_password_reset_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_citizen_usecase.dart';
import '../../domain/usecases/register_organization_usecase.dart';
import '../../domain/usecases/request_password_reset_usecase.dart';
import '../../domain/usecases/resend_phone_otp_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import '../../domain/usecases/verify_phone_otp_usecase.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(AuthRemoteDataSource());
});

final registerCitizenUseCaseProvider = Provider<RegisterCitizenUseCase>((
  ref,
) {
  return RegisterCitizenUseCase(ref.watch(authRepositoryProvider));
});

final registerOrganizationUseCaseProvider =
    Provider<RegisterOrganizationUseCase>((ref) {
      return RegisterOrganizationUseCase(ref.watch(authRepositoryProvider));
    });

final verifyPhoneOtpUseCaseProvider = Provider<VerifyPhoneOtpUseCase>((ref) {
  return VerifyPhoneOtpUseCase(ref.watch(authRepositoryProvider));
});

final resendPhoneOtpUseCaseProvider = Provider<ResendPhoneOtpUseCase>((ref) {
  return ResendPhoneOtpUseCase(ref.watch(authRepositoryProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final requestPasswordResetUseCaseProvider =
    Provider<RequestPasswordResetUseCase>((ref) {
      return RequestPasswordResetUseCase(ref.watch(authRepositoryProvider));
    });

final confirmPasswordResetUseCaseProvider =
    Provider<ConfirmPasswordResetUseCase>((ref) {
      return ConfirmPasswordResetUseCase(ref.watch(authRepositoryProvider));
    });

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final restoreSessionUseCaseProvider = Provider<RestoreSessionUseCase>((ref) {
  return RestoreSessionUseCase(ref.watch(authRepositoryProvider));
});

/// Joriy foydalanuvchi holatining reaktiv oqimi — GoRouter auth guard va
/// splash ekrani shu providerni kuzatadi (docs/UI.md, "App Entry Flow";
/// `AuthRepository.authStateChanges`ga qarang: birinchi qiymat sessiya
/// tekshiruvidan so'ng, keyingi qiymatlar kirish/chiqish sodir bo'lganda
/// keladi).
final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Ro'yxatdan o'tish/kirish/parolni tiklash/chiqish amallari uchun holat
/// boshqaruvchisi (`AppealFormController` naqshiga muvofiq —
/// docs/ARCHITECTURE.md, "Ichki Kod Arxitekturasi").
///
/// `AsyncValue<AppUser?>`: muvaffaqiyatli amal natijasida `AppUser`
/// mavjud bo'lsa (`login`/`verifyPhoneOtp`) shu qiymat, aks holda
/// (`registerCitizen`, `requestPasswordReset` va h.k.) `null` bilan
/// `AsyncValue.data` — ekran buni "muvaffaqiyatli, lekin bu amal
/// foydalanuvchi ma'lumotini qaytarmaydi" deb talqin qiladi.
class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  AuthController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<bool> registerCitizen({
    required String password,
    required String fullName,
    String? phoneNumber,
    String? email,
  }) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(registerCitizenUseCaseProvider)
        .call(
          password: password,
          fullName: fullName,
          phoneNumber: phoneNumber,
          email: email,
        );
    return _applyVoidResult(result);
  }

  Future<bool> registerOrganization({
    required String password,
    required String fullName,
    required String legalName,
    required String taxId,
    required String legalAddress,
    String? phoneNumber,
    String? email,
    String? contactEmail,
  }) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(registerOrganizationUseCaseProvider)
        .call(
          password: password,
          fullName: fullName,
          legalName: legalName,
          taxId: taxId,
          legalAddress: legalAddress,
          phoneNumber: phoneNumber,
          email: email,
          contactEmail: contactEmail,
        );
    return _applyVoidResult(result);
  }

  Future<bool> verifyPhoneOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(verifyPhoneOtpUseCaseProvider)
        .call(phoneNumber: phoneNumber, otpCode: otpCode);
    return _applyUserResult(result);
  }

  Future<bool> resendPhoneOtp({required String phoneNumber}) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(resendPhoneOtpUseCaseProvider)
        .call(phoneNumber: phoneNumber);
    return _applyVoidResult(result);
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(loginUseCaseProvider)
        .call(identifier: identifier, password: password);
    return _applyUserResult(result);
  }

  Future<bool> requestPasswordReset({required String identifier}) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(requestPasswordResetUseCaseProvider)
        .call(identifier: identifier);
    return _applyVoidResult(result);
  }

  Future<bool> confirmPasswordReset({
    required String identifier,
    required String otpCode,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(confirmPasswordResetUseCaseProvider)
        .call(
          identifier: identifier,
          otpCode: otpCode,
          newPassword: newPassword,
        );
    return _applyVoidResult(result);
  }

  Future<bool> logout() async {
    state = const AsyncValue.loading();
    final result = await _ref.read(logoutUseCaseProvider).call();
    return _applyVoidResult(result);
  }

  bool _applyVoidResult(Result<void> result) {
    state = switch (result) {
      ResultOk() => const AsyncValue.data(null),
      ResultError(:final failure) => AsyncValue.error(
        failure,
        StackTrace.current,
      ),
    };
    return result.isOk;
  }

  bool _applyUserResult(Result<AppUser> result) {
    state = switch (result) {
      ResultOk(:final data) => AsyncValue.data(data),
      ResultError(:final failure) => AsyncValue.error(
        failure,
        StackTrace.current,
      ),
    };
    return result.isOk;
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AppUser?>>((ref) {
      return AuthController(ref);
    });
