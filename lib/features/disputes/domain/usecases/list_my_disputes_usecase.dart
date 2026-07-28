import '../../../../core/network/result.dart';
import '../entities/dispute.dart';
import '../repositories/disputes_repository.dart';

class ListMyDisputesUseCase {
  const ListMyDisputesUseCase(this._repository);

  final DisputesRepository _repository;

  Future<Result<List<Dispute>>> call() {
    return _repository.listMine();
  }
}
