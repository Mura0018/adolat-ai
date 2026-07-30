/// `ai_service/domain/workflow/` (Module 5, Phase 5C) tashlaydigan
/// xatolik turlari -- `domain/case/case_exceptions.dart` (Phase 5B)
/// bilan bir xil konventsiya: hammasi kutilgan ish vaqti holatlari
/// (dasturlash xatosi EMAS), shuning uchun `Error` emas, `Exception`.
library;

/// Berilgan `requirementId` shu ish TOIFASI uchun ro'yxatda YO'Q
/// (`InformationRequirementCatalog.requirementsFor()`).
///
/// Ataylab "jimgina e'tiborsiz qoldirish" (silently ignore) EMAS --
/// aks holda noto'g'ri kalit bilan yozilgan javob hech qachon
/// progressda ko'rinmaydi va foydalanuvchi sababini bilmay qoladi
/// (`DEVELOPMENT_RULES.md`, 17–18-band, "No Dead End Rule").
class UnknownInformationRequirementException implements Exception {
  const UnknownInformationRequirementException({
    required this.requirementId,
    required this.category,
  });

  final String requirementId;

  /// `CaseCategory` -- bu yerda `Object` sifatida saqlanadi, shu bilan
  /// xatolik turi `domain/case/`ga bog'lanib qolmaydi
  /// (`InvalidCaseStatusTransitionException`, Phase 5B bilan bir xil
  /// yondashuv).
  final Object category;

  @override
  String toString() =>
      'UnknownInformationRequirementException(requirementId: $requirementId, category: $category)';
}

/// `ActionPlan` qadamlarining tartib raqamlari buzilgan (1'dan
/// boshlanib, birma-bir o'sishi shart -- `action_plan/action_plan.dart`).
///
/// Bu -- "ordered next-step structure" (Module 5, Phase 5C talabi)ning
/// INVARIANTI: tartibsiz reja foydalanuvchiga ketma-ketlikni noto'g'ri
/// ko'rsatishi mumkin, shuning uchun tuzilish vaqtidayoq rad etiladi.
class InvalidActionPlanOrderException implements Exception {
  const InvalidActionPlanOrderException(this.orders);

  final List<int> orders;

  @override
  String toString() => 'InvalidActionPlanOrderException(orders: $orders)';
}
