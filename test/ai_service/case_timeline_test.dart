import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/case/case_timeline.dart';

void main() {
  group('CaseTimeline', () {
    test('starts empty, latest is null', () {
      const timeline = CaseTimeline();

      expect(timeline.events, isEmpty);
      expect(timeline.latest, isNull);
    });

    test('appendEvent returns a new instance, original is unchanged', () {
      const timeline = CaseTimeline();
      final event = CaseTimelineEvent(
        id: 'evt1',
        type: CaseTimelineEventType.caseCreated,
        description: 'Ish yaratildi',
        occurredAt: DateTime(2026, 1, 1),
      );

      final updated = timeline.appendEvent(event);

      expect(timeline.events, isEmpty);
      expect(updated.events, [event]);
      expect(updated.latest, event);
    });

    test('equality compares events element-wise', () {
      final event = CaseTimelineEvent(
        id: 'evt1',
        type: CaseTimelineEventType.note,
        description: 'x',
        occurredAt: DateTime(2026, 1, 1),
      );
      final a = const CaseTimeline().appendEvent(event);
      final b = const CaseTimeline().appendEvent(event);

      expect(a, b);
    });
  });
}
