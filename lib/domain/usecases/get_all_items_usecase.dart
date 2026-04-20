// Слой: domain | Назначение: use case получения всех элементов

import '../entities/item.dart';
import '../repositories/item_repository.dart';
import 'base_usecase.dart';

class GetAllItemsUseCase implements UseCase<List<Item>, NoParams> {
  GetAllItemsUseCase(this._repository);

  final ItemRepository _repository;

  @override
  Future<List<Item>> call(NoParams params) {
    return _repository.getAll();
  }
}
