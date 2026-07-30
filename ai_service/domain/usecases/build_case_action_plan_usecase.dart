import '../workflow/action_plan/action_plan.dart';
import '../workflow/action_plan/action_plan_builder.dart';
import '../workflow/completeness/information_completeness_evaluator.dart';
import '../workflow/recommendation/recommendation_context.dart';
import '../workflow/recommendation/recommendation_engine.dart';
import 'get_case_usecase.dart';

/// Ish bo'yicha TARTIBLANGAN keyingi qadamlar rejasini tuzadi
/// (Module 5, Phase 5C talabi: "Action plan foundation").
///
/// Butun zanjir shu bitta usecase'da yig'iladi:
///
/// ```
/// Case -> InformationCompletenessEvaluator -> RecommendationContext
///      -> RecommendationEngine (almashtiriladigan chegara, hozircha mock)
///      -> ActionPlanBuilder (xolis tartiblash) -> ActionPlan
/// ```
///
/// **Nima YO'Q** (talab: "No final legal advice", "No document
/// generation", "No legal conclusions"):
/// - reja ishning huquqiy istiqboli/natijasi haqida hech narsa
///   aytmaydi -- faqat jarayon qadamlari;
/// - hech qanday hujjat matni yaratilmaydi (`NextStepKind.
///   prepareDocumentLater` faqat KELGUSI bosqichga ishora);
/// - rejani ish holatiga (`CaseStatus`) AVTOMATIK bog'lash yo'q --
///   reja tuzilishi ishni `actionPlanning` bosqichiga O'ZI
///   o'tkazmaydi (`AdvanceCaseStatusUseCase` alohida chaqiriladi).
class BuildCaseActionPlanUseCase {
  const BuildCaseActionPlanUseCase({
    required GetCaseUseCase getCase,
    required InformationCompletenessEvaluator evaluator,
    required RecommendationEngine recommendationEngine,
    required ActionPlanBuilder actionPlanBuilder,
  }) : _getCase = getCase,
       _evaluator = evaluator,
       _recommendationEngine = recommendationEngine,
       _actionPlanBuilder = actionPlanBuilder;

  final GetCaseUseCase _getCase;
  final InformationCompletenessEvaluator _evaluator;
  final RecommendationEngine _recommendationEngine;
  final ActionPlanBuilder _actionPlanBuilder;

  /// Tashlaydi: `CaseNotFoundException`, `CaseAccessDeniedException`.
  Future<ActionPlan> call({
    required String caseId,
    required String requestingUserId,
  }) async {
    final case_ = _getCase(caseId: caseId, requestingUserId: requestingUserId);

    final completeness = _evaluator.evaluate(
      category: case_.category,
      collected: case_.collectedInformation,
    );

    final recommendations = await _recommendationEngine.recommend(
      RecommendationContext(
        category: case_.category,
        status: case_.status,
        completeness: completeness,
      ),
    );

    return _actionPlanBuilder.build(caseId: case_.id, recommendations: recommendations);
  }
}
