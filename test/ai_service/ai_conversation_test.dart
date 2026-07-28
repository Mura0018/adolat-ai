import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/entities/ai_conversation.dart';
import '../../ai_service/domain/entities/ai_message.dart';

void main() {
  group('AIConversation.appendMessage', () {
    test('returns a new immutable instance, original is unchanged', () {
      final now = DateTime(2026, 1, 1);
      final conversation = AIConversation(
        id: 'c1',
        messages: const [],
        createdAt: now,
        updatedAt: now,
      );
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
  });
}
