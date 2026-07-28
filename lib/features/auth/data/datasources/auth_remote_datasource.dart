import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/supabase/supabase_client.dart';
import '../models/organization_profile_model.dart';
import '../models/profile_model.dart';

/// Supabase Auth va `public.profiles`/`public.organization_profiles`
/// bilan to'g'ridan-to'g'ri ishlaydigan datasource
/// (docs/DATABASE.md, 1–2-jadvallar; supabase/migrations/
/// 20260727000001_authentication_foundation.sql, `handle_new_user()`).
///
/// Bu klass hech qanday ruxsat tekshiruvini o'zi amalga oshirmaydi —
/// profil yozuvlari `handle_new_user()` trigger'i orqali avtomatik
/// yaratiladi, o'qish RLS orqali cheklanadi (`profiles_select`).
class AuthRemoteDataSource {
  AuthRemoteDataSource();

  SupabaseClient get _client => SupabaseService.client;

  /// Supabase Auth `signUp`/`signInWithPassword`/`verifyOTP`/`resend`
  /// barchasi email va telefonni **bir vaqtda emas, aynan bittasini**
  /// qabul qiladi (`GoTrueClient` implementatsiyasidagi `assert`).
  bool _looksLikeEmail(String identifier) => identifier.contains('@');

  /// `handle_new_user()` trigger'i `raw_user_meta_data`dan aynan shu
  /// kalitlarni o'qiydi — nomlar bu yerda va migratsiyada bir xil
  /// bo'lishi shart.
  Future<void> signUpCitizen({
    required String password,
    required String fullName,
    String? phoneNumber,
    String? email,
  }) {
    assert(
      (phoneNumber != null) ^ (email != null),
      'phoneNumber yoki email\'dan aynan bittasi berilishi shart',
    );
    return _client.auth.signUp(
      email: email,
      phone: phoneNumber,
      password: password,
      data: {
        'role': 'citizen',
        'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      },
    );
  }

  Future<void> signUpOrganization({
    required String password,
    required String fullName,
    required String legalName,
    required String taxId,
    required String legalAddress,
    String? phoneNumber,
    String? email,
    String? contactEmail,
  }) {
    assert(
      (phoneNumber != null) ^ (email != null),
      'phoneNumber yoki email\'dan aynan bittasi berilishi shart',
    );
    return _client.auth.signUp(
      email: email,
      phone: phoneNumber,
      password: password,
      data: {
        'role': 'organization',
        'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        'legal_name': legalName,
        'tax_id': taxId,
        'legal_address': legalAddress,
        if (contactEmail != null) 'contact_email': contactEmail,
      },
    );
  }

  /// Muvaffaqiyatli bo'lsa sessiya o'rnatiladi — qaytgan `Session.user.id`
  /// repository tomonidan profilni o'qish uchun ishlatiladi.
  Future<AuthResponse> verifyPhoneOtp({
    required String phoneNumber,
    required String otpCode,
  }) {
    return _client.auth.verifyOTP(
      phone: phoneNumber,
      token: otpCode,
      type: OtpType.sms,
    );
  }

  Future<void> resendPhoneOtp({required String phoneNumber}) {
    return _client.auth.resend(type: OtpType.sms, phone: phoneNumber);
  }

  Future<AuthResponse> login({
    required String identifier,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: _looksLikeEmail(identifier) ? identifier : null,
      phone: _looksLikeEmail(identifier) ? null : identifier,
      password: password,
    );
  }

  /// Email uchun rasmiy tiklash oqimi; telefon uchun (Supabase'da alohida
  /// "parolni tiklash" endpointi yo'q) yangi OTP yuborish orqali amalga
  /// oshiriladi — [confirmPasswordReset] shu kodni tasdiqlab parolni
  /// yangilaydi.
  Future<void> requestPasswordReset({required String identifier}) {
    if (_looksLikeEmail(identifier)) {
      return _client.auth.resetPasswordForEmail(identifier);
    }
    return _client.auth.signInWithOtp(phone: identifier);
  }

  Future<void> confirmPasswordReset({
    required String identifier,
    required String otpCode,
    required String newPassword,
  }) async {
    if (_looksLikeEmail(identifier)) {
      await _client.auth.verifyOTP(
        email: identifier,
        token: otpCode,
        type: OtpType.recovery,
      );
    } else {
      await _client.auth.verifyOTP(
        phone: identifier,
        token: otpCode,
        type: OtpType.sms,
      );
    }
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> logout() {
    return _client.auth.signOut();
  }

  Future<ProfileModel?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return ProfileModel.fromJson(row);
  }

  Future<OrganizationProfileModel?> fetchOrganizationProfile(
    String profileId,
  ) async {
    final row = await _client
        .from('organization_profiles')
        .select()
        .eq('profile_id', profileId)
        .maybeSingle();
    if (row == null) return null;
    return OrganizationProfileModel.fromJson(row);
  }

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
}
