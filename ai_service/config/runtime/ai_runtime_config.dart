import '../../domain/entities/ai_provider_id.dart';
import '../domain/ai_provider_config.dart';

/// Berilgan vaqtdagi TO'LIQ AI konfiguratsiya suratigа (snapshot) --
/// Module 5, Phase 5A talabi: "AI Runtime Configuration -- prepare
/// dynamic configuration loading".
///
/// **Oqim:** Backend/Admin sozlamalari (`config/admin/`) → shu klass →
/// `AIServiceLocator.resolveProviderCredentials()` (`di/
/// ai_service_locator.dart`, Phase 5A yangilanishi) → `AIGateway` →
/// `ai_service/`ning qolgan qismi. Har bir bosqich mustaqil test
/// qilinadigan, sof (pure) transformatsiya.
///
/// **Nega "suratga" (snapshot), jonli (live) obyekt emas:** `AIGatewayImpl`/
/// `AIServiceLocator` o'zgarmas (immutable) qiymatlar bilan ishlaydi --
/// konfiguratsiya o'zgarganda YANGI `AIRuntimeConfig` yaratiladi va
/// qayta yuklanadi (`AIRuntimeConfigProvider.watch()`ga qarang), eski
/// nusxa esa o'zgarmagan holicha qoladi. Bu -- `AIConversation`
/// (Module 4, Phase 2A)dagi bir xil o'zgarmaslik naqshi, endi
/// konfiguratsiya uchun.
class AIRuntimeConfig {
  const AIRuntimeConfig({required this.providerConfigs, required this.loadedAt});

  final Map<AIProviderId, AIProviderConfig> providerConfigs;

  /// Bu surat qachon yuklangani -- diagnostika/keshni eskirganini
  /// aniqlash uchun.
  final DateTime loadedAt;

  bool isEnabled(AIProviderId id) => providerConfigs[id]?.enabled ?? false;

  Iterable<AIProviderId> get enabledProviderIds =>
      providerConfigs.entries.where((e) => e.value.enabled).map((e) => e.key);

  @override
  String toString() =>
      'AIRuntimeConfig(providers: ${providerConfigs.length}, '
      'enabled: ${enabledProviderIds.length}, loadedAt: $loadedAt)';
}
