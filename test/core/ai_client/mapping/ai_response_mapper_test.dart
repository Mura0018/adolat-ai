import 'package:adolat_ai/core/ai_client/domain/ai_client_stream_event.dart';
import 'package:adolat_ai/core/ai_client/mapping/ai_response_mapper.dart';
import 'package:adolat_ai/core/ai_client/protocol/ai_protocol_error.dart';
import 'package:adolat_ai/core/ai_client/protocol/ai_protocol_status.dart';
import 'package:adolat_ai/core/ai_client/protocol/ai_protocol_stream_event.dart';
import 'package:adolat_ai/core/ai_client/protocol/ai_response_envelope.dart';
import 'package:adolat_ai/core/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiResponseMapper.mapStreamEvent', () {
    test('started maps to AiClientStreamStarted', () {
      const event = AiProtocolStreamEventStarted(requestId: 'r1', conversationId: 'c1');

      expect(AiResponseMapper.mapStreamEvent(event), isA<AiClientStreamStarted>());
    });

    test('chunk maps to AiClientStreamChunk preserving sequence and content', () {
      const event = AiProtocolStreamEventChunk(
        requestId: 'r1',
        conversationId: 'c1',
        sequence: 3,
        deltaContent: 'bo\'lak',
      );

      final mapped = AiResponseMapper.mapStreamEvent(event) as AiClientStreamChunk;

      expect(mapped.sequence, 3);
      expect(mapped.deltaContent, 'bo\'lak');
    });

    test('completed maps to AiClientStreamCompleted carrying the assistant message', () {
      final event = AiProtocolStreamEventCompleted(
        requestId: 'r1',
        response: AiResponseEnvelope(
          responseId: 'resp1',
          requestId: 'r1',
          conversationId: 'c1',
          assistantMessage: 'javob matni',
          status: AiProtocolStatus.completed,
          receivedAt: DateTime.utc(2026, 1, 1),
          respondedAt: DateTime.utc(2026, 1, 1, 0, 0, 2),
        ),
      );

      final mapped = AiResponseMapper.mapStreamEvent(event) as AiClientStreamCompleted;

      expect(mapped.conversationId, 'c1');
      expect(mapped.message.content, 'javob matni');
    });

    test('cancelled maps to AiClientStreamCancelled', () {
      const event = AiProtocolStreamEventCancelled(requestId: 'r1', conversationId: 'c1');

      expect(AiResponseMapper.mapStreamEvent(event), isA<AiClientStreamCancelled>());
    });

    test('failed maps to AiClientStreamFailed carrying the translated Failure', () {
      const event = AiProtocolStreamEventFailed(
        requestId: 'r1',
        conversationId: 'c1',
        error: AiProtocolError(
          code: AiProtocolErrorCode.network,
          message: 'x',
          retryable: true,
        ),
      );

      final mapped = AiResponseMapper.mapStreamEvent(event) as AiClientStreamFailed;

      expect(mapped.failure, const Failure.network());
    });
  });

  group('AiResponseMapper.mapProtocolError', () {
    test('every AiProtocolErrorCode maps to a Failure without throwing', () {
      for (final code in AiProtocolErrorCode.values) {
        final error = AiProtocolError(code: code, message: 'msg', retryable: false);

        expect(
          () => AiResponseMapper.mapProtocolError(error),
          returnsNormally,
          reason: 'code=$code kutilmagan istisno tashladi',
        );
      }
    });

    // `Failure` @freezed bo'lgani uchun haqiqiy runtime turi
    // (`_$NetworkFailureImpl` va h.k.) generatsiya qilingan, ochiq
    // (public) emas -- shuning uchun `is NetworkFailure` pattern-match
    // orqali tekshiriladi (sealed factory nomi bilan), `runtimeType`
    // bilan emas.
    final expectedMatcher = <AiProtocolErrorCode, Matcher>{
      AiProtocolErrorCode.network: isA<NetworkFailure>(),
      AiProtocolErrorCode.timeout: isA<NetworkFailure>(),
      AiProtocolErrorCode.rateLimited: isA<ServerFailure>(),
      AiProtocolErrorCode.providerError: isA<ServerFailure>(),
      AiProtocolErrorCode.providerNotConfigured: isA<ServerFailure>(),
      AiProtocolErrorCode.safetyRejected: isA<ValidationFailure>(),
      AiProtocolErrorCode.conversationNotFound: isA<ValidationFailure>(),
      AiProtocolErrorCode.conversationClosed: isA<ValidationFailure>(),
      AiProtocolErrorCode.invalidRequest: isA<ValidationFailure>(),
      AiProtocolErrorCode.unauthenticated: isA<PermissionDeniedFailure>(),
      AiProtocolErrorCode.unauthorized: isA<PermissionDeniedFailure>(),
      AiProtocolErrorCode.unknown: isA<UnknownFailure>(),
    };

    for (final entry in expectedMatcher.entries) {
      test('${entry.key} maps to the expected Failure variant', () {
        final error = AiProtocolError(code: entry.key, message: 'msg', retryable: false);

        final failure = AiResponseMapper.mapProtocolError(error);

        expect(failure, entry.value);
      });
    }

    test('expectedMatcher table covers every AiProtocolErrorCode value', () {
      expect(expectedMatcher.keys.toSet(), AiProtocolErrorCode.values.toSet());
    });
  });
}
