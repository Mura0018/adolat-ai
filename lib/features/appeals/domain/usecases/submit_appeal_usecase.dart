import '../../../../core/network/result.dart';
import '../entities/appeal.dart';
import '../repositories/appeals_repository.dart';

/// Qoralamani yakuniy tasdiqlab, davlat organiga yuborilishi uchun
/// taqdim etadi (docs/ARCHITECTURE.md, "Case Lifecycle" bo'limi:
/// `draft` → `submitted`).
///
/// MUHIM: bu amal joriy RLS siyosati ostida muvaffaqiyatsiz tugaydi —
/// tafsilotlar uchun ushbu vazifa yakunidagi audit hisobotiga qarang
/// (Critical topilma).
class SubmitAppealUseCase {
  const SubmitAppealUseCase(this._repository);

  final AppealsRepository _repository;

  Future<Result<Appeal>> call(String appealId) {
    return _repository.submit(appealId);
  }
}
