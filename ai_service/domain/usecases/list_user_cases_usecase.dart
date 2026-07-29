import '../case/case.dart';
import '../repositories/case_repository.dart';

/// Berilgan foydalanuvchining BARCHA ishlarini qaytaradi (Module 5,
/// Phase 5B talabi: "Case Repository Contract -- list user cases").
///
/// Alohida "egalik tekshiruvi" YO'Q (`GetCaseUseCase`dan farqli) --
/// `CaseRepository.listForUser()`ning o'zi natijani ALLAQACHON [userId]
/// bilan chegaralab beradi, boshqa foydalanuvchining ishi natijada
/// HECH QACHON paydo bo'lmaydi (Module 5, Phase 5B talabi: "Security
/// Rules -- User can only access own cases").
class ListUserCasesUseCase {
  const ListUserCasesUseCase(this._caseRepository);

  final CaseRepository _caseRepository;

  List<Case> call(String userId) => _caseRepository.listForUser(userId);
}
