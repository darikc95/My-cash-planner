// Слой: data | Назначение: Drift AppDatabase — singleton, таблицы, маппер-расширения

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/item.dart';
import '../../domain/entities/user.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Users, Items])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  // Статический синглтон для простого доступа без DI-фреймворка
  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase();

  @override
  int get schemaVersion => 1;

  // Миграции при обновлении схемы
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Добавляйте миграции сюда при schemaVersion > 1
        },
      );
}

// Открытие соединения с файлом БД в директории документов устройства
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_database.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

// Маппер расширения определены здесь, т.к. UserData/ItemData
// генерируются build_runner в app_database.g.dart (part-файл)

extension UserDataMapper on UserData {
  User toEntity() => User(
        id: id,
        email: email,
        name: name,
        createdAt: createdAt,
      );
}

extension ItemDataMapper on ItemData {
  Item toEntity() => Item(
        id: id,
        title: title,
        description: description,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
