import '../case/case.dart';
import '../case/case_exceptions.dart';
import '../repositories/case_repository.dart';

/// Bitta ishni EGALIK tekshiruvi bilan qaytaradi (Module 5, Phase 5B
/// talabi: "Security Rules -- User can only access own cases").
///
/// **Nega bu tekshiruv `CaseRepository.getById()`ning o'zida EMAS:**
/// `AIRequestDispatcher`ning `request.userId != auth.userId`
/// tekshiruvi (Module 4, Phase 3B) bilan bir xil qatlamlash falsafasi
/// -- repository "aqlsiz" (faqat saqlash/qidirish), ruxsat mantig'i
/// YUQORI qatlamda, chunki bu BIZNES/xavfsizlik qoidasi, saqlash
/// tafsiloti emas.
class GetCaseUseCase {
  const GetCaseUseCase(this._caseRepository);

  final CaseRepository _caseRepository;

  /// Tashlaydi:
  /// - `CaseNotFoundException` -- ish topilmasa.
  /// - `CaseAccessDeniedException` -- ish topildi, lekin
  ///   [requestingUserId]ga tegishli EMAS.
  Case call({required String caseId, required String requestingUserId}) {
    final case_ = _caseRepository.getById(caseId);
    if (case_ == null) {
      throw CaseNotFoundException(caseId);
    }
    if (case_.userId != requestingUserId) {
      throw CaseAccessDeniedException(caseId: caseId, requestingUserId: requestingUserId);
    }
    return case_;
  }
}
