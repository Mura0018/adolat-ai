import '../../../../core/network/result.dart';
import '../repositories/disputes_repository.dart';

class DeleteDisputeUseCase {
  const DeleteDisputeUseCase(this._repository);

  final DisputesRepository _repository;

  Future<Result<void>> call(String disputeId) {
    return _repository.deleteAsInitiator(disputeId);
  }
}
