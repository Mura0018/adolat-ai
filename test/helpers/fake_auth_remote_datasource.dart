import 'package:adolat_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:adolat_ai/features/auth/data/models/organization_profile_model.dart';
import 'package:adolat_ai/features/auth/data/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `AuthRemoteDataSource`ning test uchun boshqariladigan (programmable)
/// o'rnini bosuvchisi.
///
/// **Nega mock kutubxona emas:** loyihada `mockito`/`mocktail`
/// bog'liqligi yo'q va uni faqat test uchun qo'shish `pubspec.yaml`ni
/// kengaytiradi. Qo'lda yozilgan fake bu yerda yetarli, chunki
/// shartnoma kichik va barqaror -- `ai_service/` testlarida
/// (`InMemoryCaseRepository` va h.k.) allaqachon qo'llanilgan naqsh.
///
/// Har bir metod uchun: qaytariladigan qiymatni yoki TASHLANADIGAN
/// xatolikni oldindan belgilash mumkin; chaqiruv argumentlari
/// tekshirish uchun saqlanadi.
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  // --- Sozlanadigan javoblar ---
  AuthResponse? loginResponse;
  AuthResponse? verifyOtpResponse;
  ProfileModel? profile;
  OrganizationProfileModel? organizationProfile;
  Session? sessionToReturn;
  Stream<AuthState> authStateStream = const Stream<AuthState>.empty();

  /// Belgilansa, tegishli metod shu xatolikni tashlaydi.
  Object? throwOnLogin;
  Object? throwOnVerifyOtp;
  Object? throwOnFetchProfile;
  Object? throwOnSignUp;
  Object? throwOnLogout;
  Object? throwOnResend;
  Object? throwOnPasswordReset;

  // --- Yozib olingan chaqiruvlar ---
  final List<Map<String, Object?>> calls = <Map<String, Object?>>[];
  int fetchProfileCallCount = 0;
  int fetchOrganizationProfileCallCount = 0;

  void _record(String method, [Map<String, Object?> args = const {}]) {
    calls.add(<String, Object?>{'method': method, ...args});
  }

  bool wasCalled(String method) => calls.any((c) => c['method'] == method);

  Map<String, Object?> callOf(String method) =>
      calls.firstWhere((c) => c['method'] == method);

  @override
  Future<void> signUpCitizen({
    required String password,
    required String fullName,
    String? phoneNumber,
    String? email,
  }) async {
    _record('signUpCitizen', {
      'password': password,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
    });
    if (throwOnSignUp != null) throw throwOnSignUp!;
  }

  @override
  Future<void> signUpOrganization({
    required String password,
    required String fullName,
    required String legalName,
    required String taxId,
    required String legalAddress,
    String? phoneNumber,
    String? email,
    String? contactEmail,
  }) async {
    _record('signUpOrganization', {
      'fullName': fullName,
      'legalName': legalName,
      'taxId': taxId,
      'legalAddress': legalAddress,
      'phoneNumber': phoneNumber,
      'email': email,
      'contactEmail': contactEmail,
    });
    if (throwOnSignUp != null) throw throwOnSignUp!;
  }

  @override
  Future<AuthResponse> verifyPhoneOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    _record('verifyPhoneOtp', {'phoneNumber': phoneNumber, 'otpCode': otpCode});
    if (throwOnVerifyOtp != null) throw throwOnVerifyOtp!;
    return verifyOtpResponse ?? AuthResponse();
  }

  @override
  Future<void> resendPhoneOtp({required String phoneNumber}) async {
    _record('resendPhoneOtp', {'phoneNumber': phoneNumber});
    if (throwOnResend != null) throw throwOnResend!;
  }

  @override
  Future<AuthResponse> login({
    required String identifier,
    required String password,
  }) async {
    _record('login', {'identifier': identifier, 'password': password});
    if (throwOnLogin != null) throw throwOnLogin!;
    return loginResponse ?? AuthResponse();
  }

  @override
  Future<void> requestPasswordReset({required String identifier}) async {
    _record('requestPasswordReset', {'identifier': identifier});
    if (throwOnPasswordReset != null) throw throwOnPasswordReset!;
  }

  @override
  Future<void> confirmPasswordReset({
    required String identifier,
    required String otpCode,
    required String newPassword,
  }) async {
    _record('confirmPasswordReset', {
      'identifier': identifier,
      'otpCode': otpCode,
      'newPassword': newPassword,
    });
    if (throwOnPasswordReset != null) throw throwOnPasswordReset!;
  }

  @override
  Future<void> logout() async {
    _record('logout');
    if (throwOnLogout != null) throw throwOnLogout!;
  }

  @override
  Future<ProfileModel?> fetchProfile(String userId) async {
    fetchProfileCallCount += 1;
    _record('fetchProfile', {'userId': userId});
    if (throwOnFetchProfile != null) throw throwOnFetchProfile!;
    return profile;
  }

  @override
  Future<OrganizationProfileModel?> fetchOrganizationProfile(String userId) async {
    fetchOrganizationProfileCallCount += 1;
    _record('fetchOrganizationProfile', {'userId': userId});
    return organizationProfile;
  }

  @override
  Session? get currentSession => sessionToReturn;

  @override
  Stream<AuthState> get onAuthStateChange => authStateStream;
}
