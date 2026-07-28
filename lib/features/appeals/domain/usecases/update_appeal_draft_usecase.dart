import '../../../../core/network/result.dart';
import '../entities/appeal.dart';
import '../repositories/appeals_repository.dart';

/// Qoralama matnini tahrirlaydi — faqat `status = 'draft'` bo'lganda
/// muvaffaqiyatli bo'ladi (RLS server tomonida ta'minlaydi).
class UpdateAppealDraftUseCase {
  const UpdateAppealDraftUseCase(this._repository);

  final AppealsRepository _repository;

  Future<Result<Appeal>> call({
    required String appealId,
    String? title,
    String? bodyText,
  }) {
    return _repository.updateDraft(
      appealId: appealId,
      title: title,
      bodyText: bodyText,
    );
  }
}
