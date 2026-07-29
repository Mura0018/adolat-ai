import '../../../features/auth/domain/entities/user_role.dart';
import 'ai_client_prompt_context.dart';

/// So'rov yuborayotgan foydalanuvchi haqida AI'ga zarur bo'lgan
/// **minimal** ma'lumot -- rol va til.
///
/// **Ataylab yo'q:** ism, telefon, pasport/PINFL kabi sezgir shaxsiy
/// ma'lumotlar (`docs/adr/ADR-006-hybrid-infrastructure-strategy.md`)
/// bu context'ga qo'shilmaydi.
///
/// **Nega `UserRole`ni (`features/auth/`) qayta ishlatadi, backend
/// `AIUserRole`ni EMAS:** bu -- `lib/` ICHIDAGI qayta foydalanish
/// (chegara buzilmaydi, ikkalasi ham Flutter ilovasi kodi). Backend esa
/// `lib/`ga bog'liq bo'la olmagani uchun o'z mustaqil `AIUserRole`sini
/// yuritadi (`ai_service/domain/prompt/ai_user_role.dart`) -- ikkalasi
/// wire orqali `role.name`/`role.dbValue` bir xil satr ('citizen'/
/// 'organization'/'admin') orqali kelishadi.
class AiClientUserContext implements AiClientPromptContext {
  const AiClientUserContext({required this.role, required this.preferredLanguage});

  final UserRole role;
  final String preferredLanguage;

  @override
  String get contextKey => 'user';

  @override
  Map<String, dynamic> toPromptData() => {
    'role': role.dbValue,
    'preferred_language': preferredLanguage,
  };
}
