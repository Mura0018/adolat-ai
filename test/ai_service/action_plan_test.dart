import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/workflow/action_plan/action_plan.dart';
import '../../ai_service/domain/workflow/action_plan/action_plan_step.dart';
import '../../ai_service/domain/workflow/next_step_kind.dart';
import '../../ai_service/domain/workflow/workflow_exceptions.dart';

ActionPlanStep _step(int order, {ActionPlanStepStatus status = ActionPlanStepStatus.pending}) {
  return ActionPlanStep(
    id: 'step_$order',
    order: order,
    kind: NextStepKind.collectInformation,
    title: '$order-qadam',
    status: status,
  );
}

void main() {
  group('ActionPlan order invariant', () {
    test('accepts steps numbered 1..n', () {
      final plan = ActionPlan(caseId: 'case1', steps: [_step(1), _step(2), _step(3)]);

      expect(plan.stepCount, 3);
    });

    test('rejects a plan that does not start at 1', () {
      expect(
        () => ActionPlan(caseId: 'case1', steps: [_step(2), _step(3)]),
        throwsA(isA<InvalidActionPlanOrderException>()),
      );
    });

    test('rejects a gap in the ordering', () {
      expect(
        () => ActionPlan(caseId: 'case1', steps: [_step(1), _step(3)]),
        throwsA(isA<InvalidActionPlanOrderException>()),
      );
    });

    test('rejects duplicated order values', () {
      expect(
        () => ActionPlan(caseId: 'case1', steps: [_step(1), _step(1)]),
        throwsA(isA<InvalidActionPlanOrderException>()),
      );
    });

    test('rejects steps supplied out of order', () {
      expect(
        () => ActionPlan(caseId: 'case1', steps: [_step(2), _step(1)]),
        throwsA(isA<InvalidActionPlanOrderException>()),
      );
    });
  });

  group('ActionPlan.nextStep', () {
    test('is the first step that is not done', () {
      final plan = ActionPlan(
        caseId: 'case1',
        steps: [
          _step(1, status: ActionPlanStepStatus.done),
          _step(2, status: ActionPlanStepStatus.inProgress),
          _step(3),
        ],
      );

      expect(plan.nextStep?.order, 2);
      expect(plan.completedStepCount, 1);
    });

    test('is null when every step is done', () {
      final plan = ActionPlan(
        caseId: 'case1',
        steps: [
          _step(1, status: ActionPlanStepStatus.done),
          _step(2, status: ActionPlanStepStatus.done),
        ],
      );

      expect(plan.nextStep, isNull);
      expect(plan.completedStepCount, 2);
    });
  });

  group('ActionPlan.empty', () {
    test('is a valid, empty plan -- not an error state', () {
      final plan = ActionPlan.empty('case1');

      expect(plan.isEmpty, isTrue);
      expect(plan.stepCount, 0);
      expect(plan.nextStep, isNull);
      expect(plan.caseId, 'case1');
    });
  });

  group('ActionPlanStep.withStatus', () {
    test('returns a new step and leaves the original untouched', () {
      final original = _step(1);

      final updated = original.withStatus(ActionPlanStepStatus.done);

      expect(original.status, ActionPlanStepStatus.pending);
      expect(updated.status, ActionPlanStepStatus.done);
      expect(updated.id, original.id);
      expect(updated.order, original.order);
    });
  });
}
