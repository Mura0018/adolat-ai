import '../../domain/case/case_category.dart';
import '../../domain/case/intake/case_intake_assistant.dart';
import '../../domain/case/intake/case_intake_question.dart';

/// `CaseIntakeAssistant`ning FOUNDATION (mock) implementatsiyasi
/// (Module 5, Phase 5B talabi: "Use mock AI responses only") --
/// haqiqiy AI mulohaza yuritish (reasoning) YO'Q, faqat
/// [category]ga qarab OLDINDAN TAYYORLANGAN, deterministik savollar
/// ro'yxati qaytariladi.
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
  const MockCaseIntakeAssistant();

  static const Map<CaseCategory, List<String>> _questionTemplates = {
    CaseCategory.complaint: [
      'Shikoyat qaysi tashkilot/shaxsga qarshi qaratilgan?',
      'Voqea qachon sodir bo\'lgan?',
      'Hozirgacha shu masala bo\'yicha biror qadam qo\'yganmisiz?',
    ],
    CaseCategory.application: [
      'Arizangiz qaysi davlat organiga yo\'naltirilishi kerak?',
      'Arizaga biriktirilishi kerak bo\'lgan hujjatlaringiz bormi?',
    ],
    CaseCategory.legalAssistance: [
      'Vaziyatni birlashtiruvchi asosiy savolingiz nima?',
      'Bu masala bo\'yicha allaqachon boshqa maslahat olganmisiz?',
    ],
    CaseCategory.documentGeneration: [
      'Qaysi turdagi hujjat kerak (ariza, shikoyat, ...)?',
      'Hujjatda albatta bo\'lishi kerak bo\'lgan asosiy faktlar qanday?',
    ],
  };

  @override
  Future<List<CaseIntakeQuestion>> generateClarificationQuestions({
    required String problemDescription,
    required CaseCategory category,
  }) async {
    final templates = _questionTemplates[category] ?? const [];
    return [
      for (var i = 0; i < templates.length; i++)
        CaseIntakeQuestion(id: '${category.name}_q${i + 1}', text: templates[i]),
    ];
  }
}
