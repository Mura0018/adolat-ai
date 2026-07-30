import '../../case/case_category.dart';
import '../collected_information.dart';
import 'information_completeness.dart';

/// "Yetarli ma'lumot to'plandimi" savolini baholovchi CHEGARA
/// (Module 5, Phase 5C talabi: "Information completeness evaluation").
///
/// **Nega interfeys, garchi hozircha bitta xolis (pure) implementatsiya
/// bo'lsa ham:** kelgusida bu baho boyroq bo'lishi mumkin (masalan
/// javobning uzunligi/sifatini hisobga olish). Shunda ham chaqiruvchi
/// (`EvaluateCaseCompletenessUseCase`, `ClarificationWorkflow`,
/// `GetCaseProgressUseCase`) o'zgarmaydi.
///
/// **Baho HUQUQIY EMAS** -- `information_completeness.dart`dagi
/// izohga qarang: bu faqat "so'ralgan bo'laklar to'ldirilganmi".
/// Implementatsiya HECH QACHON huquqiy xulosa chiqarmasligi shart
/// (talab: "No legal judgement").
abstract interface class InformationCompletenessEvaluator {
  InformationCompleteness evaluate({
    required CaseCategory category,
    required CollectedInformation collected,
  });
}
