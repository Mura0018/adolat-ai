import '../domain/ai_global_settings.dart';

/// Admin panelning "AI Settings" ekrani chaqirishi mo'ljallangan
/// shartnoma (Module 5, Phase 5A talabi: "Admin Control Architecture
/// -- AI settings management") -- **faqat interfeys, hech qanday
/// implementatsiya yo'q**, UI yo'q (`AISafetyService` konventsiyasi).
///
/// `AIGlobalSettings` (`config/domain/ai_global_settings.dart`)ning
/// hayot davri boshqaruvi -- CRUD emas, chunki global sozlama har doim
/// BITTA yozuv (ko'p nusxali ro'yxat emas).
abstract interface class AIAdminSettingsService {
  Future<AIGlobalSettings> getSettings();

  Future<void> updateSettings(AIGlobalSettings settings);
}
