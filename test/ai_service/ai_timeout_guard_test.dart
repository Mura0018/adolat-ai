import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/entities/ai_failure.dart';
import '../../ai_service/domain/entities/ai_stream_event.dart';
import '../../ai_service/gateway/timeout/ai_timeout_guard.dart';
import '../../ai_service/gateway/timeout/ai_timeout_policy.dart';

void main() {
  group('AITimeoutGuard', () {
    test('passes events through untouched when they arrive within the timeout', () async {
      const guard = AITimeoutGuard(AITimeoutPolicy(eventTimeout: Duration(milliseconds: 200)));
      final source = Stream<AIStreamEvent>.fromIterable(const [
        AIStreamEventChunk(deltaContent: 'a'),
        AIStreamEventChunk(deltaContent: 'b'),
      ]);

      final events = await guard.guard(source).toList();

      expect(events, hasLength(2));
      expect(events.every((e) => e is AIStreamEventChunk), isTrue);
    });

    test('emits AITimeoutFailure and closes when no event arrives within the timeout', () async {
      const guard = AITimeoutGuard(AITimeoutPolicy(eventTimeout: Duration(milliseconds: 50)));
      final source = Stream<AIStreamEvent>.periodic(
        const Duration(milliseconds: 200),
        (i) => const AIStreamEventChunk(deltaContent: 'late'),
      ).take(1);

      final events = await guard.guard(source).toList();

      expect(events, hasLength(1));
      expect(events.single, isA<AIStreamEventError>());
      expect((events.single as AIStreamEventError).failure, isA<AITimeoutFailure>());
    });
  });
}
