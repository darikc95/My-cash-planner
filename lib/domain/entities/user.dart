// Слой: domain | Назначение: чистая сущность пользователя (без Flutter-зависимостей)

import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  final int id;
  final String email;
  final String name;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, email, name, createdAt];
}
