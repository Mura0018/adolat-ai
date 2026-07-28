import '../../../../core/network/result.dart';
import '../entities/appeal.dart';
import '../repositories/appeals_repository.dart';

class ListMyAppealsUseCase {
  const ListMyAppealsUseCase(this._repository);

  final AppealsRepository _repository;

  Future<Result<List<Appeal>>> call() {
    return _repository.listMine();
  }
}
