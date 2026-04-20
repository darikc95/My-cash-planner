// Слой: domain | Назначение: use case создания нового элемента

import 'package:equatable/equatable.dart';
import '../entities/item.dart';
import '../repositories/item_repository.dart';
import 'base_usecase.dart';

class CreateItemUseCase implements UseCase<Item, CreateItemParams> {
  CreateItemUseCase(this._repository);

  final ItemRepository _repository;

  @override
  Future<Item> call(CreateItemParams params) {
    return _repository.create(
      title: params.title,
      description: params.description,
    );
  }
}

class CreateItemParams extends Equatable {
  const CreateItemParams({required this.title, this.description});

  final String title;
  final String? description;

  @override
  List<Object?> get props => [title, description];
}
