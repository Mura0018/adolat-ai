import '../gateway/ai_gateway_client.dart';
import '../protocol/ai_protocol_error.dart';
import '../protocol/ai_protocol_status.dart';
import '../protocol/ai_protocol_stream_event.dart';
import '../protocol/ai_request_envelope.dart';
import '../protocol/ai_response_envelope.dart';
import '../protocol/ai_token_usage.dart';

/// `AiGatewayClient`ning SOXTA (fake) implementatsiyasi -- haqiqiy
/// backend hali qurilmagan davrda pipeline'ni oxirigacha sinash uchun
/// (Module 4, Phase 4A talabi: "Use mock responses only" / "Loading &
/// Streaming Flow -- generate fake chunks for testing only").
///
/// **Hech qanday tarmoq chaqiruvi, hech qanday provayder SDK'si yo'q**
/// -- butun javob shu klassning o'zida, xotirada generatsiya qilinadi.
/// Standart holatda `chunkDelay = Duration.zero`, shuning uchun
/// test'larda haqiqiy kutish (real wall-clock delay) YO'Q -- CI'ni
/// sekinlashtirmaydi. Rivojlantirish paytida qo'lda ko'rish uchun
/// `chunkDelay`ni oshirib, oqimni "jonli" ko'rinishda simulyatsiya
/// qilish mumkin.
///
/// **Kelgusi almashtirish:** haqiqiy backend qurilganda, shu klass
/// o'rniga `HttpAiGatewayClient`/`WebSocketAiGatewayClient` kabi
/// implementatsiya DI'da (`../di/ai_client_providers.dart`) almashtiriladi
/// -- `AiGatewayClient` interfeysini ishlatuvchi hech qanday chaqiruvchi
/// kod (`AiRequestPipeline` va undan yuqorisi) o'zgarmaydi (`docs/
/// AI_ARCHITECTURE.md`, "Kelgusi backend almashtirish strategiyasi").
class MockAiGatewayClient implements AiGatewayClient {
  const MockAiGatewayClient({
    this.responseText =
        'Bu -- Module 4, Phase 4A soxta (mock) AI javobi. Haqiqiy backend '
        'hali ulanmagan.',
    this.wordsPerChunk = 3,
    this.chunkDelay = Duration.zero,
    this.failWith,
    this.respondentAtGenerator,
  });

  /// Yakuniy assistant javobi sifatida qaytariladigan matn.
  final String responseText;

  /// Har bir `chunk`da nechta so'z chiqarilishi -- kattaroq qiymat kamroq,
  /// kichikroq qiymat ko'proq oqim bo'lagini simulyatsiya qiladi.
  final int wordsPerChunk;

  /// Ikkita bo'lak orasidagi (va so'rov bilan birinchi bo'lak orasidagi)
  /// sun'iy kutish -- standart holatda yo'q (testlar uchun xavfsiz).
  final Duration chunkDelay;

  /// Berilsa, oqim `chunk` chiqarmasdan darhol shu xatolik bilan
  /// yakunlanadi -- xatolik yo'lini (`AiResponseMapper`, pipeline)
  /// sinash uchun.
  final AiProtocolError? failWith;

  /// Test'larda deterministik vaqt uchun; `null` bo'lsa `DateTime.now()`.
  final DateTime Function()? respondentAtGenerator;

  @override
  Stream<AiProtocolStreamEvent> sendMessage(
    AiRequestEnvelope request, {
    Object? credential,
  }) async* {
    yield AiProtocolStreamEventStarted(
      requestId: request.requestId,
      conversationId: request.conversationId,
    );

    if (chunkDelay > Duration.zero) {
      await Future<void>.delayed(chunkDelay);
    }

    if (failWith case final error?) {
      yield AiProtocolStreamEventFailed(
        requestId: request.requestId,
        conversationId: request.conversationId,
        error: error,
      );
      return;
    }

    final words = responseText.split(' ');
    var sequence = 0;
    for (var i = 0; i < words.length; i += wordsPerChunk) {
      final chunkWords = words.skip(i).take(wordsPerChunk).join(' ');
      final isFirst = i == 0;
      yield AiProtocolStreamEventChunk(
        requestId: request.requestId,
        conversationId: request.conversationId,
        sequence: sequence,
        deltaContent: isFirst ? chunkWords : ' $chunkWords',
      );
      sequence += 1;
      if (chunkDelay > Duration.zero) {
        await Future<void>.delayed(chunkDelay);
      }
    }

    final respondedAt = (respondentAtGenerator ?? DateTime.now)();
    yield AiProtocolStreamEventCompleted(
      requestId: request.requestId,
      response: AiResponseEnvelope(
        responseId: 'mock_resp_${request.requestId}',
        requestId: request.requestId,
        conversationId: request.conversationId,
        assistantMessage: responseText,
        status: AiProtocolStatus.completed,
        tokenUsage: const AiTokenUsage(),
        receivedAt: request.requestedAt,
        respondedAt: respondedAt,
      ),
    );
  }
}
