import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/providers/ai_provider_adapter.dart';
import '../../ai_service/data/repositories/ai_repository_impl.dart';
import '../../ai_service/domain/entities/ai_cancellation_token.dart';
import '../../ai_service/domain/entities/ai_context.dart';
import '../../ai_service/domain/entities/ai_conversation.dart';
import '../../ai_service/domain/entities/ai_provider_id.dart';
import '../../ai_service/domain/entities/ai_request.dart';
import '../../ai_service/domain/entities/ai_response.dart';
import '../../ai_service/domain/entities/ai_stream_event.dart';
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

class _AlwaysUnsafe implements AISafetyService {
  @override
  Future<AISafetyCheckResult> validateRequest(AIRequest request) async =>
      const AISafetyCheckResult(isSafe: false, reason: 'blocked in test');

  @override
  Future<AISafetyCheckResult> validateResponse(AIResponse response) async =>
      const AISafetyCheckResult(isSafe: true);
}

class _FakeProviderAdapter implements AIProviderAdapter {
  _FakeProviderAdapter(this.providerId);

  @override
  final AIProviderId providerId;

  bool wasCalled = false;

  @override
  Stream<AIStreamEvent> streamCompletion({
    required AIRequest request,
    AICancellationToken? cancellationToken,
  }) async* {
    wasCalled = true;
    yield AIStreamEventDone(
      response: AIResponse(
        id: 'r1',
        conversationId: request.conversationId,
        content: 'fake response',
        providerId: providerId,
        modelVersion: 'fake-v1',
        completedAt: DateTime(2026, 1, 1),
      ),
    );
  }
}

AIConversation _conversation() {
  final now = DateTime(2026, 1, 1);
  return AIConversation(id: 'c1', messages: const [], createdAt: now, updatedAt: now);
}

void main() {
  group('AIRepositoryImpl', () {
    test('delegates to the adapter registered for the requested provider', () async {
      final adapter = _FakeProviderAdapter(AIProviderId.openAI);
      final repository = AIRepositoryImpl(
        providers: {AIProviderId.openAI: adapter},
        safetyService: _AlwaysSafe(),
      );

      final events = await repository
          .sendMessage(
            conversation: _conversation(),
            context: const AIContext(sections: {}),
            providerId: AIProviderId.openAI,
          )
          .toList();

      expect(adapter.wasCalled, isTrue);
      expect(events, hasLength(1));
      expect(events.single, isA<AIStreamEventDone>());
    });

    test('errors without calling any adapter when the provider is not registered', () async {
      final adapter = _FakeProviderAdapter(AIProviderId.openAI);
      final repository = AIRepositoryImpl(
        providers: {AIProviderId.openAI: adapter},
        safetyService: _AlwaysSafe(),
      );

      final events = await repository
          .sendMessage(
            conversation: _conversation(),
            context: const AIContext(sections: {}),
            providerId: AIProviderId.gemini,
          )
          .toList();

      expect(adapter.wasCalled, isFalse);
      expect(events, hasLength(1));
      expect(events.single, isA<AIStreamEventError>());
    });

    test('errors without calling the adapter when the safety check fails', () async {
      final adapter = _FakeProviderAdapter(AIProviderId.openAI);
      final repository = AIRepositoryImpl(
        providers: {AIProviderId.openAI: adapter},
        safetyService: _AlwaysUnsafe(),
      );

      final events = await repository
          .sendMessage(
            conversation: _conversation(),
            context: const AIContext(sections: {}),
            providerId: AIProviderId.openAI,
          )
          .toList();

      expect(adapter.wasCalled, isFalse);
      expect(events.single, isA<AIStreamEventError>());
      expect(
        (events.single as AIStreamEventError).message,
        'blocked in test',
      );
    });

    test('short-circuits to cancelled when the token is already cancelled', () async {
      final adapter = _FakeProviderAdapter(AIProviderId.openAI);
      final repository = AIRepositoryImpl(
        providers: {AIProviderId.openAI: adapter},
        safetyService: _AlwaysSafe(),
      );
      final token = AICancellationToken()..cancel();

      final events = await repository
          .sendMessage(
            conversation: _conversation(),
            context: const AIContext(sections: {}),
            providerId: AIProviderId.openAI,
            cancellationToken: token,
          )
          .toList();

      expect(adapter.wasCalled, isFalse);
      expect(events.single, isA<AIStreamEventCancelled>());
    });
  });
}
