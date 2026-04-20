// Тесты: ItemBloc — загрузка списка, создание записи, ошибка загрузки

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:template/domain/entities/item.dart';
import 'package:template/domain/repositories/item_repository.dart';
import 'package:template/domain/usecases/base_usecase.dart';
import 'package:template/domain/usecases/create_item_usecase.dart';
import 'package:template/domain/usecases/delete_item_usecase.dart';
import 'package:template/domain/usecases/get_all_items_usecase.dart';
import 'package:template/domain/usecases/search_items_usecase.dart';
import 'package:template/domain/usecases/update_item_usecase.dart';
import 'package:template/presentation/blocs/item/item_bloc.dart';

class MockItemRepository extends Mock implements ItemRepository {}

void main() {
  late MockItemRepository mockRepository;
  late GetAllItemsUseCase getAllItems;
  late CreateItemUseCase createItem;
  late UpdateItemUseCase updateItem;
  late DeleteItemUseCase deleteItem;
  late SearchItemsUseCase searchItems;

  final testItems = [
    Item(
      id: 1,
      title: 'Первый элемент',
      status: ItemStatus.active,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ),
    Item(
      id: 2,
      title: 'Второй элемент',
      status: ItemStatus.archived,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ),
  ];

  final newItem = Item(
    id: 3,
    title: 'Новый элемент',
    status: ItemStatus.active,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  setUp(() {
    mockRepository = MockItemRepository();
    getAllItems = GetAllItemsUseCase(mockRepository);
    createItem = CreateItemUseCase(mockRepository);
    updateItem = UpdateItemUseCase(mockRepository);
    deleteItem = DeleteItemUseCase(mockRepository);
    searchItems = SearchItemsUseCase(mockRepository);

    registerFallbackValue(
      Item(
        id: 0,
        title: '',
        status: ItemStatus.active,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
    );
  });

  ItemBloc buildBloc() => ItemBloc(
        getAllItemsUseCase: getAllItems,
        createItemUseCase: createItem,
        updateItemUseCase: updateItem,
        deleteItemUseCase: deleteItem,
        searchItemsUseCase: searchItems,
      );

  group('ItemBloc', () {
    test('начальное состояние — ItemInitial', () {
      expect(buildBloc().state, isA<ItemInitial>());
    });

    blocTest<ItemBloc, ItemState>(
      'успешная загрузка списка переходит в ItemSuccess',
      build: () {
        when(() => mockRepository.getAll()).thenAnswer((_) async => testItems);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ItemLoaded()),
      expect: () => [
        isA<ItemLoading>(),
        isA<ItemSuccess>(),
      ],
      verify: (bloc) {
        final state = bloc.state as ItemSuccess;
        expect(state.items.length, equals(2));
      },
    );

    blocTest<ItemBloc, ItemState>(
      'создание нового элемента и перезагрузка списка',
      build: () {
        when(
          () => mockRepository.create(
            title: 'Новый элемент',
            description: null,
          ),
        ).thenAnswer((_) async => newItem);
        when(() => mockRepository.getAll())
            .thenAnswer((_) async => [...testItems, newItem]);
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const ItemCreated(title: 'Новый элемент')),
      expect: () => [
        isA<ItemLoading>(),
        isA<ItemSuccess>(),
      ],
      verify: (bloc) {
        final state = bloc.state as ItemSuccess;
        expect(state.items.length, equals(3));
      },
    );

    blocTest<ItemBloc, ItemState>(
      'ошибка загрузки переходит в ItemFailure',
      build: () {
        when(() => mockRepository.getAll())
            .thenThrow(Exception('Ошибка базы данных'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ItemLoaded()),
      expect: () => [
        isA<ItemLoading>(),
        isA<ItemFailure>(),
      ],
      verify: (bloc) {
        final state = bloc.state as ItemFailure;
        expect(state.message, contains('Ошибка базы данных'));
      },
    );
  });
}
