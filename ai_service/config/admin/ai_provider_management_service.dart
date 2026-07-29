import '../../domain/entities/ai_provider_id.dart';
import '../domain/ai_provider_config.dart';

/// Admin panelning "Provider Management" ekrani chaqirishi mo'ljallangan
/// shartnoma (Module 5, Phase 5A talabi: "Admin Control Architecture
/// -- provider management") -- **faqat interfeys, hech qanday
/// implementatsiya yo'q**, UI yo'q.
///
/// `AIProviderConfig` (`config/domain/ai_provider_config.dart`)ning
/// to'liq hayot davri: ro'yxat, bitta yozuvni o'qish, yaratish/yangilash
/// (upsert -- provayder soni kichik va sobit, `AIProviderId.values`
/// bilan chegaralangan, shuning uchun alohida "create" bilan "update"ni
/// ajratish keraksiz murakkablik) va tezkor yoqish/o'chirish.
abstract interface class AIProviderManagementService {
  Future<List<AIProviderConfig>> listProviders();

  Future<AIProviderConfig?> getProvider(AIProviderId providerId);

  Future<void> upsertProvider(AIProviderConfig config);

  /// [upsertProvider]ning to'liq konfiguratsiyani qayta yuborishini
  /// talab qilmaydigan qulaylik metodi -- admin panelda "yoqish/
  /// o'chirish" ko'pincha bitta tugma, boshqa maydonlarni o'zgartirmasdan.
  Future<void> setEnabled({required AIProviderId providerId, required bool enabled});
}
