import '../../../../core/network/result.dart';
import '../entities/dispute.dart';
import '../repositories/disputes_repository.dart';

class GetDisputeUseCase {
  const GetDisputeUseCase(this._repository);

  final DisputesRepository _repository;

  Future<Result<Dispute>> call(String disputeId) {
    return _repository.getById(disputeId);
  }
}
