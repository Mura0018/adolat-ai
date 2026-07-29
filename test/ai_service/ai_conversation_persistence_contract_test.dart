import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/ai_conversation_persistence_contract.dart';
import '../../ai_service/domain/entities/ai_conversation_status.dart';
import '../../ai_service/domain/entities/ai_message.dart';

void main() {
  group('AIConversationRecord', () {
    test('allows an appeal-linked record', () {
      final record = AIConversationRecord(
        id: 'conv1',
        userId: 'user1',
        appealId: 'appeal1',
        status: AIConversationStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(record.appealId, 'appeal1');
      expect(record.disputeId, isNull);
    });

    test('allows a record with neither appealId nor disputeId (general conversation)', () {
      final record = AIConversationRecord(
        id: 'conv1',
        userId: 'user1',
        status: AIConversationStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(record.appealId, isNull);
      expect(record.disputeId, isNull);
    });

    test('rejects a record with both appealId and disputeId set', () {
      expect(
        () => AIConversationRecord(
          id: 'conv1',
          userId: 'user1',
          appealId: 'appeal1',
          disputeId: 'dispute1',
          status: AIConversationStatus.active,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('AIConversationMessageRecord', () {
    test('holds role/content/sequence', () {
      final record = AIConversationMessageRecord(
        id: 'msg1',
        conversationId: 'conv1',
        role: AIMessageRole.user,
        content: 'Nafaqa haqida savol',
        sequence: 0,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(record.role, AIMessageRole.user);
      expect(record.sequence, 0);
    });

    test('rejects a negative sequence', () {
      expect(
        () => AIConversationMessageRecord(
          id: 'msg1',
          conversationId: 'conv1',
          role: AIMessageRole.assistant,
          content: 'x',
          sequence: -1,
          createdAt: DateTime(2026, 1, 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
