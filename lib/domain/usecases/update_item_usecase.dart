// Слой: domain | Назначение: use case обновления существующего элемента

import '../entities/item.dart';
import '../repositories/item_repository.dart';
import 'base_usecase.dart';

class UpdateItemUseCase implements UseCase<Item, Item> {
  UpdateItemUseCase(this._repository);

  final ItemRepository _repository;

  @override
  Future<Item> call(Item params) {
    return _repository.update(params);
  }
}
