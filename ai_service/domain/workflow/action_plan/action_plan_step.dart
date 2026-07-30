import '../next_step_kind.dart';

/// Reja qadamining bajarilish holati -- **operatsion**, huquqiy
/// ma'noga ega emas.
enum ActionPlanStepStatus { pending, inProgress, done }

/// Harakat rejasidagi BITTA tartibli qadam (Module 5, Phase 5C talabi:
/// "Action plan foundation -- prepare ordered next-step structure").
///
/// O'zgarmas (immutable) -- holatni o'zgartirish uchun [withStatus]
/// YANGI nusxa qaytaradi (`Case.withStatus()`, Module 5, Phase 5B
/// bilan bir xil naqsh).
class ActionPlanStep {
  const ActionPlanStep({
    required this.id,
    required this.order,
    required this.kind,
    required this.title,
    this.requirementId,
    this.status = ActionPlanStepStatus.pending,
  }) : assert(order >= 1, 'order 1 dan boshlanadi');

  final String id;

  /// 1'dan boshlanadigan tartib raqami -- `ActionPlan` bu raqamlarning
  /// UZLUKSIZ (1, 2, 3, ...) ekanligini tuzilish vaqtida tekshiradi.
  final int order;

  final NextStepKind kind;

  /// Foydalanuvchiga ko'rsatiladigan qadam matni -- JARAYON tili
  /// (talab: "No final legal advice"). Matn `Recommendation.message`dan
  /// keladi, ya'ni MAZMUN uchun mas'uliyat butunlay
  /// `RecommendationEngine`da (almashtiriladigan chegara), reja
  /// tuzuvchida emas.
  final String title;

  /// `NextStepKind.collectInformation` qadamlari uchun -- to'ldirilishi
  /// kerak bo'lgan `InformationRequirement.id`, aks holda `null`.
  final String? requirementId;

  final ActionPlanStepStatus status;

  ActionPlanStep withStatus(ActionPlanStepStatus newStatus) {
    return ActionPlanStep(
      id: id,
      order: order,
      kind: kind,
      title: title,
      requirementId: requirementId,
      status: newStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ActionPlanStep &&
            other.id == id &&
            other.order == order &&
            other.kind == kind &&
            other.title == title &&
            other.requirementId == requirementId &&
            other.status == status);
  }

  @override
  int get hashCode => Object.hash(id, order, kind, title, requirementId, status);

  @override
  String toString() =>
      'ActionPlanStep($order. ${kind.name}, id: $id, status: ${status.name})';
}
