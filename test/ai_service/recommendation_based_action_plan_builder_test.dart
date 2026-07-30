import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/workflow/action_plan/action_plan_step.dart';
import '../../ai_service/domain/workflow/action_plan/recommendation_based_action_plan_builder.dart';
import '../../ai_service/domain/workflow/next_step_kind.dart';
import '../../ai_service/domain/workflow/recommendation/recommendation.dart';

void main() {
  const builder = RecommendationBasedActionPlanBuilder();

  group('RecommendationBasedActionPlanBuilder', () {
    test('turns recommendations into steps ordered by Recommendation.order', () {
      final plan = builder.build(
        caseId: 'case1',
        recommendations: const [
          Recommendation(
            id: 'second',
            kind: NextStepKind.reviewCollectedInformation,
            message: 'Ikkinchi',
            order: 5,
          ),
          Recommendation(
            id: 'first',
            kind: NextStepKind.collectInformation,
            message: 'Birinchi',
            order: 2,
          ),
        ],
      );

      expect(plan.steps.map((s) => s.title), ['Birinchi', 'Ikkinchi']);
    });

    test('renumbers steps to a contiguous 1..n sequence even with gaps in order', () {
      final plan = builder.build(
        caseId: 'case1',
        recommendations: const [
          Recommendation(
            id: 'a',
            kind: NextStepKind.collectInformation,
            message: 'A',
            order: 3,
          ),
          Recommendation(
            id: 'b',
            kind: NextStepKind.collectInformation,
            message: 'B',
            order: 99,
          ),
        ],
      );

      expect(plan.steps.map((s) => s.order), [1, 2]);
    });

    test('keeps the original sequence for recommendations sharing an order (stable sort)', () {
      final plan = builder.build(
        caseId: 'case1',
        recommendations: const [
          Recommendation(
            id: 'x',
            kind: NextStepKind.collectInformation,
            message: 'X',
            order: 1,
          ),
          Recommendation(
            id: 'y',
            kind: NextStepKind.collectInformation,
            message: 'Y',
            order: 1,
          ),
        ],
      );

      expect(plan.steps.map((s) => s.title), ['X', 'Y']);
    });

    test('carries kind, message and requirementId through to the step', () {
      final plan = builder.build(
        caseId: 'case1',
        recommendations: const [
          Recommendation(
            id: 'collect_complaint_target',
            kind: NextStepKind.collectInformation,
            message: 'Shikoyat kimga qarshi?',
            order: 1,
            requirementId: 'complaint_target',
          ),
        ],
      );

      final step = plan.steps.single;
      expect(step.kind, NextStepKind.collectInformation);
      expect(step.title, 'Shikoyat kimga qarshi?');
      expect(step.requirementId, 'complaint_target');
      expect(step.status, ActionPlanStepStatus.pending);
      expect(step.id, 'plan_collect_complaint_target');
    });

    test('produces no content of its own -- every title comes from a recommendation', () {
      const messages = ['A', 'B'];
      final plan = builder.build(
        caseId: 'case1',
        recommendations: const [
          Recommendation(id: 'a', kind: NextStepKind.collectInformation, message: 'A', order: 1),
          Recommendation(
            id: 'b',
            kind: NextStepKind.consultHumanSpecialist,
            message: 'B',
            order: 2,
          ),
        ],
      );

      expect(plan.steps.map((s) => s.title), messages);
    });

    test('an empty recommendation list yields an empty plan', () {
      final plan = builder.build(caseId: 'case1', recommendations: const []);

      expect(plan.isEmpty, isTrue);
      expect(plan.caseId, 'case1');
    });
  });
}
