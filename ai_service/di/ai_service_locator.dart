import '../data/providers/ai_provider_adapter.dart';
import '../data/providers/claude_provider_adapter.dart';
import '../data/providers/gemini_provider_adapter.dart';
import '../data/providers/local_llm_provider_adapter.dart';
import '../data/providers/openai_provider_adapter.dart';
import '../data/repositories/ai_repository_impl.dart';
import '../data/session/in_memory_cancellation_registry.dart';
import '../data/session/in_memory_conversation_repository.dart';
import '../domain/entities/ai_provider_id.dart';
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
  }) {
    final bundle = _buildUseCases(
      providerCredentials: providerCredentials,
      safetyService: safetyService,
      retryPolicy: retryPolicy,
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
  static AIGateway buildGateway({
    required Map<AIProviderId, String> providerCredentials,
    required AISafetyService safetyService,
    required AIProviderId Function(AIRequestEnvelope request) selectProvider,
    AIRetryPolicy retryPolicy = const AIRetryPolicy(),
    AITimeoutPolicy timeoutPolicy = const AITimeoutPolicy(),
  }) {
    final bundle = _buildUseCases(
      providerCredentials: providerCredentials,
      safetyService: safetyService,
      retryPolicy: retryPolicy,
    );

    return AIGatewayImpl(
      requestDispatcher: AIRequestDispatcher(
        sendMessageUseCase: bundle.sendConversationMessageUseCase,
        selectProvider: selectProvider,
      ),
      timeoutPolicy: timeoutPolicy,
    );
  }

  static _UseCaseBundle _buildUseCases({
    required Map<AIProviderId, String> providerCredentials,
    required AISafetyService safetyService,
    required AIRetryPolicy retryPolicy,
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

    final ConversationRepository conversationRepository =
        InMemoryConversationRepository();
    final AICancellationRegistry cancellationRegistry =
        InMemoryCancellationRegistry();

    return _UseCaseBundle(
      startConversationUseCase: StartConversationUseCase(conversationRepository),
      sendConversationMessageUseCase: SendConversationMessageUseCase(
        repository: repository,
        conversationRepository: conversationRepository,
        cancellationRegistry: cancellationRegistry,
        retryPolicy: retryPolicy,
      ),
      cancelConversationUseCase: CancelConversationUseCase(cancellationRegistry),
      closeConversationUseCase: CloseConversationUseCase(conversationRepository),
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
