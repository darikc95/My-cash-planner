// Слой: data | Назначение: определение Drift-таблицы Users

import 'package:drift/drift.dart';

// Drift-таблица пользователей (генерирует UserData, UsersCompanion)
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get password => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
}
