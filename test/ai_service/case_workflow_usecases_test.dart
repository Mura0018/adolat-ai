import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/in_memory_case_repository.dart';
import '../../ai_service/data/session/in_memory_conversation_repository.dart';
import '../../ai_service/data/workflow/mock_recommendation_engine.dart';
import '../../ai_service/data/workflow/static_information_requirement_catalog.dart';
import '../../ai_service/domain/case/case.dart';
import '../../ai_service/domain/case/case_category.dart';
import '../../ai_service/domain/case/case_exceptions.dart';
import '../../ai_service/domain/case/case_status.dart';
import '../../ai_service/domain/usecases/build_case_action_plan_usecase.dart';
import '../../ai_service/domain/usecases/evaluate_case_completeness_usecase.dart';
import '../../ai_service/domain/usecases/get_case_progress_usecase.dart';
import '../../ai_service/domain/usecases/get_case_usecase.dart';
import '../../ai_service/domain/usecases/next_clarification_question_usecase.dart';
import '../../ai_service/domain/usecases/record_case_answer_usecase.dart';
import '../../ai_service/domain/usecases/record_case_information_usecase.dart';
import '../../ai_service/domain/workflow/action_plan/recommendation_based_action_plan_builder.dart';
import '../../ai_service/domain/workflow/clarification/clarification_workflow.dart';
import '../../ai_service/domain/workflow/completeness/requirement_checklist_evaluator.dart';
import '../../ai_service/domain/workflow/next_step_kind.dart';

/// Butun Phase 5C zanjiri bitta, haqiqiy (in-memory) tayanchlar bilan
/// yig'ilgan holda -- usecase'lar bir-biri bilan qanday ishlashini
/// tekshiradi.
class _Fixture {
  _Fixture({CaseCategory category = CaseCategory.complaint}) {
    final caseRepository = InMemoryCaseRepository();
    final conversationRepository = InMemoryConversationRepository();
    const catalog = StaticInformationRequirementCatalog();
    const evaluator = RequirementChecklistEvaluator(catalog);
    final getCase = GetCaseUseCase(caseRepository);

    case_ = caseRepository.create(
      userId: 'user1',
      category: category,
      problemSummary: 'muammo',
      conversationId: conversationRepository.create().id,
    );

    this.caseRepository = caseRepository;
    record = RecordCaseInformationUseCase(
      caseRepository: caseRepository,
      getCase: getCase,
      recordAnswer: RecordCaseAnswerUseCase(
        caseRepository: caseRepository,
        conversationRepository: conversationRepository,
      ),
      catalog: catalog,
    );
    evaluate = EvaluateCaseCompletenessUseCase(getCase: getCase, evaluator: evaluator);
    nextQuestion = NextClarificationQuestionUseCase(
      getCase: getCase,
      workflow: const ClarificationWorkflow(evaluator),
    );
    buildPlan = BuildCaseActionPlanUseCase(
      getCase: getCase,
      evaluator: evaluator,
      recommendationEngine: const MockRecommendationEngine(),
      actionPlanBuilder: const RecommendationBasedActionPlanBuilder(),
    );
    progress = GetCaseProgressUseCase(getCase: getCase, evaluator: evaluator);
    mandatoryIds = catalog
        .requirementsFor(category)
        .where((r) => r.isMandatory)
        .map((r) => r.id)
        .toList();
  }

  late final InMemoryCaseRepository caseRepository;
  late final Case case_;
  late final RecordCaseInformationUseCase record;
  late final EvaluateCaseCompletenessUseCase evaluate;
  late final NextClarificationQuestionUseCase nextQuestion;
  late final BuildCaseActionPlanUseCase buildPlan;
  late final GetCaseProgressUseCase progress;
  late final List<String> mandatoryIds;

  /// Barcha majburiy bo'laklarni to'ldiradi.
  void answerAllMandatory() {
    for (final id in mandatoryIds) {
      record(
        caseId: case_.id,
        requestingUserId: 'user1',
        requirementId: id,
        value: 'javob',
      );
    }
  }
}

void main() {
  group('EvaluateCaseCompletenessUseCase', () {
    test('a brand new case is not sufficient and everything is missing', () {
      final fixture = _Fixture();

      final result = fixture.evaluate(caseId: fixture.case_.id, requestingUserId: 'user1');

      expect(result.isSufficient, isFalse);
      expect(result.satisfied, isEmpty);
      expect(result.missing, isNotEmpty);
    });

    test('becomes sufficient once every mandatory requirement is answered', () {
      final fixture = _Fixture()..answerAllMandatory();

      final result = fixture.evaluate(caseId: fixture.case_.id, requestingUserId: 'user1');

      expect(result.isSufficient, isTrue);
      expect(result.missingMandatory, isEmpty);
    });

    test('does not advance the case status by itself', () {
      final fixture = _Fixture()..answerAllMandatory();

      fixture.evaluate(caseId: fixture.case_.id, requestingUserId: 'user1');

      expect(fixture.caseRepository.getById(fixture.case_.id)!.status, CaseStatus.created);
    });

    test('enforces case ownership', () {
      final fixture = _Fixture();

      expect(
        () => fixture.evaluate(caseId: fixture.case_.id, requestingUserId: 'boshqa'),
        throwsA(isA<CaseAccessDeniedException>()),
      );
    });
  });

  group('NextClarificationQuestionUseCase', () {
    test('asks the first mandatory question of a new case', () {
      final fixture = _Fixture();

      final step = fixture.nextQuestion(caseId: fixture.case_.id, requestingUserId: 'user1');

      expect(step, isNotNull);
      expect(step!.requirement.id, fixture.mandatoryIds.first);
      expect(step.stepNumber, 1);
    });

    test('moves on to the next question after an answer is recorded', () {
      final fixture = _Fixture();
      fixture.record(
        caseId: fixture.case_.id,
        requestingUserId: 'user1',
        requirementId: fixture.mandatoryIds.first,
        value: 'javob',
      );

      final step = fixture.nextQuestion(caseId: fixture.case_.id, requestingUserId: 'user1');

      expect(step!.requirement.id, isNot(fixture.mandatoryIds.first));
    });

    test('returns null once every question has been answered', () {
      final fixture = _Fixture();
      for (final requirement
          in const StaticInformationRequirementCatalog().requirementsFor(
            CaseCategory.complaint,
          )) {
        fixture.record(
          caseId: fixture.case_.id,
          requestingUserId: 'user1',
          requirementId: requirement.id,
          value: 'javob',
        );
      }

      expect(fixture.nextQuestion(caseId: fixture.case_.id, requestingUserId: 'user1'), isNull);
    });

    test('remaining() shrinks as answers come in', () {
      final fixture = _Fixture();
      final before = fixture.nextQuestion.remaining(
        caseId: fixture.case_.id,
        requestingUserId: 'user1',
      );

      fixture.record(
        caseId: fixture.case_.id,
        requestingUserId: 'user1',
        requirementId: fixture.mandatoryIds.first,
        value: 'javob',
      );
      final after = fixture.nextQuestion.remaining(
        caseId: fixture.case_.id,
        requestingUserId: 'user1',
      );

      expect(after.length, before.length - 1);
    });

    test('enforces case ownership', () {
      final fixture = _Fixture();

      expect(
        () => fixture.nextQuestion(caseId: fixture.case_.id, requestingUserId: 'boshqa'),
        throwsA(isA<CaseAccessDeniedException>()),
      );
    });
  });

  group('BuildCaseActionPlanUseCase', () {
    test('plans one collect-information step per missing requirement', () async {
      final fixture = _Fixture();

      final plan = await fixture.buildPlan(
        caseId: fixture.case_.id,
        requestingUserId: 'user1',
      );

      final requirementCount = const StaticInformationRequirementCatalog()
          .requirementsFor(CaseCategory.complaint)
          .length;
      expect(plan.stepCount, requirementCount);
      expect(
        plan.steps.every((s) => s.kind == NextStepKind.collectInformation),
        isTrue,
      );
      expect(plan.steps.map((s) => s.order), List.generate(requirementCount, (i) => i + 1));
    });

    test('hands off to a human specialist once mandatory information is complete', () async {
      final fixture = _Fixture()..answerAllMandatory();

      final plan = await fixture.buildPlan(
        caseId: fixture.case_.id,
        requestingUserId: 'user1',
      );

      expect(plan.steps.last.kind, NextStepKind.consultHumanSpecialist);
    });

    test('for documentGeneration it only prepares for the document stage', () async {
      final fixture = _Fixture(category: CaseCategory.documentGeneration)..answerAllMandatory();

      final plan = await fixture.buildPlan(
        caseId: fixture.case_.id,
        requestingUserId: 'user1',
      );

      expect(plan.steps.last.kind, NextStepKind.prepareDocumentLater);
      // Hujjatning O'ZI yaratilmaydi -- reja faqat qadamlardan iborat.
      expect(plan.steps.every((s) => s.title.trim().isNotEmpty), isTrue);
    });

    test('an archived case gets an empty plan', () async {
      final fixture = _Fixture();
      fixture.caseRepository.updateStatus(fixture.case_.id, CaseStatus.archived);

      final plan = await fixture.buildPlan(
        caseId: fixture.case_.id,
        requestingUserId: 'user1',
      );

      expect(plan.isEmpty, isTrue);
    });

    test('does not change the case in any way', () async {
      final fixture = _Fixture();
      final before = fixture.caseRepository.getById(fixture.case_.id);

      await fixture.buildPlan(caseId: fixture.case_.id, requestingUserId: 'user1');

      expect(fixture.caseRepository.getById(fixture.case_.id), before);
    });

    test('enforces case ownership', () async {
      final fixture = _Fixture();

      expect(
        () => fixture.buildPlan(caseId: fixture.case_.id, requestingUserId: 'boshqa'),
        throwsA(isA<CaseAccessDeniedException>()),
      );
    });
  });

  group('GetCaseProgressUseCase', () {
    test('reports nothing complete and everything missing for a new case', () {
      final fixture = _Fixture();

      final progress = fixture.progress(caseId: fixture.case_.id, requestingUserId: 'user1');

      expect(progress.completedInformation, isEmpty);
      expect(progress.missingInformation, isNotEmpty);
      expect(progress.informationCompletionRatio, 0.0);
      expect(progress.caseId, fixture.case_.id);
    });

    test('moves the completed/missing split as answers are recorded', () {
      final fixture = _Fixture();
      fixture.record(
        caseId: fixture.case_.id,
        requestingUserId: 'user1',
        requirementId: fixture.mandatoryIds.first,
        value: 'javob',
      );

      final progress = fixture.progress(caseId: fixture.case_.id, requestingUserId: 'user1');

      expect(progress.completedInformation.map((r) => r.id), [fixture.mandatoryIds.first]);
      expect(
        progress.missingInformation.map((r) => r.id).contains(fixture.mandatoryIds.first),
        isFalse,
      );
      expect(progress.informationCompletionRatio, greaterThan(0.0));
    });

    test('is recomputed, never stored -- it follows the case state', () {
      final fixture = _Fixture();
      final before = fixture.progress(caseId: fixture.case_.id, requestingUserId: 'user1');

      fixture.answerAllMandatory();
      final after = fixture.progress(caseId: fixture.case_.id, requestingUserId: 'user1');

      expect(before.isInformationSufficient, isFalse);
      expect(after.isInformationSufficient, isTrue);
    });

    test('enforces case ownership', () {
      final fixture = _Fixture();

      expect(
        () => fixture.progress(caseId: fixture.case_.id, requestingUserId: 'boshqa'),
        throwsA(isA<CaseAccessDeniedException>()),
      );
    });
  });
}
