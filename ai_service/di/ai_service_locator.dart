import '../config/runtime/ai_credential_resolver.dart';
import '../config/runtime/ai_runtime_config.dart';
import '../data/providers/ai_provider_adapter.dart';
import '../data/providers/claude_provider_adapter.dart';
import '../data/providers/gemini_provider_adapter.dart';
import '../data/providers/local_llm_provider_adapter.dart';
import '../data/providers/openai_provider_adapter.dart';
import '../data/repositories/ai_repository_impl.dart';
import '../data/session/in_memory_cancellation_registry.dart';
import '../data/session/in_memory_conversation_repository.dart';
import '../domain/entities/ai_provider_id.dart';
import '../domain/quota/ai_usage_quota.dart';
import '../domain/repositories/ai_cancellation_registry.dart';
import '../domain/repositories/ai_repository.dart';
import '../domain/repositories/conversation_repository.dart';
import '../domain/retry/ai_retry_policy.dart';
import '../domain/usecases/cancel_conversation_usecase.dart';
import '../domain/usecases/close_conversation_usecase.dart';
import '../domain/usecases/send_conversation_message_usecase.dart';
import '../domain/usecases/start_conversation_usecase.dart';
import '../gateway/ai_gateway.dart';
import '../gateway/ai_gateway_impl.dart';
import '../gateway/dispatch/ai_request_dispatcher.dart';
import '../gateway/ratelimit/ai_rate_limiter.dart';
import '../gateway/timeout/ai_timeout_policy.dart';
import '../presentation/ai_service_handler.dart';
import '../protocol/ai_request_envelope.dart';
import '../safety/ai_safety_service.dart';

/// Yagona kompozitsiya nuqtasi (composition root) — barcha qatlamlarni
/// bir-biriga bog'laydi (Module 4 talabi: "Dependency Injection —
/// Register everything correctly").
///
/// **Nega Riverpod emas:** Riverpod Flutter widget hayot davriga
/// bog'langan holat boshqaruv kutubxonasi — bu xizmat Flutter ilovasi
/// emas (backend/serverless konteksti), shuning uchun oddiy, ochiq
/// konstruktor-in'ektsiya (constructor injection) ishlatiladi.
///
/// **`AISafetyService` uchun implementatsiya talab qilinadi:**
/// `ai_service/safety/`da hozircha konkret klass yo'q (Module 4, Phase
/// 1 talabi — "No implementation yet"), shuning uchun bu funksiya
/// chaqiruvchidan uni **majburiy** parametr sifatida kutadi — soxta/
/// bo'sh implementatsiya bu yerda yashirincha berilmaydi.
class AIServiceLocator {
  const AIServiceLocator._();

  static AIServiceHandler build({
    required Map<AIProviderId, String> providerCredentials,
    required AISafetyService safetyService,
    AIRetryPolicy retryPolicy = const AIRetryPolicy(),
    ConversationRepository? conversationRepository,
    AICancellationRegistry? cancellationRegistry,
  }) {
    final bundle = _buildUseCases(
      providerCredentials: providerCredentials,
      safetyService: safetyService,
      retryPolicy: retryPolicy,
      conversationRepository: conversationRepository,
      cancellationRegistry: cancellationRegistry,
    );

    return AIServiceHandler(
      startConversationUseCase: bundle.startConversationUseCase,
      sendConversationMessageUseCase: bundle.sendConversationMessageUseCase,
      cancelConversationUseCase: bundle.cancelConversationUseCase,
      closeConversationUseCase: bundle.closeConversationUseCase,
    );
  }

  /// `AIGateway`ni quradi -- simli (`AIRequestEnvelope`) chegara orqali
  /// kiruvchi chaqiruvchilar uchun (Module 4, Phase 3B).
  ///
  /// **Muhim:** `build()` bilan bir vaqtda, ALOHIDA chaqirilsa, ikkitasi
  /// MUSTAQIL `InMemoryConversationRepository` nusxasiga ega bo'ladi
  /// (suhbat holati ULASHILMAYDI) -- bu `InMemoryConversationRepository`
  /// hujjatida allaqachon qayd etilgan, ko'p-nusxali cheklovning bir
  /// ko'rinishi, xolos. Amalda faqat BITTASI (haqiqiy kelgusi backend
  /// qanday integratsiya qilinishiga qarab: to'g'ridan-to'g'ri Dart
  /// chaqiruvi -- `build()`, yoki HTTP/WebSocket kirish nuqtasi --
  /// `buildGateway()`) ishlatilishi kutiladi.
  ///
  /// [selectProvider] -- qaysi AI provayder so'rovga xizmat qilishini
  /// hal qiluvchi funksiya (`AIRequestDispatcher`ga qarang) -- haqiqiy
  /// tanlov strategiyasi (`docs/adr/ADR-005`) kelgusi bosqich, shuning
  /// uchun **majburiy** parametr (yashirin standart yo'q).
  ///
  /// **Phase 4C yangilanishi ("Backend Implementation Readiness"):**
  /// [rateLimiter]/[quotaStore]/[quotaPolicy] -- `AIGatewayImpl`ga
  /// to'g'ridan-to'g'ri o'tkaziladi (ikkalasi ham ixtiyoriy, standart
  /// holatda `null` -- tekshiruv o'chirilgan, mavjud xatti-harakat
  /// o'zgarmaydi). Haqiqiy backend qurilganda faqat shu ikkita
  /// parametrni chaqiruvchi tomonidan berish YETARLI.
  static AIGateway buildGateway({
    required Map<AIProviderId, String> providerCredentials,
    required AISafetyService safetyService,
    required AIProviderId Function(AIRequestEnvelope request) selectProvider,
    AIRetryPolicy retryPolicy = const AIRetryPolicy(),
    AITimeoutPolicy timeoutPolicy = const AITimeoutPolicy(),
    ConversationRepository? conversationRepository,
    AICancellationRegistry? cancellationRegistry,
    AIRateLimiter? rateLimiter,
    AIUsageQuotaStore? quotaStore,
    AIUsageQuotaPolicy? quotaPolicy,
  }) {
    final bundle = _buildUseCases(
      providerCredentials: providerCredentials,
      safetyService: safetyService,
      retryPolicy: retryPolicy,
      conversationRepository: conversationRepository,
      cancellationRegistry: cancellationRegistry,
    );

    return AIGatewayImpl(
      requestDispatcher: AIRequestDispatcher(
        sendMessageUseCase: bundle.sendConversationMessageUseCase,
        selectProvider: selectProvider,
      ),
      timeoutPolicy: timeoutPolicy,
      rateLimiter: rateLimiter,
      quotaStore: quotaStore,
      quotaPolicy: quotaPolicy,
    );
  }

  /// Admin tomonidan boshqariladigan [AIRuntimeConfig]ni `build()`/
  /// `buildGateway()`ning `providerCredentials` parametri kutgan
  /// shaklga aylantiradi (Module 5, Phase 5A talabi: "AI Runtime
  /// Configuration -- Backend/Admin settings → AI Gateway → AI
  /// Service").
  ///
  /// **Oqim:** chaqiruvchi (kelgusi HTTP kirish nuqtasi) avval
  /// `AIRuntimeConfigProvider.load()` orqali [AIRuntimeConfig] oladi,
  /// so'ng shu funksiyani chaqiradi, natijani esa `build()`/
  /// `buildGateway()`ga `providerCredentials` sifatida uzatadi:
  ///
  /// ```dart
  /// final runtimeConfig = await runtimeConfigProvider.load();
  /// final credentials = await AIServiceLocator.resolveProviderCredentials(
  ///   runtimeConfig: runtimeConfig,
  ///   credentialResolver: credentialResolver,
  /// );
  /// final gateway = AIServiceLocator.buildGateway(
  ///   providerCredentials: credentials,
  ///   ...
  /// );
  /// ```
  ///
  /// **Faqat YOQILGAN (`enabled == true`) provayderlar uchun** haqiqiy
  /// hisob ma'lumoti hal qilinadi (`AICredentialResolver.resolve()`
  /// chaqiriladi) -- o'chirilgan provayder uchun mos yozuv `providerCredentials`da
  /// UMUMAN bo'lmaydi, shuning uchun `_buildUseCases()`dagi mavjud
  /// mantiq (`if (providerCredentials[id] case final apiKey?) ...`,
  /// Module 4, Phase 1'dan beri o'zgarmagan) uni avtomatik ravishda
  /// "sozlanmagan" deb hisoblaydi -- `AIProviderNotConfiguredFailure`
  /// bilan bir xil yo'l, hech qanday yangi shart-band kerak emas edi.
  ///
  /// Bu funksiya `credentialResolver`ni O'ZI TANLAMAYDI/yaratmaydi --
  /// chaqiruvchi tomonidan majburiy in'ektsiya qilinadi (`AISafetyService`
  /// bilan bir xil konventsiya: haqiqiy implementatsiya hali yo'q,
  /// shuning uchun yashirin soxta/bo'sh variant berilmaydi).
  static Future<Map<AIProviderId, String>> resolveProviderCredentials({
    required AIRuntimeConfig runtimeConfig,
    required AICredentialResolver credentialResolver,
  }) async {
    final result = <AIProviderId, String>{};
    for (final providerId in runtimeConfig.enabledProviderIds) {
      final config = runtimeConfig.providerConfigs[providerId]!;
      result[providerId] = await credentialResolver.resolve(config.credentialRef);
    }
    return result;
  }

  /// [conversationRepository]/[cancellationRegistry] -- Phase 4C
  /// yangilanishi: kompozitsiya ildizini PLUGGABLE qiladi. Standart
  /// holatda (ikkalasi ham `null`) avvalgidek `InMemory...`
  /// implementatsiyalari yaratiladi -- xatti-harakat o'zgarmaydi.
  /// Haqiqiy backend (masalan Postgres-asosli `ConversationRepository`)
  /// qurilganda, `AIServiceLocator`ning o'zini o'zgartirmasdan shu
  /// yerga in'ektsiya qilinishi mo'ljallangan (`data/session/
  /// ai_conversation_persistence_contract.dart`, "Conversation
  /// persistence contract" bilan bog'liq).
  static _UseCaseBundle _buildUseCases({
    required Map<AIProviderId, String> providerCredentials,
    required AISafetyService safetyService,
    required AIRetryPolicy retryPolicy,
    ConversationRepository? conversationRepository,
    AICancellationRegistry? cancellationRegistry,
  }) {
    final providers = <AIProviderId, AIProviderAdapter>{
      if (providerCredentials[AIProviderId.openAI] case final apiKey?)
        AIProviderId.openAI: OpenAiProviderAdapter(apiKey: apiKey),
      if (providerCredentials[AIProviderId.gemini] case final apiKey?)
        AIProviderId.gemini: GeminiProviderAdapter(apiKey: apiKey),
      if (providerCredentials[AIProviderId.claude] case final apiKey?)
        AIProviderId.claude: ClaudeProviderAdapter(apiKey: apiKey),
      if (providerCredentials[AIProviderId.local] case final endpointUrl?)
        AIProviderId.local: LocalLlmProviderAdapter(endpointUrl: endpointUrl),
    };

    final AIRepository repository = AIRepositoryImpl(
      providers: providers,
      safetyService: safetyService,
    );

    final ConversationRepository resolvedConversationRepository =
        conversationRepository ?? InMemoryConversationRepository();
    final AICancellationRegistry resolvedCancellationRegistry =
        cancellationRegistry ?? InMemoryCancellationRegistry();

    return _UseCaseBundle(
      startConversationUseCase: StartConversationUseCase(resolvedConversationRepository),
      sendConversationMessageUseCase: SendConversationMessageUseCase(
        repository: repository,
        conversationRepository: resolvedConversationRepository,
        cancellationRegistry: resolvedCancellationRegistry,
        retryPolicy: retryPolicy,
      ),
      cancelConversationUseCase: CancelConversationUseCase(resolvedCancellationRegistry),
      closeConversationUseCase: CloseConversationUseCase(resolvedConversationRepository),
    );
  }
}

/// `build()`/`buildGateway()` orasidagi umumiy qurish mantig'ini
/// (provayder xaritasi, repository, usecase'lar) takrorlamaslik uchun
/// ichki, xususiy tashuvchi (carrier).
class _UseCaseBundle {
  const _UseCaseBundle({
    required this.startConversationUseCase,
    required this.sendConversationMessageUseCase,
    required this.cancelConversationUseCase,
    required this.closeConversationUseCase,
  });

  final StartConversationUseCase startConversationUseCase;
  final SendConversationMessageUseCase sendConversationMessageUseCase;
  final CancelConversationUseCase cancelConversationUseCase;
  final CloseConversationUseCase closeConversationUseCase;
}
