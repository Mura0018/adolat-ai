import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/ai_session_manager.dart';
import '../../ai_service/domain/entities/ai_message.dart';

void main() {
  group('AISessionManager', () {
    test('startConversation creates an empty conversation with a unique id', () {
      final manager = AISessionManager();

      final first = manager.startConversation();
      final second = manager.startConversation();

      expect(first.messages, isEmpty);
      expect(first.id, isNot(second.id));
    });

    test('getConversation returns null for an unknown id', () {
      final manager = AISessionManager();

      expect(manager.getConversation('unknown'), isNull);
    });

    test('appendMessage returns an updated conversation without mutating history', () {
      final manager = AISessionManager();
      final conversation = manager.startConversation();
      final message = AIMessage(
        id: 'm1',
        role: AIMessageRole.user,
        content: 'test',
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = manager.appendMessage(conversation.id, message);

      expect(updated.messages, [message]);
      expect(manager.getConversation(conversation.id)!.messages, [message]);
    });

    test('appendMessage throws for an unknown conversation', () {
      final manager = AISessionManager();
      final message = AIMessage(
        id: 'm1',
        role: AIMessageRole.user,
        content: 'test',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(
        () => manager.appendMessage('unknown', message),
        throwsA(isA<StateError>()),
      );
    });

    test('cancel triggers the cancellation token for that conversation', () {
      final manager = AISessionManager();
      final conversation = manager.startConversation();
      final token = manager.beginCancellableOperation(conversation.id);

      expect(token.isCancelled, isFalse);

      manager.cancel(conversation.id);

      expect(token.isCancelled, isTrue);
    });

    test('cancel is a no-op when no operation is active', () {
      final manager = AISessionManager();
      final conversation = manager.startConversation();

      expect(() => manager.cancel(conversation.id), returnsNormally);
    });
  });
}
