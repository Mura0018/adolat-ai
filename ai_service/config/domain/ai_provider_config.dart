import '../../domain/entities/ai_provider_id.dart';
import 'ai_credential_reference.dart';
import 'ai_provider_cost_control.dart';
import 'ai_provider_token_limits.dart';
import 'ai_provider_usage_limits.dart';

/// Bitta AI provayder uchun admin tomonidan boshqariladigan TO'LIQ
/// konfiguratsiya (Module 5, Phase 5A talabi: "AI Provider
/// Configuration Contract" -- "Create provider-independent
/// configuration models").
///
/// **Nega "provider-independent":** `OpenAI`/`Gemini`/`Claude`/`Local`
/// uchun to'rtta alohida klass YO'Q -- bitta `AIProviderConfig`,
/// [providerId] (`domain/entities/ai_provider_id.dart`, Module 4, Phase 1)
/// orqali farqlanadi. Bu -- loyihaning allaqachon o'rnatilgan
/// "Provider Abstraction" naqshining (`AIProviderAdapter`,
/// `docs/AI_ARCHITECTURE.md`) konfiguratsiya darajasidagi davomi: yangi
/// provayder qo'shish yangi klass talab qilmaydi, faqat yangi
/// `AIProviderConfig` YOZUVI (`config/admin/ai_provider_management_service.dart`
/// orqali).
///
/// **Nega bu klass domain VA simli (wire) shaklning ikkalasi ham:**
/// Module 4, Phase 3A `protocol/`ni `domain/`dan ATAYLAB ajratdi --
/// sabab: klient ISHONCHSIZ (masalan `providerId`ni o'zi tanlamasligi
/// kerak). Admin konfiguratsiyasi uchun bunday ishonch muammosi YO'Q:
/// admin panel (kelgusi klient) allaqachon vakolatli, va bu klassning
/// o'zi (masalan [AICredentialReference]) xavfsizlik xususiyatini
/// (hech qachon xom kalit saqlamaslik) TUR DARAJASIDA ta'minlaydi --
/// alohida "wire mirror" qo'shish shu yerda faqat DUBLIKATSIYA
/// bo'lardi (`DEVELOPMENT_RULES.md`, 7-band -- DRY). Shuning uchun
/// `toJson()`/`fromJson()` to'g'ridan-to'g'ri shu yerda.
class AIProviderConfig {
  const AIProviderConfig({
    required this.providerId,
    required this.enabled,
    required this.activeModel,
    required this.credentialRef,
    required this.usageLimits,
    required this.tokenLimits,
    required this.costControl,
  });

  final AIProviderId providerId;

  /// `false` bo'lsa, bu provayder hech qanday so'rovga xizmat
  /// qilmasligi kerak -- `config/runtime/`, "AI Runtime Configuration"
  /// bo'limiga qarang: `AIServiceLocator.resolveProviderCredentials()`
  /// FAQAT `enabled == true` provayderlar uchun credential hal qiladi.
  final bool enabled;

  /// Provayder ichidagi model identifikatori (masalan `"gpt-4o"`,
  /// `"gemini-1.5-pro"`, `"claude-sonnet"`) -- xom, opaque satr, chunki
  /// har bir provayderning o'z model nomlash konventsiyasi bor (`data/
  /// providers/*_adapter.dart`dagi `model` maydonlariga qarang, Phase
  /// 1'dan beri mavjud, lekin hozircha qattiq kodlangan standart bilan).
  final String activeModel;

  /// Haqiqiy API kalitiga ISHORA -- hech qachon kalitning o'zi emas
  /// (yuqoridagi sinf izohiga qarang).
  final AICredentialReference credentialRef;

  final AIProviderUsageLimits usageLimits;
  final AIProviderTokenLimits tokenLimits;
  final AIProviderCostControlParams costControl;

  Map<String, dynamic> toJson() => {
    'providerId': providerId.name,
    'enabled': enabled,
    'activeModel': activeModel,
    'credentialRef': credentialRef.toJson(),
    'usageLimits': usageLimits.toJson(),
    'tokenLimits': tokenLimits.toJson(),
    'costControl': costControl.toJson(),
  };

  factory AIProviderConfig.fromJson(Map<String, dynamic> json) {
    return AIProviderConfig(
      providerId: AIProviderId.values.byName(json['providerId'] as String),
      enabled: json['enabled'] as bool,
      activeModel: json['activeModel'] as String,
      credentialRef: AICredentialReference.fromJson(
        json['credentialRef'] as Map<String, dynamic>,
      ),
      usageLimits: AIProviderUsageLimits.fromJson(json['usageLimits'] as Map<String, dynamic>),
      tokenLimits: AIProviderTokenLimits.fromJson(json['tokenLimits'] as Map<String, dynamic>),
      costControl: AIProviderCostControlParams.fromJson(
        json['costControl'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIProviderConfig &&
            other.providerId == providerId &&
            other.enabled == enabled &&
            other.activeModel == activeModel &&
            other.credentialRef == credentialRef &&
            other.usageLimits == usageLimits &&
            other.tokenLimits == tokenLimits &&
            other.costControl == costControl);
  }

  @override
  int get hashCode => Object.hash(
    providerId,
    enabled,
    activeModel,
    credentialRef,
    usageLimits,
    tokenLimits,
    costControl,
  );

  @override
  String toString() =>
      'AIProviderConfig(providerId: $providerId, enabled: $enabled, activeModel: $activeModel)';
}
