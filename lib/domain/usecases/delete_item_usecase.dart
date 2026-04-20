// Слой: domain | Назначение: use case удаления элемента по id

import '../repositories/item_repository.dart';
import 'base_usecase.dart';

class DeleteItemUseCase implements UseCase<void, int> {
  DeleteItemUseCase(this._repository);

  final ItemRepository _repository;

  @override
  Future<void> call(int params) {
    return _repository.delete(params);
  }
}
