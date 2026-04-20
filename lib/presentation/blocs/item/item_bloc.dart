// Слой: presentation | Назначение: ItemBloc — управление списком элементов

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/item.dart';
import '../../../domain/usecases/base_usecase.dart';
import '../../../domain/usecases/create_item_usecase.dart';
import '../../../domain/usecases/delete_item_usecase.dart';
import '../../../domain/usecases/get_all_items_usecase.dart';
import '../../../domain/usecases/search_items_usecase.dart';
import '../../../domain/usecases/update_item_usecase.dart';

part 'item_event.dart';
part 'item_state.dart';

class ItemBloc extends Bloc<ItemEvent, ItemState> {
  ItemBloc({
    required GetAllItemsUseCase getAllItemsUseCase,
    required CreateItemUseCase createItemUseCase,
    required UpdateItemUseCase updateItemUseCase,
    required DeleteItemUseCase deleteItemUseCase,
    required SearchItemsUseCase searchItemsUseCase,
  })  : _getAllItems = getAllItemsUseCase,
        _createItem = createItemUseCase,
        _updateItem = updateItemUseCase,
        _deleteItem = deleteItemUseCase,
        _searchItems = searchItemsUseCase,
        super(const ItemInitial()) {
    on<ItemLoaded>(_onItemLoaded);
    on<ItemCreated>(_onItemCreated);
    on<ItemUpdated>(_onItemUpdated);
    on<ItemDeleted>(_onItemDeleted);
    on<ItemSearched>(_onItemSearched);
    on<ItemFiltered>(_onItemFiltered);
  }

  final GetAllItemsUseCase _getAllItems;
  final CreateItemUseCase _createItem;
  final UpdateItemUseCase _updateItem;
  final DeleteItemUseCase _deleteItem;
  final SearchItemsUseCase _searchItems;

  Future<void> _onItemLoaded(ItemLoaded event, Emitter<ItemState> emit) async {
    emit(const ItemLoading());
    try {
      final items = await _getAllItems(const NoParams());
      emit(ItemSuccess(items));
    } catch (e) {
      emit(ItemFailure(e.toString()));
    }
  }

  Future<void> _onItemCreated(ItemCreated event, Emitter<ItemState> emit) async {
    try {
      await _createItem(
        CreateItemParams(title: event.title, description: event.description),
      );
      add(const ItemLoaded());
    } catch (e) {
      emit(ItemFailure(e.toString()));
    }
  }

  Future<void> _onItemUpdated(ItemUpdated event, Emitter<ItemState> emit) async {
    try {
      await _updateItem(event.item);
      add(const ItemLoaded());
    } catch (e) {
      emit(ItemFailure(e.toString()));
    }
  }

  Future<void> _onItemDeleted(ItemDeleted event, Emitter<ItemState> emit) async {
    try {
      await _deleteItem(event.id);
      add(const ItemLoaded());
    } catch (e) {
      emit(ItemFailure(e.toString()));
    }
  }

  Future<void> _onItemSearched(ItemSearched event, Emitter<ItemState> emit) async {
    emit(const ItemLoading());
    try {
      final items = await _searchItems(event.query);
      emit(ItemSuccess(items));
    } catch (e) {
      emit(ItemFailure(e.toString()));
    }
  }

  Future<void> _onItemFiltered(ItemFiltered event, Emitter<ItemState> emit) async {
    emit(const ItemLoading());
    try {
      final currentState = state;
      if (currentState is ItemSuccess) {
        final filtered = currentState.items
            .where((item) => item.status == event.status)
            .toList();
        emit(ItemSuccess(filtered));
      }
    } catch (e) {
      emit(ItemFailure(e.toString()));
    }
  }
}
