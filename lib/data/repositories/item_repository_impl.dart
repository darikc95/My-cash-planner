// Слой: data | Назначение: реализация ItemRepository через локальный Drift-источник

import '../../domain/entities/item.dart';
import '../../domain/repositories/item_repository.dart';
import '../datasources/item_local_datasource.dart';

class ItemRepositoryImpl implements ItemRepository {
  ItemRepositoryImpl(this._localDatasource);

  final ItemLocalDatasource _localDatasource;

  @override
  Future<List<Item>> getAll() => _localDatasource.getAll();

  @override
  Future<Item?> getById(int id) => _localDatasource.getById(id);

  @override
  Future<Item> create({required String title, String? description}) {
    return _localDatasource.create(title: title, description: description);
  }

  @override
  Future<Item> update(Item item) => _localDatasource.update(item);

  @override
  Future<void> delete(int id) => _localDatasource.delete(id);

  @override
  Future<List<Item>> search(String query) => _localDatasource.search(query);

  @override
  Future<List<Item>> filterByStatus(ItemStatus status) {
    return _localDatasource.filterByStatus(status);
  }
}
