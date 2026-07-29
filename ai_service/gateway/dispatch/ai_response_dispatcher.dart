import '../../domain/entities/ai_failure.dart';
import '../../domain/entities/ai_stream_event.dart';
import '../../protocol/ai_protocol_error.dart';
import '../../protocol/ai_protocol_status.dart';
import '../../protocol/ai_protocol_stream_event.dart';
import '../../protocol/ai_request_envelope.dart';
import '../../protocol/ai_response_envelope.dart';
import '../../protocol/ai_token_usage.dart';

/// Ichki `Stream<AIStreamEvent>`ni simli `Stream<AIProtocolStreamEvent>`ga
/// aylantiradi (Module 4, Phase 3B talabi: "Response Dispatcher").
///
/// Bu klass aynan `docs/AI_ARCHITECTURE.md`, "Klient ↔ Backend
/// Protokoli" (Phase 3A) bo'limida ochiq qoldirilgan tarjimani amalga
/// oshiradi: o'sha bosqichda `AIStreamEvent` ↔ `AIProtocolStreamEvent`
/// va `AIFailure` ↔ `AIProtocolError` orasidagi bog'lanish ATAYLAB
/// "kelgusi integratsiya bosqichi"ga qoldirilgan edi -- bu bosqich
/// (Gateway) aynan o'sha integratsiya.
class AIResponseDispatcher {
  const AIResponseDispatcher();

  /// [receivedAt] -- backend so'rovni qabul qilgan vaqt (gateway
  /// darajasida qayd etiladi, `AIResponseEnvelope.receivedAt`ga
  /// o'tadi). [events] -- ichki `SendConversationMessageUseCase`
  /// natijasi (qayta urinish/xavfsizlik/xatolik allaqachon hal
  /// qilingan holda).
  Stream<AIProtocolStreamEvent> dispatch({
    required AIRequestEnvelope request,
    required DateTime receivedAt,
    required Stream<AIStreamEvent> events,
  }) async* {
    yield AIProtocolStreamEventStarted(
      requestId: request.requestId,
      conversationId: request.conversationId,
      protocolVersion: request.protocolVersion,
    );

    var sequence = 0;

    await for (final event in events) {
      switch (event) {
        case AIStreamEventChunk(:final deltaContent):
          yield AIProtocolStreamEventChunk(
            requestId: request.requestId,
            conversationId: request.conversationId,
            sequence: sequence,
            deltaContent: deltaContent,
          );
          sequence += 1;

        case AIStreamEventDone(:final response):
          yield AIProtocolStreamEventCompleted(
            requestId: request.requestId,
            response: AIResponseEnvelope(
              responseId: response.id,
              requestId: request.requestId,
              conversationId: response.conversationId,
              assistantMessage: response.content,
              status: AIProtocolStatus.completed,
              tokenUsage: const AITokenUsage(), // joy ajratilgan, Phase 3A/3B'da o'lchanmaydi
              receivedAt: receivedAt,
              respondedAt: response.completedAt,
              protocolVersion: request.protocolVersion,
            ),
          );

        case AIStreamEventCancelled():
          yield AIProtocolStreamEventCancelled(
            requestId: request.requestId,
            conversationId: request.conversationId,
          );

        case AIStreamEventError(:final failure):
          yield AIProtocolStreamEventFailed(
            requestId: request.requestId,
            conversationId: request.conversationId,
            error: _toProtocolError(failure),
          );
      }
    }
  }

  /// `AIFailure` (ichki, `domain/entities/`) → `AIProtocolError`
  /// (simli, `protocol/`) tarjimasi. Sealed klass bo'lgani uchun bu
  /// `switch` TO'LIQ (exhaustive) -- kelgusida `AIFailure`ga yangi
  /// variant qo'shilsa, kompilyator shu joyni yangilashni MAJBUR
  /// qiladi.
  ///
  /// `message` maydoni ichki xatolikning xom matnini EMAS, har bir kod
  /// uchun oldindan tayyorlangan, foydalanuvchiga xavfsiz umumiy
  /// matnni oladi -- provayder ichki tafsilotlari (masalan
  /// `AIProviderFailure.message`) simdan tashqariga chiqmasligi kerak.
  AIProtocolError _toProtocolError(AIFailure failure) {
    return switch (failure) {
      AINetworkFailure() => const AIProtocolError(
        code: AIProtocolErrorCode.network,
        message: 'Tarmoq bilan bog\'lanishda xatolik yuz berdi',
        retryable: true,
      ),
      AITimeoutFailure() => const AIProtocolError(
        code: AIProtocolErrorCode.timeout,
        message: 'So\'rov belgilangan vaqt ichida yakunlanmadi',
        retryable: true,
      ),
      AIRateLimitFailure() => const AIProtocolError(
        code: AIProtocolErrorCode.rateLimited,
        message: 'Juda ko\'p so\'rov yuborildi, birozdan keyin qayta urinib ko\'ring',
        retryable: true,
      ),
      AIProviderFailure() => const AIProtocolError(
        code: AIProtocolErrorCode.providerError,
        message: 'AI xizmatida vaqtinchalik nosozlik yuz berdi',
        retryable: false,
      ),
      AISafetyRejectionFailure() => const AIProtocolError(
        code: AIProtocolErrorCode.safetyRejected,
        message: 'So\'rov xavfsizlik tekshiruvidan o\'tmadi',
        retryable: false,
      ),
      AIProviderNotConfiguredFailure() => const AIProtocolError(
        code: AIProtocolErrorCode.providerNotConfigured,
        message: 'So\'ralgan AI xizmati hozircha mavjud emas',
        retryable: false,
      ),
      AIConversationNotFoundFailure() => const AIProtocolError(
        code: AIProtocolErrorCode.conversationNotFound,
        message: 'Suhbat topilmadi',
        retryable: false,
      ),
      AIConversationClosedFailure() => const AIProtocolError(
        code: AIProtocolErrorCode.conversationClosed,
        message: 'Suhbat yopilgan',
        retryable: false,
      ),
      AIUnauthorizedFailure() => const AIProtocolError(
        code: AIProtocolErrorCode.unauthorized,
        message: 'Ushbu amalni bajarishga huquqingiz yo\'q',
        retryable: false,
      ),
      AIInvalidRequestFailure(:final reason) => AIProtocolError(
        code: AIProtocolErrorCode.invalidRequest,
        message: 'So\'rov noto\'g\'ri shakllangan: $reason',
        retryable: false,
      ),
      AIUnknownFailure() => const AIProtocolError(
        code: AIProtocolErrorCode.unknown,
        message: 'Noma\'lum xatolik yuz berdi',
        retryable: false,
      ),
    };
  }
}
