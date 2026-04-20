// Слой: presentation | Назначение: главный экран — список Items с поиском и фильтром

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/item.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/item/item_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ItemBloc>().add(const ItemLoaded());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новый элемент'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Название'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Описание (опционально)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                context.read<ItemBloc>().add(
                      ItemCreated(
                        title: titleController.text.trim(),
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                      ),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои элементы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Аналитика',
            onPressed: () => context.push(AppConstants.routeAnalytics),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Выйти',
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Поиск...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      context.read<ItemBloc>().add(const ItemLoaded());
                    },
                  ),
              ],
              onChanged: (query) {
                if (query.isEmpty) {
                  context.read<ItemBloc>().add(const ItemLoaded());
                } else {
                  context.read<ItemBloc>().add(ItemSearched(query));
                }
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Фильтр по статусу
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Все'),
                  selected: true,
                  onSelected: (_) =>
                      context.read<ItemBloc>().add(const ItemLoaded()),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Активные'),
                  selected: false,
                  onSelected: (_) => context
                      .read<ItemBloc>()
                      .add(const ItemFiltered(ItemStatus.active)),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Архив'),
                  selected: false,
                  onSelected: (_) => context
                      .read<ItemBloc>()
                      .add(const ItemFiltered(ItemStatus.archived)),
                ),
              ],
            ),
          ),
          // Список элементов
          Expanded(
            child: BlocBuilder<ItemBloc, ItemState>(
              builder: (context, state) {
                if (state is ItemLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ItemFailure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 12),
                        Text(state.message),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () =>
                              context.read<ItemBloc>().add(const ItemLoaded()),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ItemSuccess) {
                  if (state.items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Список пуст',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return _ItemCard(
                        item: item,
                        onDelete: () => context
                            .read<ItemBloc>()
                            .add(ItemDeleted(item.id)),
                        onToggleStatus: () {
                          final newStatus = item.status == ItemStatus.active
                              ? ItemStatus.archived
                              : ItemStatus.active;
                          context.read<ItemBloc>().add(
                                ItemUpdated(item.copyWith(status: newStatus)),
                              );
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.onDelete,
    required this.onToggleStatus,
  });

  final Item item;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final isArchived = item.status == ItemStatus.archived;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isArchived ? Icons.archive_rounded : Icons.check_circle_outline,
          color: isArchived
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          item.title,
          style: isArchived
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: item.description != null ? Text(item.description!) : null,
        trailing: PopupMenuButton<String>(
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'toggle',
              child: Text(isArchived ? 'Восстановить' : 'В архив'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Удалить'),
            ),
          ],
          onSelected: (value) {
            if (value == 'toggle') onToggleStatus();
            if (value == 'delete') onDelete();
          },
        ),
      ),
    );
  }
}
