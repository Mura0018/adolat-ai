import '../../domain/case/case_category.dart';
import '../../domain/case/intake/case_intake_assistant.dart';
import '../../domain/case/intake/case_intake_question.dart';
import '../../domain/workflow/information_requirement_catalog.dart';
import '../workflow/static_information_requirement_catalog.dart';

/// `CaseIntakeAssistant`ning FOUNDATION (mock) implementatsiyasi
/// (Module 5, Phase 5B talabi: "Use mock AI responses only") --
/// haqiqiy AI mulohaza yuritish (reasoning) YO'Q, faqat [category]ga
/// qarab OLDINDAN TAYYORLANGAN, deterministik savollar ro'yxati
/// qaytariladi.
///
/// **Module 5, Phase 5C o'zgarishi (DRY):** savol matnlari ilgari shu
/// klassning ichida saqlanardi. Endi ular
/// `InformationRequirementCatalog`dan (`data/workflow/
/// static_information_requirement_catalog.dart`) keladi -- ya'ni
/// "birinchi beriladigan savollar" va "yetishmayotgan ma'lumot
/// bo'laklari" YAGONA manbadan oziqlanadi (`DEVELOPMENT_RULES.md`,
/// 7-band). Muhim amaliy natija: `CaseIntakeQuestion.id` endi
/// `InformationRequirement.id` bilan BIR XIL, shuning uchun
/// foydalanuvchining javobi to'g'ridan-to'g'ri kerakli bo'lakka
/// yozilishi mumkin (`RecordCaseInformationUseCase`) -- oldin savol
/// ID'lari (`complaint_q1`) hech qanday ma'lumot bo'lagiga
/// bog'lanmasdi.
///
/// **Nega [problemDescription]ning o'zi tahlil qilinmaydi:** talab
/// "DO NOT connect real AI providers" -- matnni "tushunish" (NLP/LLM
/// chaqiruvi) shu klassning vazifasi emas. Savollar faqat
/// [category]ga bog'liq -- shu bilan bu implementatsiya haqiqiy AI
/// bilan ALMASHTIRILGANDA (`CaseIntakeAssistant` interfeysi orqali,
/// boshqa hech narsa o'zgarmasdan) natija SIFAT jihatidan farq
/// qilishi kutiladi, lekin SHAKL (bir nechta savol qaytarish) bir xil
/// qoladi.
class MockCaseIntakeAssistant implements CaseIntakeAssistant {
  const MockCaseIntakeAssistant({
    InformationRequirementCatalog catalog = const StaticInformationRequirementCatalog(),
  }) : _catalog = catalog;

  final InformationRequirementCatalog _catalog;

  @override
  Future<List<CaseIntakeQuestion>> generateClarificationQuestions({
    required String problemDescription,
    required CaseCategory category,
  }) async {
    return [
      for (final requirement in _catalog.requirementsFor(category))
        CaseIntakeQuestion(id: requirement.id, text: requirement.question),
    ];
  }
}
