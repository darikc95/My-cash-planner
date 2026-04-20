// Слой: domain | Назначение: чистая сущность элемента списка (без Flutter-зависимостей)

import 'package:equatable/equatable.dart';

enum ItemStatus { active, archived }

class Item extends Equatable {
  const Item({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String? description;
  final ItemStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item copyWith({
    int? id,
    String? title,
    String? description,
    ItemStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, description, status, createdAt, updatedAt];
}
