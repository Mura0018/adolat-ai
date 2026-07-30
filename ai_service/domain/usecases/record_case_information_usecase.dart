import '../case/case.dart';
import '../repositories/case_repository.dart';
import '../workflow/information_requirement_catalog.dart';
import '../workflow/workflow_exceptions.dart';
import 'get_case_usecase.dart';
import 'record_case_answer_usecase.dart';

/// Foydalanuvchining javobini ANIQ bir ma'lumot bo'lagiga
/// (`InformationRequirement.id`) bog'lab yozadi (Module 5, Phase 5C
/// talabi: "Progress tracking -- show what information is complete").
///
/// **`RecordCaseAnswerUseCase` (Module 5, Phase 5B) bilan farqi:**
/// u erkin matnli javobni FAQAT suhbatga va timeline'ga yozadi
/// (javob qaysi savolga tegishli ekani noma'lum qoladi). Bu usecase
/// esa uning USTIGA quriladi: avval bo'lakning haqiqiyligini
/// tekshiradi, keyin o'sha usecase'ni chaqiradi (suhbat + timeline --
/// KOD TAKRORLANMAYDI, `DEVELOPMENT_RULES.md`, 7-band), so'ng
/// javobni `Case.collectedInformation`ga yozadi.
///
/// Natijada tarix (timeline) va joriy holat (collectedInformation)
/// bir tranzaksiyada, bir xil manbadan yangilanadi.
///
/// **Xavfsizlik:** `GetCaseUseCase` orqali EGALIK tekshiriladi --
/// begona foydalanuvchi boshqa birovning ishiga ma'lumot yoza
/// olmaydi (`CaseAccessDeniedException`).
class RecordCaseInformationUseCase {
  const RecordCaseInformationUseCase({
    required CaseRepository caseRepository,
    required GetCaseUseCase getCase,
    required RecordCaseAnswerUseCase recordAnswer,
    required InformationRequirementCatalog catalog,
  }) : _caseRepository = caseRepository,
       _getCase = getCase,
       _recordAnswer = recordAnswer,
       _catalog = catalog;

  final CaseRepository _caseRepository;
  final GetCaseUseCase _getCase;
  final RecordCaseAnswerUseCase _recordAnswer;
  final InformationRequirementCatalog _catalog;

  /// Tashlaydi:
  /// - `CaseNotFoundException` -- ish topilmasa;
  /// - `CaseAccessDeniedException` -- ish [requestingUserId]ga tegishli
  ///   bo'lmasa;
  /// - `UnknownInformationRequirementException` -- [requirementId] shu
  ///   ish toifasi uchun katalogda bo'lmasa (`../workflow/
  ///   workflow_exceptions.dart` -- nega jimgina e'tiborsiz
  ///   qoldirilmasligi shu yerda izohlangan).
  Case call({
    required String caseId,
    required String requestingUserId,
    required String requirementId,
    required String value,
  }) {
    final case_ = _getCase(caseId: caseId, requestingUserId: requestingUserId);

    final isKnown = _catalog
        .requirementsFor(case_.category)
        .any((requirement) => requirement.id == requirementId);
    if (!isKnown) {
      throw UnknownInformationRequirementException(
        requirementId: requirementId,
        category: case_.category,
      );
    }

    // Suhbat + timeline yozuvi (Phase 5B mantig'i, qayta yozilmaydi).
    _recordAnswer(caseId: caseId, answer: value);

    return _caseRepository.recordInformation(caseId, requirementId, value);
  }
}
