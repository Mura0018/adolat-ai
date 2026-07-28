import '../../../../core/network/result.dart';
import '../entities/dispute.dart';
import '../repositories/disputes_repository.dart';

class CreateDisputeUseCase {
  const CreateDisputeUseCase(this._repository);

  final DisputesRepository _repository;

  Future<Result<Dispute>> call({
    required String categoryId,
    required String title,
    required String description,
    required String respondentDisplayName,
  }) {
    return _repository.createWithUnregisteredRespondent(
      categoryId: categoryId,
      title: title,
      description: description,
      respondentDisplayName: respondentDisplayName,
    );
  }
}
