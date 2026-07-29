import '../case/case.dart';
import '../case/case_status.dart';
import '../repositories/case_repository.dart';

/// Ishni bir hayot-davri holatidan ikkinchisiga o'tkazadi (Module 5,
/// Phase 5B talabi: "Case Lifecycle").
///
/// **Bu usecase QACHON chaqirilishi kerakligini HAL QILMAYDI** --
/// faqat chaqirilganda o'tishning MANTIQAN to'g'ri ekanligini
/// tekshiradi (`Case.withStatus()` orqali). Kim/nima asosida (admin
/// amali, keyinchalik AI xulosasi) `actionPlanning`ga o'tish kerakligi
/// haqida QAROR qabul qilish -- talab: "Do not implement legal
/// decisions" doirasidan tashqarida, chaqiruvchining ishi.
class AdvanceCaseStatusUseCase {
  const AdvanceCaseStatusUseCase(this._caseRepository);

  final CaseRepository _caseRepository;

  /// Tashlaydi:
  /// - `CaseNotFoundException` -- ish topilmasa.
  /// - `InvalidCaseStatusTransitionException` -- o'tish noto'g'ri
  ///   bo'lsa (`../case/case_status.dart`, [isValidCaseStatusTransition]).
  Case call({required String caseId, required CaseStatus newStatus}) {
    return _caseRepository.updateStatus(caseId, newStatus);
  }
}
