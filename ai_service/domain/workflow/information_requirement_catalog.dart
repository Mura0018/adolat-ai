import '../case/case_category.dart';
import 'information_requirement.dart';

/// Har bir ish toifasi uchun QANDAY ma'lumot bo'laklari kerakligini
/// biladigan YAGONA manba (Module 5, Phase 5C talabi: "Clarification
/// workflow -- AI determines missing information").
///
/// **Nega interfeys:** hozirgi implementatsiya -- statik, oldindan
/// yozilgan ro'yxat (`data/workflow/static_information_requirement_catalog.dart`,
/// talab: "Mock responses only"). Kelgusida bu ro'yxat backend
/// konfiguratsiyasidan yoki (huquqiy jamoa tomonidan tasdiqlangan)
/// shablon bazasidan kelishi mumkin -- chaqiruvchi kod (`ClarificationWorkflow`,
/// `RequirementChecklistEvaluator`) o'zgarmaydi. `CaseIntakeAssistant`
/// (Module 5, Phase 5B) bilan bir xil almashtiriladigan-chegara
/// falsafasi.
///
/// **Provayderdan mustaqil:** bu interfeys ham, uning implementatsiyasi
/// ham `AIProviderId`/`AIProviderAdapter`/`AIRepository` (Module 4)ni
/// HECH QACHON import qilmaydi (talab: "No AI provider integration").
abstract interface class InformationRequirementCatalog {
  /// Berilgan toifa uchun kerakli bo'laklar -- TARTIB MA'NOLI:
  /// ro'yxatdagi ketma-ketlik aniqlashtiruvchi savollarning berilish
  /// tartibini belgilaydi (`ClarificationWorkflow`).
  ///
  /// Noma'lum/ro'yxatga olinmagan toifa uchun bo'sh ro'yxat qaytarish
  /// mumkin -- bu xatolik EMAS (`InformationCompleteness` bo'sh
  /// ro'yxatni "hamma narsa to'plangan" deb hisoblaydi, shu
  /// faylning izohiga qarang).
  List<InformationRequirement> requirementsFor(CaseCategory category);
}
