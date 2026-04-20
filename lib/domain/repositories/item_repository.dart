// Слой: domain | Назначение: абстрактный интерфейс CRUD-репозитория элементов

import '../entities/item.dart';

abstract class ItemRepository {
  Future<List<Item>> getAll();

  Future<Item?> getById(int id);

  Future<Item> create({
    required String title,
    String? description,
  });

  Future<Item> update(Item item);

  Future<void> delete(int id);

  Future<List<Item>> search(String query);

  Future<List<Item>> filterByStatus(ItemStatus status);
}
