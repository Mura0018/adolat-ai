import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase turlaridan test uchun namunalar quruvchi yordamchilar
/// (`test/features/` infratuzilmasi, 2026-07-30 auditi, 2-topilma).
///
/// **Nega alohida fayl:** `AuthResponse`/`User` kabi turlar ko'p
/// majburiy maydon talab qiladi (`appMetadata`, `aud`, `createdAt` ...),
/// va ularning hech biri testning MAZMUNIGA aloqador emas. Bu shovqinni
/// bitta joyga yig'ish har bir testni o'qishga tushunarli qoldiradi.

/// Minimal, lekin yaroqli `User` -- faqat [id] mazmunli, qolgani
/// to'ldiruvchi qiymat.
User buildUser({String id = 'user-1'}) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: DateTime.utc(2026).toIso8601String(),
  );
}

/// Foydalanuvchisi bor `AuthResponse` (muvaffaqiyatli kirish/tasdiqlash).
AuthResponse buildAuthResponse({String userId = 'user-1'}) {
  return AuthResponse(user: buildUser(id: userId));
}

/// Foydalanuvchisiz `AuthResponse` -- Supabase ba'zi holatlarda shunday
/// qaytaradi; repository buni ANIQ xatolik sifatida qayta ishlashi
/// kerak (foydalanuvchi "hech narsa bo'lmadi" holatida qolmasligi
/// uchun -- `DEVELOPMENT_RULES.md`, 18-band).
AuthResponse buildAuthResponseWithoutUser() => AuthResponse();

/// `public.profiles` qatoriga mos xom JSON (snake_case kalitlar --
/// `ProfileModel`ning `@JsonKey` xaritalashini haqiqiy shaklda
/// tekshirish uchun).
Map<String, dynamic> buildProfileJson({
  String id = 'user-1',
  String role = 'citizen',
  String fullName = 'Test Foydalanuvchi',
  String? phoneNumber = '+998901234567',
  String? avatarUrl,
}) {
  return <String, dynamic>{
    'id': id,
    'role': role,
    'full_name': fullName,
    'phone_number': phoneNumber,
    'avatar_url': avatarUrl,
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-02T00:00:00.000Z',
  };
}

/// `public.appeals` qatoriga mos xom JSON.
Map<String, dynamic> buildAppealJson({
  String id = 'appeal-1',
  String status = 'draft',
  String title = 'Sinov murojaati',
  String? officialResponseText,
  String? submittedAt,
}) {
  return <String, dynamic>{
    'id': id,
    'author_id': 'user-1',
    'category_id': 'category-1',
    'recipient_body_id': 'body-1',
    'title': title,
    'body_text': 'Murojaat matni',
    'ai_draft_text': null,
    'status': status,
    'official_response_text': officialResponseText,
    'submitted_at': submittedAt,
    'closed_at': null,
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-02T00:00:00.000Z',
  };
}

/// `public.disputes` qatoriga mos xom JSON.
Map<String, dynamic> buildDisputeJson({
  String id = 'dispute-1',
  String status = 'open',
  String respondentType = 'unregistered',
  String? respondentStatement,
}) {
  return <String, dynamic>{
    'id': id,
    'initiator_id': 'user-1',
    'respondent_profile_id': null,
    'respondent_display_name': 'Qarshi tomon',
    'respondent_type': respondentType,
    'category_id': 'category-1',
    'title': 'Sinov nizosi',
    'description': 'Nizo tavsifi',
    'respondent_statement': respondentStatement,
    'status': status,
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-02T00:00:00.000Z',
    'closed_at': null,
  };
}

/// RLS rad etishini taqlid qiluvchi xatolik (`42501` --
/// `insufficient_privilege`); `mapSupabaseExceptionToFailure` buni
/// `PermissionDeniedFailure`ga aylantirishi shart.
PostgrestException buildRlsDeniedException() {
  return const PostgrestException(message: 'permission denied for table', code: '42501');
}

/// Oddiy server xatoligi (RLS emas).
PostgrestException buildPostgrestException({String code = '23505'}) {
  return PostgrestException(message: 'duplicate key value', code: code);
}
