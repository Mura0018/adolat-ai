import '../../../../core/network/result.dart';
import '../entities/dispute.dart';
import '../repositories/disputes_repository.dart';

class SubmitRespondentStatementUseCase {
  const SubmitRespondentStatementUseCase(this._repository);

  final DisputesRepository _repository;

  Future<Result<Dispute>> call({
    required String disputeId,
    required String statement,
  }) {
    return _repository.submitRespondentStatement(
      disputeId: disputeId,
      statement: statement,
    );
  }
}
