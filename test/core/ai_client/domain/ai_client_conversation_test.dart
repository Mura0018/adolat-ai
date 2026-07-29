import 'package:adolat_ai/core/ai_client/domain/ai_client_conversation.dart';
import 'package:adolat_ai/core/ai_client/domain/ai_client_conversation_status.dart';
import 'package:adolat_ai/core/ai_client/domain/ai_client_message.dart';
import 'package:adolat_ai/core/ai_client/domain/ai_client_message_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiClientConversation', () {
    final base = AiClientConversation(
      id: 'c1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    test('appendMessage returns a new instance with the message added', () {
      final message = AiClientMessage(
        id: 'm1',
        role: AiClientMessageRole.user,
        content: 'Salom',
        createdAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
      );

      final updated = base.appendMessage(message);

      expect(updated.messages, [message]);
      expect(base.messages, isEmpty); // original o'zgarmagan (immutable)
    });

    test('close marks the conversation as closed', () {
      final closed = base.close(closedAt: DateTime.utc(2026, 1, 2));

      expect(closed.isClosed, isTrue);
      expect(closed.status, AiClientConversationStatus.closed);
      expect(base.isClosed, isFalse);
    });

    test('closing an already-closed conversation is idempotent', () {
      final closed = base.close(closedAt: DateTime.utc(2026, 1, 2));
      final closedAgain = closed.close(closedAt: DateTime.utc(2026, 1, 3));

      expect(closedAgain.updatedAt, closed.updatedAt);
    });
  });
}
