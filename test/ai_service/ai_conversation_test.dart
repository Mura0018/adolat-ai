import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/entities/ai_conversation.dart';
import '../../ai_service/domain/entities/ai_conversation_status.dart';
import '../../ai_service/domain/entities/ai_message.dart';
import '../../ai_service/domain/repositories/conversation_exceptions.dart';

AIConversation _conversation({AIConversationStatus status = AIConversationStatus.active}) {
  final now = DateTime(2026, 1, 1);
  return AIConversation(
    id: 'c1',
    messages: const [],
    createdAt: now,
    updatedAt: now,
    status: status,
  );
}

void main() {
  group('AIConversation.appendMessage', () {
    test('returns a new immutable instance, original is unchanged', () {
      final conversation = _conversation();
      final message = AIMessage(
        id: 'm1',
        role: AIMessageRole.user,
        content: 'hello',
        createdAt: DateTime(2026, 1, 2),
      );

      final updated = conversation.appendMessage(message);

      expect(conversation.messages, isEmpty);
      expect(updated.messages, [message]);
      expect(updated.updatedAt, message.createdAt);
    });

    test('throws ConversationClosedException when the conversation is closed', () {
      final closed = _conversation(status: AIConversationStatus.closed);
      final message = AIMessage(
        id: 'm1',
        role: AIMessageRole.user,
        content: 'hello',
        createdAt: DateTime(2026, 1, 2),
      );

      expect(
        () => closed.appendMessage(message),
        throwsA(isA<ConversationClosedException>()),
      );
    });
  });

  group('AIConversation.close', () {
    test('marks the conversation closed and updates updatedAt', () {
      final conversation = _conversation();
      final closedAt = DateTime(2026, 1, 3);

      final closed = conversation.close(closedAt: closedAt);

      expect(closed.isClosed, isTrue);
      expect(closed.status, AIConversationStatus.closed);
      expect(closed.updatedAt, closedAt);
      expect(conversation.isClosed, isFalse); // original unchanged
    });

    test('is idempotent -- closing an already-closed conversation is a no-op', () {
      final closed = _conversation(status: AIConversationStatus.closed);

      final result = closed.close(closedAt: DateTime(2026, 1, 5));

      expect(result.updatedAt, closed.updatedAt); // NOT overwritten
    });
  });
}
