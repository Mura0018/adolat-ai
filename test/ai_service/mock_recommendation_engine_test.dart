import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/workflow/mock_recommendation_engine.dart';
import '../../ai_service/domain/case/case_category.dart';
import '../../ai_service/domain/case/case_status.dart';
import '../../ai_service/domain/workflow/completeness/information_completeness.dart';
import '../../ai_service/domain/workflow/information_requirement.dart';
import '../../ai_service/domain/workflow/next_step_kind.dart';
import '../../ai_service/domain/workflow/recommendation/recommendation_context.dart';

const _mandatory = InformationRequirement(id: 'a', question: 'A?');
const _optional = InformationRequirement(
  id: 'b',
  question: 'B?',
  importance: InformationImportance.optional,
);

RecommendationContext _context({
  required InformationCompleteness completeness,
  CaseCategory category = CaseCategory.complaint,
  CaseStatus status = CaseStatus.informationGathering,
}) {
  return RecommendationContext(
    category: category,
    status: status,
    completeness: completeness,
  );
}

void main() {
  const engine = MockRecommendationEngine();

  group('MockRecommendationEngine with missing mandatory information', () {
    test('recommends collecting each missing requirement, mandatory first', () async {
      final result = await engine.recommend(
        _context(
          completeness: const InformationCompleteness(
            satisfied: [],
            missing: [_optional, _mandatory],
          ),
        ),
      );

      expect(result.map((r) => r.requirementId), ['a', 'b']);
      expect(result.every((r) => r.kind == NextStepKind.collectInformation), isTrue);
      expect(result.map((r) => r.order), [1, 2]);
    });

    test('uses the requirement question as the recommendation message', () async {
      final result = await engine.recommend(
        _context(
          completeness: const InformationCompleteness(satisfied: [], missing: [_mandatory]),
        ),
      );

      expect(result.single.message, 'A?');
    });

    test('does not suggest review or next-stage steps yet -- no dead end, but no skipping', () async {
      final result = await engine.recommend(
        _context(
          completeness: const InformationCompleteness(satisfied: [], missing: [_mandatory]),
        ),
      );

      expect(
        result.any((r) => r.kind == NextStepKind.reviewCollectedInformation),
        isFalse,
      );
      expect(result.any((r) => r.kind == NextStepKind.consultHumanSpecialist), isFalse);
    });
  });

  group('MockRecommendationEngine when mandatory information is complete', () {
    test('recommends review and then a human specialist for non-document categories', () async {
      final result = await engine.recommend(
        _context(
          completeness: const InformationCompleteness(satisfied: [_mandatory], missing: []),
        ),
      );

      expect(result.map((r) => r.kind), [
        NextStepKind.reviewCollectedInformation,
        NextStepKind.consultHumanSpecialist,
      ]);
      expect(result.map((r) => r.order), [1, 2]);
    });

    test('recommends the document stage only as preparation for documentGeneration', () async {
      final result = await engine.recommend(
        _context(
          category: CaseCategory.documentGeneration,
          completeness: const InformationCompleteness(satisfied: [_mandatory], missing: []),
        ),
      );

      expect(result.last.kind, NextStepKind.prepareDocumentLater);
      // Hech qanday hujjat matni/shabloni qaytarilmaydi -- faqat
      // keyingi bosqichga ishora (talab: "No document generation").
      expect(result.last.message.contains('tayyorlanmaydi'), isTrue);
    });

    test('still asks the remaining optional questions before the review step', () async {
      final result = await engine.recommend(
        _context(
          completeness: const InformationCompleteness(
            satisfied: [_mandatory],
            missing: [_optional],
          ),
        ),
      );

      expect(result.map((r) => r.kind), [
        NextStepKind.collectInformation,
        NextStepKind.reviewCollectedInformation,
        NextStepKind.consultHumanSpecialist,
      ]);
    });
  });

  group('MockRecommendationEngine terminal cases', () {
    test('recommends nothing for a completed or archived case', () async {
      for (final status in [CaseStatus.completed, CaseStatus.archived]) {
        final result = await engine.recommend(
          _context(
            status: status,
            completeness: const InformationCompleteness(satisfied: [], missing: [_mandatory]),
          ),
        );

        expect(result, isEmpty, reason: '${status.name} uchun tavsiya berilmasligi kerak');
      }
    });
  });

  group('MockRecommendationEngine guarantees', () {
    test('is deterministic -- identical context yields an identical result', () async {
      final context = _context(
        completeness: const InformationCompleteness(satisfied: [], missing: [_mandatory]),
      );

      expect(await engine.recommend(context), await engine.recommend(context));
    });

    test('never ends the flow with a legal conclusion -- last step hands off or waits', () async {
      for (final category in CaseCategory.values) {
        final result = await engine.recommend(
          _context(
            category: category,
            completeness: const InformationCompleteness(satisfied: [_mandatory], missing: []),
          ),
        );

        expect(
          result.last.kind,
          anyOf(NextStepKind.consultHumanSpecialist, NextStepKind.prepareDocumentLater),
          reason: '${category.name}: oqim huquqiy xulosa bilan yakunlanmasligi kerak',
        );
      }
    });
  });
}
