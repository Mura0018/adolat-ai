import '../../error/failure.dart';
import '../domain/ai_client_message.dart';
import '../domain/ai_client_message_role.dart';
import '../domain/ai_client_stream_event.dart';
import '../protocol/ai_protocol_error.dart';
import '../protocol/ai_protocol_stream_event.dart';

/// Backend protokol modellarini (`protocol/`) ilova domeni modellariga
/// (`domain/`) tarjima qiladi (Module 4, Phase 4A talabi: "Response
/// Mapping" + "Error Handling").
///
/// **Ikkita mustaqil tarjima:**
/// 1. `AiProtocolStreamEvent` (simli, 5 holat) -> `AiClientStreamEvent`
///    (domen, xuddi shu 5 holat, lekin xatoligi `Failure` bilan).
/// 2. `AiProtocolError` -> `Failure` (`core/error/failure.dart`) --
///    ilovaning YAGONA, mavjud xatolik turi. AI-ga xos ikkinchi xatolik
///    ierarxiyasi ATAYLAB yaratilmagan -- `Result<T>`,
///    `describeErrorForUser()`, `FailureUserMessage.userMessage` kabi
///    butun ilova bo'ylab ishlaydigan mexanizmlar shu orqali AI oqimi
///    uchun ham avtomatik ishlaydi.
///
/// Xatolik matni (`AiProtocolError.message`) qasddan `Failure`ga
/// SAQLANMAYDI (masalan `Failure.server(message: ...)`ga qo'yilmaydi
/// har doim) -- chunki `FailureUserMessage.userMessage`
/// (`core/error/failure_presentation.dart`) allaqachon har bir variant
/// uchun xavfsiz, oldindan yozilgan matn beradi; backend'dan kelgan xom
/// matn faqat diagnostika (`AiDiagnosticsLogger`) uchun saqlanadi, UI'ga
/// hech qachon to'g'ridan-to'g'ri chiqarilmaydi (`docs/SECURITY.md`,
/// "API Security").
abstract final class AiResponseMapper {
  static AiClientStreamEvent mapStreamEvent(AiProtocolStreamEvent event) {
    return switch (event) {
      AiProtocolStreamEventStarted() => AiClientStreamStarted(
        requestId: event.requestId,
        conversationId: event.conversationId,
      ),
      AiProtocolStreamEventChunk(:final sequence, :final deltaContent) => AiClientStreamChunk(
        requestId: event.requestId,
        conversationId: event.conversationId,
        sequence: sequence,
        deltaContent: deltaContent,
      ),
      AiProtocolStreamEventCompleted(:final response) => AiClientStreamCompleted(
        requestId: event.requestId,
        conversationId: response.conversationId,
        message: AiClientMessage(
          id: response.responseId,
          role: AiClientMessageRole.assistant,
          content: response.assistantMessage ?? '',
          createdAt: response.respondedAt,
        ),
      ),
      AiProtocolStreamEventCancelled() => AiClientStreamCancelled(
        requestId: event.requestId,
        conversationId: event.conversationId,
      ),
      AiProtocolStreamEventFailed(:final error) => AiClientStreamFailed(
        requestId: event.requestId,
        conversationId: event.conversationId,
        failure: mapProtocolError(error),
      ),
    };
  }

  /// `AiProtocolErrorCode` -> `Failure` xaritalash jadvali. Sealed
  /// bo'lmagan (enum-asosli) manba bo'lgani uchun to'liqlikni (barcha
  /// kodlar qamrab olinganini) `mapProtocolError_test.dart`
  /// `AiProtocolErrorCode.values`ni aylanib tekshiradi.
  static Failure mapProtocolError(AiProtocolError error) {
    return switch (error.code) {
      AiProtocolErrorCode.network => const Failure.network(),
      // Timeout -- tarmoq qatlamining o'zi kabi bir xil foydalanuvchi
      // ta'siriga ega (javob kelmadi), alohida `Failure` varianti yo'q.
      AiProtocolErrorCode.timeout => const Failure.network(),
      AiProtocolErrorCode.rateLimited => Failure.server(
        message: error.message,
        code: 'rate_limited',
      ),
      AiProtocolErrorCode.providerError => Failure.server(
        message: error.message,
        code: 'provider_error',
      ),
      AiProtocolErrorCode.providerNotConfigured => Failure.server(
        message: error.message,
        code: 'provider_not_configured',
      ),
      // Xavfsizlik rad etilishi -- so'rov mazmuni qabul qilinmadi,
      // ruxsat masalasi emas -- `validation`ga eng yaqin mavjud variant.
      AiProtocolErrorCode.safetyRejected => Failure.validation(message: error.message),
      AiProtocolErrorCode.conversationNotFound => Failure.validation(message: error.message),
      AiProtocolErrorCode.conversationClosed => Failure.validation(message: error.message),
      AiProtocolErrorCode.invalidRequest => Failure.validation(message: error.message),
      // Autentifikatsiya/avtorizatsiya -- ilovada alohida variant yo'q,
      // ikkalasi ham "ruxsat yo'q" ma'nosida `permissionDenied`ga mos.
      AiProtocolErrorCode.unauthenticated => Failure.permissionDenied(message: error.message),
      AiProtocolErrorCode.unauthorized => Failure.permissionDenied(message: error.message),
      AiProtocolErrorCode.unknown => Failure.unknown(message: error.message),
    };
  }
}
