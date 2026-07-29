import 'package:adolat_ai/core/ai_client/ai_request_pipeline.dart';
import 'package:adolat_ai/core/ai_client/connectivity/ai_connectivity_monitor.dart';
import 'package:adolat_ai/core/ai_client/connectivity/ai_connectivity_status.dart';
import 'package:adolat_ai/core/ai_client/context/ai_client_context_assembler.dart';
import 'package:adolat_ai/core/ai_client/context/ai_client_safety_context.dart';
import 'package:adolat_ai/core/ai_client/context/ai_client_system_context.dart';
import 'package:adolat_ai/core/ai_client/context/ai_client_user_context.dart';
import 'package:adolat_ai/core/ai_client/domain/ai_client_conversation.dart';
import 'package:adolat_ai/core/ai_client/domain/ai_client_stream_event.dart';
import 'package:adolat_ai/core/ai_client/gateway/ai_gateway_client.dart';
import 'package:adolat_ai/core/ai_client/mock/mock_ai_gateway_client.dart';
import 'package:adolat_ai/core/ai_client/protocol/ai_protocol_stream_event.dart';
import 'package:adolat_ai/core/ai_client/protocol/ai_request_envelope.dart';
import 'package:adolat_ai/core/error/failure.dart';
import 'package:adolat_ai/features/auth/domain/entities/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingGatewayClient implements AiGatewayClient {
  AiRequestEnvelope? lastRequest;
  var callCount = 0;

  @override
  Stream<AiProtocolStreamEvent> sendMessage(AiRequestEnvelope request, {Object? credential}) {
    lastRequest = request;
    callCount += 1;
    return Stream.value(
      AiProtocolStreamEventStarted(requestId: request.requestId, conversationId: request.conversationId),
    );
  }
}

class _FixedConnectivityMonitor implements AiConnectivityMonitor {
  const _FixedConnectivityMonitor(this.currentStatus);

  @override
  final AiConnectivityStatus currentStatus;

  @override
  Stream<AiConnectivityStatus> get statusChanges => const Stream.empty();
}

void main() {
  final conversation = AiClientConversation(
    id: 'c1',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  const contextAssembler = AiClientContextAssembler(
    systemContext: AiClientSystemContext(locale: 'uz'),
    userContext: AiClientUserContext(role: UserRole.citizen, preferredLanguage: 'uz'),
    safetyContext: AiClientSafetyContext(),
  );

  group('AiRequestPipeline', () {
    test(
      'end-to-end with MockAiGatewayClient yields started -> chunks -> completed',
      () async {
        final pipeline = AiRequestPipeline(
          gatewayClient: const MockAiGatewayClient(responseText: 'salom dunyo', wordsPerChunk: 1),
        );

        final events = await pipeline
            .sendMessage(
              conversation: conversation,
              userId: 'u1',
              userMessageContent: 'Salom',
              contextAssembler: contextAssembler,
            )
            .toList();

        expect(events.first, isA<AiClientStreamStarted>());
        expect(events.whereType<AiClientStreamChunk>(), isNotEmpty);
        final completed = events.whereType<AiClientStreamCompleted>().single;
        expect(completed.message.content, 'salom dunyo');
      },
    );

    test('assembled context and user message reach the gateway client request', () async {
      final recording = _RecordingGatewayClient();
      final pipeline = AiRequestPipeline(gatewayClient: recording);

      await pipeline
          .sendMessage(
            conversation: conversation,
            userId: 'u1',
            userMessageContent: 'Mening savolim',
            contextAssembler: contextAssembler,
          )
          .toList();

      expect(recording.lastRequest, isNotNull);
      expect(recording.lastRequest!.conversationId, 'c1');
      expect(recording.lastRequest!.userId, 'u1');
      expect(recording.lastRequest!.message, 'Mening savolim');
      expect(recording.lastRequest!.context.keys, containsAll(['system', 'user', 'safety']));
    });

    test('offline connectivity short-circuits to a network Failure without calling the gateway', () async {
      final recording = _RecordingGatewayClient();
      final pipeline = AiRequestPipeline(
        gatewayClient: recording,
        connectivityMonitor: const _FixedConnectivityMonitor(AiConnectivityStatus.offline),
      );

      final events = await pipeline
          .sendMessage(
            conversation: conversation,
            userId: 'u1',
            userMessageContent: 'Salom',
            contextAssembler: contextAssembler,
          )
          .toList();

      expect(recording.callCount, 0);
      final failed = events.single as AiClientStreamFailed;
      expect(failed.failure, const Failure.network());
    });

    test('online connectivity does not block the request', () async {
      final recording = _RecordingGatewayClient();
      final pipeline = AiRequestPipeline(
        gatewayClient: recording,
        connectivityMonitor: const _FixedConnectivityMonitor(AiConnectivityStatus.online),
      );

      await pipeline
          .sendMessage(
            conversation: conversation,
            userId: 'u1',
            userMessageContent: 'Salom',
            contextAssembler: contextAssembler,
          )
          .toList();

      expect(recording.callCount, 1);
    });
  });
}
