import '../../domain/entities/ai_provider_id.dart';

/// Bitta provayderga emas, BUTUN AI xususiyatiga tegishli global
/// sozlamalar (Module 5, Phase 5A talabi: "AI settings management").
///
/// `AIProviderConfig`dan (`ai_provider_config.dart`) FARQI: o'sha klass
/// BITTA provayderning konfiguratsiyasi, bu klass esa "AI xususiyati
/// umuman yoqilganmi", "provayder tanlanmasa qaysi biri standart" kabi
/// provayderdan YUQORI darajadagi qarorlar.
class AIGlobalSettings {
  const AIGlobalSettings({
    required this.aiFeatureEnabled,
    required this.defaultProviderId,
    this.maintenanceMessage,
  });

  /// `false` bo'lsa, `AIGatewayImpl`gacha yetib borishdan OLDIN butun
  /// AI xususiyati o'chirilgan deb hisoblanishi kerak -- masalan
  /// texnik xizmat ko'rsatish oynasi uchun. Bu bayroqni HAQIQIY
  /// tekshirish (masalan `AIGatewayImpl`ga yangi parametr sifatida)
  /// hali ULANMAGAN -- `docs/AI_ARCHITECTURE.md`, "AI Configuration
  /// and Control Foundation (Module 5, Phase 5A)"ga qarang.
  final bool aiFeatureEnabled;

  /// `AIRequestDispatcher.selectProvider` (Module 4, Phase 3B) hali
  /// "chaqiruvchi tomonidan majburiy in'ektsiya qilinadigan funksiya"
  /// -- standart strategiyasiz. Bu maydon kelgusida shu funksiya
  /// UCHUN eng sodda strategiyaning (agar boshqa hech narsa mos
  /// kelmasa, shu provayderni tanlash) manbai bo'lishi mo'ljallangan.
  final AIProviderId defaultProviderId;

  /// `aiFeatureEnabled == false` bo'lganda foydalanuvchiga
  /// ko'rsatiladigan xabar (`DEVELOPMENT_RULES.md`, 17-band -- "No
  /// Dead End Rule": foydalanuvchi hech qachon sababsiz rad javobi
  /// olmasligi kerak).
  final String? maintenanceMessage;

  Map<String, dynamic> toJson() => {
    'aiFeatureEnabled': aiFeatureEnabled,
    'defaultProviderId': defaultProviderId.name,
    if (maintenanceMessage != null) 'maintenanceMessage': maintenanceMessage,
  };

  factory AIGlobalSettings.fromJson(Map<String, dynamic> json) {
    return AIGlobalSettings(
      aiFeatureEnabled: json['aiFeatureEnabled'] as bool,
      defaultProviderId: AIProviderId.values.byName(json['defaultProviderId'] as String),
      maintenanceMessage: json['maintenanceMessage'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIGlobalSettings &&
            other.aiFeatureEnabled == aiFeatureEnabled &&
            other.defaultProviderId == defaultProviderId &&
            other.maintenanceMessage == maintenanceMessage);
  }

  @override
  int get hashCode => Object.hash(aiFeatureEnabled, defaultProviderId, maintenanceMessage);

  @override
  String toString() =>
      'AIGlobalSettings(aiFeatureEnabled: $aiFeatureEnabled, defaultProviderId: $defaultProviderId)';
}
