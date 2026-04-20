// Слой: data | Назначение: определение Drift-таблицы Items с TypeConverter для enum

import 'package:drift/drift.dart';
import '../../domain/entities/item.dart';

// TypeConverter: сохраняет ItemStatus как int в SQLite
class ItemStatusConverter extends TypeConverter<ItemStatus, int> {
  const ItemStatusConverter();

  @override
  ItemStatus fromSql(int fromDb) => ItemStatus.values[fromDb];

  @override
  int toSql(ItemStatus value) => value.index;
}

// Drift-таблица элементов (генерирует ItemData, ItemsCompanion)
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get status =>
      integer().map(const ItemStatusConverter()).withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
