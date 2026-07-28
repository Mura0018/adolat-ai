import '../domain/entities/ai_context.dart';
import '../domain/entities/ai_conversation.dart';
import '../domain/entities/ai_message.dart';
import '../domain/entities/ai_provider_id.dart';
import '../domain/entities/ai_stream_event.dart';
import '../domain/repositories/ai_cancellation_registry.dart';
import '../domain/repositories/ai_repository.dart';
import '../domain/repositories/conversation_repository.dart';

/// "Presentation" qatlamining backend-kontekstidagi analogi — bu
/// klass UI emas, balki **tashqi chaqiruvchiga ochilgan kirish nuqtasi**
/// (masalan Supabase Edge Function yoki alohida Dart xizmatining HTTP
/// handler'i shu klassni chaqiradi). Flutter'dagi "ekran" tushunchasi
/// bu yerda yo'q — buning o'rniga "so'rovni qabul qilib, domain
/// qatlamiga uzatish" mas'uliyati bor, xuddi Flutter'dagi
/// `presentation/providers/`ning domain use case'larni chaqirishiga
/// o'xshash (`docs/AI_ARCHITECTURE.md`, "Component Diagram").
///
/// **Muhim:** bu klass hech qachon Flutter ilovasi (`lib/`) tomonidan
/// chaqirilmaydi — faqat backend/serverless muhitda ishlaydi.
class AIServiceHandler {
  AIServiceHandler({
    required AIRepository repository,
    required ConversationRepository conversationRepository,
    required AICancellationRegistry cancellationRegistry,
    String Function()? messageIdGenerator,
  }) : _repository = repository,
       _conversationRepository = conversationRepository,
       _cancellationRegistry = cancellationRegistry,
       _generateMessageId = messageIdGenerator ?? _defaultMessageIdGenerator;

  final AIRepository _repository;
  final ConversationRepository _conversationRepository;
  final AICancellationRegistry _cancellationRegistry;
  final String Function() _generateMessageId;

  static int _messageCounter = 0;

  static String _defaultMessageIdGenerator() {
    _messageCounter += 1;
    return 'msg_${DateTime.now().microsecondsSinceEpoch}_$_messageCounter';
  }

  /// Yangi suhbat boshlaydi va uning identifikatorini qaytaradi.
  String startConversation() {
    return _conversationRepository.create().id;
  }

  /// Mavjud suhbatga foydalanuvchi xabarini yozadi, AI so'rovini
  /// yuboradi va natijani oqim sifatida qaytaradi (Module 4, Phase 2A:
  /// "Conversation lifecycle" + "Streaming-ready interfaces" birgalikda
  /// ishlashi).
  ///
  /// Suhbat tarixi bilan bog'lanish:
  /// 1. `userMessageContent` darhol suhbatga (`role: user`) yoziladi —
  ///    so'rov muvaffaqiyatli bo'lishidan qat'i nazar, foydalanuvchi
  ///    nima deganini tarix saqlaydi.
  /// 2. Oqim (`chunk`) bo'laklari yig'iladi (accumulate), lekin
  ///    suhbatga **yozilmaydi** — faqat oraliq holat.
  /// 3. `done` kelganda, to'liq javob (`role: assistant`) suhbatga
  ///    yoziladi.
  /// 4. `error`/`cancelled` kelganda, hech qanday assistant xabari
  ///    yozilmaydi — muvaffaqiyatsiz/bekor qilingan javob tarixni
  ///    "ifloslamaydi".
  Stream<AIStreamEvent> handleRequest({
    required String conversationId,
    required String userMessageContent,
    required AIContext context,
    required AIProviderId providerId,
  }) async* {
    final AIConversation conversationWithUserMessage;
    try {
      conversationWithUserMessage = _conversationRepository.appendMessage(
        conversationId,
        AIMessage(
          id: _generateMessageId(),
          role: AIMessageRole.user,
          content: userMessageContent,
          createdAt: DateTime.now(),
        ),
      );
    } on StateError catch (error) {
      yield AIStreamEventError(message: error.message);
      return;
    }

    final cancellationToken = _cancellationRegistry.register(conversationId);

    await for (final event in _repository.sendMessage(
      conversation: conversationWithUserMessage,
      context: context,
      providerId: providerId,
      cancellationToken: cancellationToken,
    )) {
      switch (event) {
        case AIStreamEventDone(:final response):
          _conversationRepository.appendMessage(
            conversationId,
            AIMessage(
              id: _generateMessageId(),
              role: AIMessageRole.assistant,
              content: response.content,
              createdAt: response.completedAt,
            ),
          );
          _cancellationRegistry.release(conversationId);
        case AIStreamEventCancelled() || AIStreamEventError():
          _cancellationRegistry.release(conversationId);
        case AIStreamEventChunk():
          break; // Faqat oraliq holat -- suhbatga yozilmaydi.
      }
      yield event;
    }
  }

  /// Joriy davom etayotgan so'rovni bekor qiladi (Module 4 talabi:
  /// "Cancellation support").
  void cancelRequest(String conversationId) {
    _cancellationRegistry.cancel(conversationId);
  }
}
