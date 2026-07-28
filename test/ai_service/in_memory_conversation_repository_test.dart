import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/in_memory_conversation_repository.dart';
import '../../ai_service/domain/entities/ai_conversation_status.dart';
import '../../ai_service/domain/entities/ai_message.dart';

void main() {
  group('InMemoryConversationRepository', () {
    test('create returns an empty, active conversation with a unique id', () {
      final repository = InMemoryConversationRepository();

      final first = repository.create();
      final second = repository.create();

      expect(first.messages, isEmpty);
      expect(first.status, AIConversationStatus.active);
      expect(first.id, isNot(second.id));
    });

    test('getById returns null for an unknown id', () {
      final repository = InMemoryConversationRepository();

      expect(repository.getById('unknown'), isNull);
    });

    test('appendMessage persists the update and returns it from getById', () {
      final repository = InMemoryConversationRepository();
      final conversation = repository.create();
      final message = AIMessage(
        id: 'm1',
        role: AIMessageRole.user,
        content: 'test',
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = repository.appendMessage(conversation.id, message);

      expect(updated.messages, [message]);
      expect(repository.getById(conversation.id)!.messages, [message]);
    });

    test('appendMessage throws for an unknown conversation', () {
      final repository = InMemoryConversationRepository();
      final message = AIMessage(
        id: 'm1',
        role: AIMessageRole.user,
        content: 'test',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(
        () => repository.appendMessage('unknown', message),
        throwsStateError,
      );
    });

    test('appendMessage throws once the conversation has been closed', () {
      final repository = InMemoryConversationRepository();
      final conversation = repository.create();
      repository.close(conversation.id);
      final message = AIMessage(
        id: 'm1',
        role: AIMessageRole.user,
        content: 'test',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(
        () => repository.appendMessage(conversation.id, message),
        throwsStateError,
      );
    });

    test('close persists the closed status', () {
      final repository = InMemoryConversationRepository();
      final conversation = repository.create();

      final closed = repository.close(conversation.id);

      expect(closed.isClosed, isTrue);
      expect(repository.getById(conversation.id)!.isClosed, isTrue);
    });

    test('close throws for an unknown conversation', () {
      final repository = InMemoryConversationRepository();

      expect(() => repository.close('unknown'), throwsStateError);
    });
  });
}
