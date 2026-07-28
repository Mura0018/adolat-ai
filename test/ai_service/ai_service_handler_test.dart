import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/in_memory_cancellation_registry.dart';
import '../../ai_service/data/session/in_memory_conversation_repository.dart';
import '../../ai_service/domain/entities/ai_cancellation_token.dart';
import '../../ai_service/domain/entities/ai_context.dart';
import '../../ai_service/domain/entities/ai_conversation.dart';
import '../../ai_service/domain/entities/ai_provider_id.dart';
import '../../ai_service/domain/entities/ai_response.dart';
import '../../ai_service/domain/entities/ai_stream_event.dart';
import '../../ai_service/domain/repositories/ai_repository.dart';
import '../../ai_service/domain/usecases/cancel_conversation_usecase.dart';
import '../../ai_service/domain/usecases/close_conversation_usecase.dart';
import '../../ai_service/domain/usecases/send_conversation_message_usecase.dart';
import '../../ai_service/domain/usecases/start_conversation_usecase.dart';
import '../../ai_service/presentation/ai_service_handler.dart';

/// `AIServiceHandler` Phase 2C'dan beri faqat delegatsiya qiladi --
/// suhbat tarixi/qayta urinish semantikasi endi
/// `send_conversation_message_usecase_test.dart`da sinaladi. Bu yerda
/// faqat "har bir metod to'g'ri usecase'ni chaqiradimi va natijani
/// o'zgartirmasdan qaytaradimi" tekshiriladi.
class _ScriptedAIRepository implements AIRepository {
  _ScriptedAIRepository(this.events);

  final List<AIStreamEvent> events;

  @override
  Stream<AIStreamEvent> sendMessage({
    required AIConversation conversation,
    required AIContext context,
    required AIProviderId providerId,
    AICancellationToken? cancellationToken,
  }) async* {
    for (final event in events) {
      yield event;
    }
  }
}

AIServiceHandler _buildHandler({
  required InMemoryConversationRepository conversationRepository,
  required InMemoryCancellationRegistry cancellationRegistry,
  required _ScriptedAIRepository repository,
}) {
  return AIServiceHandler(
    startConversationUseCase: StartConversationUseCase(conversationRepository),
    sendConversationMessageUseCase: SendConversationMessageUseCase(
      repository: repository,
      conversationRepository: conversationRepository,
      cancellationRegistry: cancellationRegistry,
    ),
    cancelConversationUseCase: CancelConversationUseCase(cancellationRegistry),
    closeConversationUseCase: CloseConversationUseCase(conversationRepository),
  );
}

void main() {
  group('AIServiceHandler delegation', () {
    test('startConversation delegates to StartConversationUseCase', () {
      final conversationRepository = InMemoryConversationRepository();
      final handler = _buildHandler(
        conversationRepository: conversationRepository,
        cancellationRegistry: InMemoryCancellationRegistry(),
        repository: _ScriptedAIRepository([]),
      );

      final id = handler.startConversation();

      expect(conversationRepository.getById(id), isNotNull);
    });

    test('handleRequest delegates to SendConversationMessageUseCase and passes events through', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final handler = _buildHandler(
        conversationRepository: conversationRepository,
        cancellationRegistry: InMemoryCancellationRegistry(),
        repository: _ScriptedAIRepository([
          AIStreamEventDone(
            response: AIResponse(
              id: 'r1',
              conversationId: conversation.id,
              content: 'reply',
              providerId: AIProviderId.openAI,
              modelVersion: 'fake-v1',
              completedAt: DateTime(2026, 1, 1),
            ),
          ),
        ]),
      );

      final events = await handler
          .handleRequest(
            conversationId: conversation.id,
            userMessageContent: 'hi',
            context: const AIContext(sections: {}),
            providerId: AIProviderId.openAI,
          )
          .toList();

      expect(events.single, isA<AIStreamEventDone>());
    });

    test('cancelRequest delegates to CancelConversationUseCase', () {
      final cancellationRegistry = InMemoryCancellationRegistry();
      final handler = _buildHandler(
        conversationRepository: InMemoryConversationRepository(),
        cancellationRegistry: cancellationRegistry,
        repository: _ScriptedAIRepository([]),
      );
      final token = cancellationRegistry.register('c1');

      handler.cancelRequest('c1');

      expect(token.isCancelled, isTrue);
    });

    test('closeConversation delegates to CloseConversationUseCase', () {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final handler = _buildHandler(
        conversationRepository: conversationRepository,
        cancellationRegistry: InMemoryCancellationRegistry(),
        repository: _ScriptedAIRepository([]),
      );

      final closed = handler.closeConversation(conversation.id);

      expect(closed.isClosed, isTrue);
    });
  });
}
