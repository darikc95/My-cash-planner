// Слой: presentation | Назначение: события ItemBloc

part of 'item_bloc.dart';

abstract class ItemEvent extends Equatable {
  const ItemEvent();

  @override
  List<Object?> get props => [];
}

class ItemLoaded extends ItemEvent {
  const ItemLoaded();
}

class ItemCreated extends ItemEvent {
  const ItemCreated({required this.title, this.description});

  final String title;
  final String? description;

  @override
  List<Object?> get props => [title, description];
}

class ItemUpdated extends ItemEvent {
  const ItemUpdated(this.item);

  final Item item;

  @override
  List<Object?> get props => [item];
}

class ItemDeleted extends ItemEvent {
  const ItemDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class ItemSearched extends ItemEvent {
  const ItemSearched(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class ItemFiltered extends ItemEvent {
  const ItemFiltered(this.status);

  final ItemStatus status;

  @override
  List<Object?> get props => [status];
}
