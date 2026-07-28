import '../../../../core/network/result.dart';
import '../entities/appeal.dart';
import '../repositories/appeals_repository.dart';

/// Yangi murojaat qoralamasini yaratadi (docs/UI.md, "Authentication
/// Screens"dan keyingi asosiy oqim — murojaat yaratish).
class CreateAppealDraftUseCase {
  const CreateAppealDraftUseCase(this._repository);

  final AppealsRepository _repository;

  Future<Result<Appeal>> call({
    required String categoryId,
    required String recipientBodyId,
    required String title,
    required String bodyText,
    String? aiDraftText,
  }) {
    return _repository.createDraft(
      categoryId: categoryId,
      recipientBodyId: recipientBodyId,
      title: title,
      bodyText: bodyText,
      aiDraftText: aiDraftText,
    );
  }
}
