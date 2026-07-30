import '../workflow_exceptions.dart';
import 'action_plan_step.dart';

/// Ish bo'yicha TARTIBLANGAN keyingi qadamlar tuzilmasi (Module 5,
/// Phase 5C talabi: "Action plan foundation").
///
/// **Bu YAKUNIY HUQUQIY MASLAHAT EMAS** (talab: "No final legal
/// advice") -- reja faqat JARAYONNI tavsiflaydi: qaysi ma'lumot
/// kerak, qachon ko'rib chiqish kerak, qachon odam-mutaxassisga
/// murojaat qilish kerak. Ishning huquqiy natijasi/istiqboli haqida
/// hech qanday da'vo yo'q.
///
/// **Hujjat GENERATSIYA QILINMAYDI** (talab: "No document generation"):
/// `NextStepKind.prepareDocumentLater` qadami faqat KELGUSI bosqichga
/// ishora qiladi, hech qanday matn/shablon ishlab chiqarmaydi.
class ActionPlan {
  /// [steps] `order` bo'yicha 1'dan boshlanib UZLUKSIZ o'sishi shart.
  ///
  /// Tashlaydi: `InvalidActionPlanOrderException` -- tartib buzilgan
  /// bo'lsa (`../workflow_exceptions.dart`). Bu invariant ATAYLAB
  /// tuzilish vaqtida majburlanadi: "ordered structure" -- shu
  /// klassning yagona va'dasi, uni buzilgan holda tarqatish
  /// foydalanuvchiga noto'g'ri ketma-ketlik ko'rsatishga olib keladi.
  ActionPlan({required this.caseId, required List<ActionPlanStep> steps})
    : steps = List.unmodifiable(steps) {
    _validateOrder(this.steps);
  }

  /// Hech qanday qadam yo'q (masalan ish arxivlangan) -- bu XATOLIK
  /// emas, oddiy holat.
  ActionPlan.empty(this.caseId) : steps = const [];

  final String caseId;
  final List<ActionPlanStep> steps;

  static void _validateOrder(List<ActionPlanStep> steps) {
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].order != i + 1) {
        throw InvalidActionPlanOrderException([for (final step in steps) step.order]);
      }
    }
  }

  bool get isEmpty => steps.isEmpty;

  int get stepCount => steps.length;

  /// Navbatdagi bajarilmagan qadam; hammasi bajarilgan (yoki reja
  /// bo'sh) bo'lsa `null`.
  ActionPlanStep? get nextStep {
    for (final step in steps) {
      if (step.status != ActionPlanStepStatus.done) return step;
    }
    return null;
  }

  int get completedStepCount =>
      steps.where((s) => s.status == ActionPlanStepStatus.done).length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ActionPlan) return false;
    if (other.caseId != caseId || other.steps.length != steps.length) return false;
    for (var i = 0; i < steps.length; i++) {
      if (other.steps[i] != steps[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(caseId, Object.hashAll(steps));

  @override
  String toString() => 'ActionPlan(caseId: $caseId, ${steps.length} steps)';
}
