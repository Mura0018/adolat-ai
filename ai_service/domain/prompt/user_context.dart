import 'ai_user_role.dart';
import 'prompt_context.dart';

/// So'rov yuborayotgan foydalanuvchi haqida AI'ga zarur bo'lgan **minimal**
/// ma'lumot — rol va til.
///
/// **Ataylab yo'q:** ism, telefon, pasport/PINFL kabi sezgir shaxsiy
/// ma'lumotlar (`docs/adr/ADR-006-hybrid-infrastructure-strategy.md`,
/// "Sezgir ma'lumotlar tasnifi") bu context'ga qo'shilmaydi — AI
/// tahliliga foydalanuvchi identifikatorini emas, faqat rol va til
/// kabi tahlil uchun zarur bo'lgan minimal atributlarni berish kifoya.
class UserContext implements PromptContext {
  const UserContext({required this.role, required this.preferredLanguage});

  final AIUserRole role;
  final String preferredLanguage;

  @override
  String get contextKey => 'user';

  @override
  Map<String, dynamic> toPromptData() {
    return {'role': role.name, 'preferred_language': preferredLanguage};
  }
}
