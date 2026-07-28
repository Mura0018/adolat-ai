import '../../../../core/network/result.dart';
import '../repositories/appeals_repository.dart';

class DeleteAppealDraftUseCase {
  const DeleteAppealDraftUseCase(this._repository);

  final AppealsRepository _repository;

  Future<Result<void>> call(String appealId) {
    return _repository.deleteDraft(appealId);
  }
}
