import '../../../../core/network/result.dart';
import '../entities/dispute.dart';
import '../repositories/disputes_repository.dart';

class UpdateDisputeAsInitiatorUseCase {
  const UpdateDisputeAsInitiatorUseCase(this._repository);

  final DisputesRepository _repository;

  Future<Result<Dispute>> call({
    required String disputeId,
    String? title,
    String? description,
  }) {
    return _repository.updateAsInitiator(
      disputeId: disputeId,
      title: title,
      description: description,
    );
  }
}
