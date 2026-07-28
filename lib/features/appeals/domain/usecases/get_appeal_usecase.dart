import '../../../../core/network/result.dart';
import '../entities/appeal.dart';
import '../repositories/appeals_repository.dart';

class GetAppealUseCase {
  const GetAppealUseCase(this._repository);

  final AppealsRepository _repository;

  Future<Result<Appeal>> call(String appealId) {
    return _repository.getById(appealId);
  }
}
