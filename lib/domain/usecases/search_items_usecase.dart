// Слой: domain | Назначение: use case поиска элементов по строке запроса

import '../entities/item.dart';
import '../repositories/item_repository.dart';
import 'base_usecase.dart';

class SearchItemsUseCase implements UseCase<List<Item>, String> {
  SearchItemsUseCase(this._repository);

  final ItemRepository _repository;

  @override
  Future<List<Item>> call(String params) {
    return _repository.search(params);
  }
}
