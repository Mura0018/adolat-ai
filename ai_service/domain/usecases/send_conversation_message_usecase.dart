import '../entities/ai_context.dart';
import '../entities/ai_conversation.dart';
import '../entities/ai_failure.dart';
import '../entities/ai_message.dart';
import '../entities/ai_provider_id.dart';
import '../entities/ai_stream_event.dart';
import '../repositories/ai_cancellation_registry.dart';
import '../repositories/ai_repository.dart';
import '../repositories/conversation_exceptions.dart';
import '../repositories/conversation_repository.dart';
import '../retry/ai_retry_executor.dart';
import '../retry/ai_retry_policy.dart';

/// Foydalanuvchi xabarini mavjud suhbatga yozadi, AI so'rovini
/// (qayta-urinish siyosati bilan o'ralgan holda) yuboradi va suhbat
/// tarixini yakuniy natijaga qarab yangilaydi (Module 4, Phase 2C
/// talabi: "AI UseCases" + "Conversation orchestration").
///
/// **Nega bu orkestratsiya avval `presentation/ai_service_handler.dart`da
/// edi, endi bu yerda:** suhbat tarixi bilan qanday bog'lanish
/// (xabarni qachon yozish, qachon yozmaslik, qayta urinishni qachon
/// qo'llash) — bu BIZNES QOIDASI, "tashqi chaqiruvchiga ochilgan kirish
/// nuqtasi" mas'uliyati emas. `AIServiceHandler` endi shu qoidani
/// bilmaydi — faqat shu usecase'ni chaqiradi (xuddi Flutter
/// ekranlarining `ref.read(someUseCaseProvider).call(...)` chaqirishi
/// kabi, `docs/AI_ARCHITECTURE.md`, "Component Diagram").
class SendConversationMessageUseCase {
  SendConversationMessageUseCase({
    required AIRepository repository,
    required ConversationRepository conversationRepository,
    required AICancellationRegistry cancellationRegistry,
    AIRetryPolicy retryPolicy = const AIRetryPolicy(),
    String Function()? messageIdGenerator,
  }) : _repository = repository,
       _conversationRepository = conversationRepository,
       _cancellationRegistry = cancellationRegistry,
       _retryExecutor = AIRetryExecutor(retryPolicy),
       _generateMessageId = messageIdGenerator ?? _defaultMessageIdGenerator;

  final AIRepository _repository;
  final ConversationRepository _conversationRepository;
  final AICancellationRegistry _cancellationRegistry;
  final AIRetryExecutor _retryExecutor;
  final String Function() _generateMessageId;

  static int _messageCounter = 0;

  static String _defaultMessageIdGenerator() {
    _messageCounter += 1;
    return 'msg_${DateTime.now().microsecondsSinceEpoch}_$_messageCounter';
  }

  /// Suhbat tarixi bilan bog'lanish:
  /// 1. `userMessageContent` darhol suhbatga (`role: user`) yoziladi —
  ///    so'rov muvaffaqiyatli bo'lishidan qat'i nazar, foydalanuvchi
  ///    nima deganini tarix saqlaydi.
  /// 2. AI so'rovi `AIRetryPolicy` asosida qayta urinish bilan
  ///    yuboriladi (`AIRetryExecutor`, streaming-xavfsiz qoidaga
  ///    muvofiq).
  /// 3. Oqim (`chunk`) bo'laklari suhbatga **yozilmaydi** — faqat
  ///    oraliq holat.
  /// 4. `done` kelganda, to'liq javob (`role: assistant`) suhbatga
  ///    yoziladi.
  /// 5. `error`/`cancelled` kelganda, hech qanday assistant xabari
  ///    yozilmaydi — muvaffaqiyatsiz/bekor qilingan javob tarixni
  ///    "ifloslamaydi".
  Stream<AIStreamEvent> call({
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
    } on ConversationNotFoundException {
      yield AIStreamEventError(
        failure: AIConversationNotFoundFailure(conversationId: conversationId),
      );
      return;
    } on ConversationClosedException {
      yield AIStreamEventError(
        failure: AIConversationClosedFailure(conversationId: conversationId),
      );
      return;
    }

    final cancellationToken = _cancellationRegistry.register(conversationId);

    final events = _retryExecutor.run(
      () => _repository.sendMessage(
        conversation: conversationWithUserMessage,
        context: context,
        providerId: providerId,
        cancellationToken: cancellationToken,
      ),
    );

    await for (final event in events) {
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
}
