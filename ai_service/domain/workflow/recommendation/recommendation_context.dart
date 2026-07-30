import '../../case/case_category.dart';
import '../../case/case_status.dart';
import '../completeness/information_completeness.dart';

/// `RecommendationEngine`ga uzatiladigan KIRISH ma'lumoti -- ish
/// haqidagi MINIMAL kesim (Module 5, Phase 5C).
///
/// **Nega `Case`ning O'ZI uzatilmaydi:** `Case` foydalanuvchi
/// identifikatori va muammoning xom matnini (`problemSummary`,
/// sezgir bo'lishi mumkin) olib yuradi. Tavsiya generatsiyasi bularga
/// MUHTOJ EMAS -- shuning uchun tavsiya chegarasidan (kelgusida
/// haqiqiy AI joylashishi mumkin bo'lgan nuqtadan) faqat kerakli
/// minimum o'tadi. `UserContext`ning ataylab minimal ekanligi
/// (`docs/adr/ADR-006`, Module 4, Phase 2B) bilan bir xil intizom.
class RecommendationContext {
  const RecommendationContext({
    required this.category,
    required this.status,
    required this.completeness,
  });

  final CaseCategory category;
  final CaseStatus status;
  final InformationCompleteness completeness;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RecommendationContext &&
            other.category == category &&
            other.status == status &&
            other.completeness == completeness);
  }

  @override
  int get hashCode => Object.hash(category, status, completeness);

  @override
  String toString() =>
      'RecommendationContext(category: ${category.name}, status: ${status.name}, '
      'completeness: $completeness)';
}
