// Слой: presentation | Назначение: состояния ItemBloc

part of 'item_bloc.dart';

abstract class ItemState extends Equatable {
  const ItemState();

  @override
  List<Object?> get props => [];
}

class ItemInitial extends ItemState {
  const ItemInitial();
}

class ItemLoading extends ItemState {
  const ItemLoading();
}

class ItemSuccess extends ItemState {
  const ItemSuccess(this.items);

  final List<Item> items;

  @override
  List<Object?> get props => [items];
}

class ItemFailure extends ItemState {
  const ItemFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
