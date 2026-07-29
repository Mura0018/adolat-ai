import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/intake/mock_case_intake_assistant.dart';
import '../../ai_service/domain/case/case_category.dart';

void main() {
  group('MockCaseIntakeAssistant', () {
    test('returns a non-empty, deterministic question list for every category', () async {
      const assistant = MockCaseIntakeAssistant();

      for (final category in CaseCategory.values) {
        final first = await assistant.generateClarificationQuestions(
          problemDescription: 'har qanday matn',
          category: category,
        );
        final second = await assistant.generateClarificationQuestions(
          problemDescription: 'butunlay boshqa matn',
          category: category,
        );

        expect(first, isNotEmpty);
        expect(first, second); // deterministik -- matnga bog'liq emas
      }
    });

    test('question ids are unique within a category', () async {
      const assistant = MockCaseIntakeAssistant();

      final questions = await assistant.generateClarificationQuestions(
        problemDescription: 'x',
        category: CaseCategory.complaint,
      );

      expect(questions.map((q) => q.id).toSet(), hasLength(questions.length));
    });
  });
}
