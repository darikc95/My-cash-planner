// Слой: domain | Назначение: use case получения элемента по id

import '../entities/item.dart';
import '../repositories/item_repository.dart';
import 'base_usecase.dart';

class GetItemByIdUseCase implements UseCase<Item?, int> {
  GetItemByIdUseCase(this._repository);

  final ItemRepository _repository;

  @override
  Future<Item?> call(int params) {
    return _repository.getById(params);
  }
}
