import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/in_memory_conversation_repository.dart';
import '../../ai_service/di/ai_service_locator.dart';
import '../../ai_service/domain/entities/ai_provider_id.dart';
import '../../ai_service/domain/entities/ai_request.dart';
import '../../ai_service/domain/entities/ai_response.dart';
import '../../ai_service/gateway/auth/ai_auth_context.dart';
import '../../ai_service/protocol/ai_protocol_error.dart';
import '../../ai_service/protocol/ai_protocol_stream_event.dart';
import '../../ai_service/protocol/ai_request_envelope.dart';
import '../../ai_service/safety/ai_safety_check_result.dart';
import '../../ai_service/safety/ai_safety_service.dart';

class _AlwaysSafe implements AISafetyService {
  @override
  Future<AISafetyCheckResult> validateRequest(AIRequest request) async =>
      const AISafetyCheckResult(isSafe: true);

  @override
  Future<AISafetyCheckResult> validateResponse(AIResponse response) async =>
      const AISafetyCheckResult(isSafe: true);
}

void main() {
  group('AIServiceLocator.build -- Phase 4C pluggable composition root', () {
    test('uses the injected conversationRepository instead of a fresh in-memory one', () {
      final customRepository = InMemoryConversationRepository();
      final handler = AIServiceLocator.build(
        providerCredentials: const {},
        safetyService: _AlwaysSafe(),
        conversationRepository: customRepository,
      );

      final conversationId = handler.startConversation();

      expect(customRepository.getById(conversationId), isNotNull);
    });

    test('falls back to an in-memory conversationRepository when none is injected', () {
      final handler = AIServiceLocator.build(
        providerCredentials: const {},
        safetyService: _AlwaysSafe(),
      );

      expect(handler.startConversation(), isNotEmpty);
    });
  });

  group('AIServiceLocator.buildGateway -- Phase 4C pluggable composition root', () {
    test('uses the injected conversationRepository -- request reaches provider selection, not conversationNotFound', () async {
      final customRepository = InMemoryConversationRepository();
      final conversation = customRepository.create();

      final gateway = AIServiceLocator.buildGateway(
        providerCredentials: const {},
        safetyService: _AlwaysSafe(),
        selectProvider: (_) => AIProviderId.openAI,
        conversationRepository: customRepository,
      );

      final events = await gateway
          .handle(
            request: AIRequestEnvelope(
              requestId: 'req1',
              conversationId: conversation.id,
              userId: 'user1',
              message: 'hi',
              requestedAt: DateTime(2026, 1, 1),
            ),
            auth: const AIAuthContext(isAuthenticated: true, userId: 'user1'),
          )
          .toList();

      final failed = events.whereType<AIProtocolStreamEventFailed>().single;
      // providerCredentials is empty, so openAI has no adapter configured --
      // this (not conversationNotFound) proves the conversation was found
      // via the INJECTED repository before reaching provider dispatch.
      expect(failed.error.code, AIProtocolErrorCode.providerNotConfigured);
    });
  });
}
