import '../../domain/case/case_category.dart';
import '../../domain/workflow/information_requirement.dart';
import '../../domain/workflow/information_requirement_catalog.dart';

/// `InformationRequirementCatalog`ning FOUNDATION implementatsiyasi
/// (Module 5, Phase 5C talabi: "Mock responses only") -- toifaga
/// qarab OLDINDAN YOZILGAN, deterministik ro'yxat. Hech qanday NLP/
/// LLM chaqiruvi, hech qanday tashqi manba yo'q.
///
/// **Bu fayl -- aniqlashtiruvchi savollarning YAGONA manbai:**
/// `MockCaseIntakeAssistant` (Module 5, Phase 5B, `data/intake/`) ham
/// endi shu katalogdan oziqlanadi -- ilgari savol matnlari o'sha
/// klassda alohida saqlanardi, natijada "birinchi savollar" va
/// "yetishmayotgan ma'lumot" ro'yxatlari bir-biridan uzilib ketish
/// xavfi bor edi (`DEVELOPMENT_RULES.md`, 7-band, DRY). Endi
/// `CaseIntakeQuestion.id` == `InformationRequirement.id`, ya'ni
/// foydalanuvchining javobi to'g'ridan-to'g'ri kerakli bo'lakka
/// (`RecordCaseInformationUseCase`) bog'lanadi.
///
/// **Savollar FAQAT fakt so'raydi** (talab: "No legal judgement") --
/// birortasi ham foydalanuvchidan huquqiy baho ("huquqingiz
/// buzilganmi?") so'ramaydi va javob asosida hech qanday xulosa
/// chiqarilmaydi.
///
/// **Ixtiyoriy (`optional`) bo'laklar nega bor:** foydalanuvchi
/// hamma narsani bilishi shart emas -- majburiy bo'laklar
/// to'ldirilishi bilan oqim keyingi bosqichga o'tishga tayyor
/// bo'ladi, ixtiyoriylari esa "boshi berk holat" yaratmaydi
/// (`DEVELOPMENT_RULES.md`, 18-band).
class StaticInformationRequirementCatalog implements InformationRequirementCatalog {
  const StaticInformationRequirementCatalog();

  static const Map<CaseCategory, List<InformationRequirement>> _requirements = {
    CaseCategory.complaint: [
      InformationRequirement(
        id: 'complaint_target',
        question: 'Shikoyat qaysi tashkilot/shaxsga qarshi qaratilgan?',
      ),
      InformationRequirement(
        id: 'complaint_event_date',
        question: 'Voqea qachon sodir bo\'lgan?',
      ),
      InformationRequirement(
        id: 'complaint_prior_steps',
        question: 'Hozirgacha shu masala bo\'yicha biror qadam qo\'yganmisiz?',
      ),
      InformationRequirement(
        id: 'complaint_evidence',
        question: 'Vaziyatni tasdiqlovchi hujjat yoki yozishmalaringiz bormi?',
        importance: InformationImportance.optional,
      ),
    ],
    CaseCategory.application: [
      InformationRequirement(
        id: 'application_authority',
        question: 'Arizangiz qaysi davlat organiga yo\'naltirilishi kerak?',
      ),
      InformationRequirement(
        id: 'application_subject',
        question: 'Arizada nima so\'ralishi kerak?',
      ),
      InformationRequirement(
        id: 'application_attachments',
        question: 'Arizaga biriktirilishi kerak bo\'lgan hujjatlaringiz bormi?',
        importance: InformationImportance.optional,
      ),
    ],
    CaseCategory.legalAssistance: [
      InformationRequirement(
        id: 'assistance_main_question',
        question: 'Vaziyatni birlashtiruvchi asosiy savolingiz nima?',
      ),
      InformationRequirement(
        id: 'assistance_situation_summary',
        question: 'Vaziyat qanday yuzaga kelgan -- asosiy faktlarni sanab bering.',
      ),
      InformationRequirement(
        id: 'assistance_prior_advice',
        question: 'Bu masala bo\'yicha allaqachon boshqa maslahat olganmisiz?',
        importance: InformationImportance.optional,
      ),
    ],
    CaseCategory.documentGeneration: [
      InformationRequirement(
        id: 'document_type',
        question: 'Qaysi turdagi hujjat kerak (ariza, shikoyat, ...)?',
      ),
      InformationRequirement(
        id: 'document_recipient',
        question: 'Hujjat kimga/qaysi organga mo\'ljallangan?',
      ),
      InformationRequirement(
        id: 'document_key_facts',
        question: 'Hujjatda albatta bo\'lishi kerak bo\'lgan asosiy faktlar qanday?',
      ),
    ],
  };

  @override
  List<InformationRequirement> requirementsFor(CaseCategory category) {
    return _requirements[category] ?? const [];
  }
}
