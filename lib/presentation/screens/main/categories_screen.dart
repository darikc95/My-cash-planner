import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/expense_ui_data.dart';
import '../../widgets/expense_ui_widgets.dart';
import '../app/expense_ui_routes.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late List<_CategoryItem> _categories;

  void _handleBottomBarTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(ExpenseUiRoutes.home);
      case 1:
        context.go(ExpenseUiRoutes.statistics);
      case 2:
        context.go(ExpenseUiRoutes.categories);
      case 3:
        context.go(ExpenseUiRoutes.profile);
    }
  }

  @override
  void initState() {
    super.initState();
    _categories = filterItems
        .asMap()
        .entries
        .map(
          (entry) => _CategoryItem(
            id: 'category_${entry.key}',
            name: entry.value.label,
            icon: entry.value.icon,
            color: entry.value.color,
            isActive: entry.value.selected,
          ),
        )
        .toList();
  }

  Future<void> _createCategory() async {
    final draft = await showDialog<_CategoryDraft>(
      context: context,
      builder: (_) => const _CategoryEditorDialog(
        title: 'Новая категория',
        actionLabel: 'Создать',
      ),
    );

    if (!mounted || draft == null) {
      return;
    }

    setState(() {
      _categories = [
        ..._categories,
        _CategoryItem(
          id: 'category_${DateTime.now().millisecondsSinceEpoch}',
          name: draft.name,
          icon: draft.icon,
          color: _categoryPalette[_categories.length % _categoryPalette.length],
          isActive: true,
        ),
      ];
    });
  }

  Future<void> _editCategory(_CategoryItem item) async {
    final draft = await showDialog<_CategoryDraft>(
      context: context,
      builder: (_) => _CategoryEditorDialog(
        title: 'Редактировать категорию',
        actionLabel: 'Сохранить',
        initialName: item.name,
        initialIcon: item.icon,
      ),
    );

    if (!mounted || draft == null) {
      return;
    }

    setState(() {
      _categories = _categories
          .map(
            (category) => category.id == item.id
                ? category.copyWith(name: draft.name, icon: draft.icon)
                : category,
          )
          .toList();
    });
  }

  Future<void> _deleteCategory(_CategoryItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить категорию?'),
        content: Text('Категория "${item.name}" будет удалена.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (!mounted || shouldDelete != true) {
      return;
    }

    setState(() {
      _categories =
          _categories.where((category) => category.id != item.id).toList();
    });
  }

  void _toggleCategory(_CategoryItem item, bool value) {
    setState(() {
      _categories = _categories
          .map(
            (category) => category.id == item.id
                ? category.copyWith(isActive: value)
                : category,
          )
          .toList();
    });
  }

  void _onMenuAction(_CategoryAction action, _CategoryItem item) {
    switch (action) {
      case _CategoryAction.edit:
        _editCategory(item);
      case _CategoryAction.delete:
        _deleteCategory(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: PrimaryFab(
        onPressed: () => context.push(ExpenseUiRoutes.addExpense),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AppBottomBar(
        currentIndex: 2,
        onTap: (index) => _handleBottomBarTap(context, index),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
              children: [
                Row(
                  children: [
                    Text(
                      'Категории',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TopActionButton(
                      icon: Icons.add_rounded,
                      onPressed: _createCategory,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Настройте набор категорий для будущей логики',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (_categories.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'Список пуст. Добавьте первую категорию.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                else
                  ..._categories.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CategoryStatusTile(
                        item: item,
                        onChanged: (value) => _toggleCategory(item, value),
                        onAction: (action) => _onMenuAction(action, item),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryStatusTile extends StatelessWidget {
  const _CategoryStatusTile({
    required this.item,
    required this.onChanged,
    required this.onAction,
  });

  final _CategoryItem item;
  final ValueChanged<bool> onChanged;
  final ValueChanged<_CategoryAction> onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF252A39),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Switch(
              value: item.isActive,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFF6C45E3),
            ),
            PopupMenuButton<_CategoryAction>(
              onSelected: onAction,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _CategoryAction.edit,
                  child: Text('Редактировать'),
                ),
                PopupMenuItem(
                  value: _CategoryAction.delete,
                  child: Text('Удалить'),
                ),
              ],
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({
    required this.title,
    required this.actionLabel,
    this.initialName,
    this.initialIcon,
  });

  final String title;
  final String actionLabel;
  final String? initialName;
  final IconData? initialIcon;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _nameController;
  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedIcon = widget.initialIcon ?? _iconChoices.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _CategoryDraft(name: name, icon: _selectedIcon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Название категории',
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Иконка',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconChoices.map((icon) {
                final isSelected = icon == _selectedIcon;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEDE7FF)
                          : const Color(0xFFF5F5FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6C45E3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? const Color(0xFF6C45E3)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

enum _CategoryAction { edit, delete }

class _CategoryDraft {
  const _CategoryDraft({required this.name, required this.icon});

  final String name;
  final IconData icon;
}

class _CategoryItem {
  const _CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isActive,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isActive;

  _CategoryItem copyWith({
    String? name,
    IconData? icon,
    Color? color,
    bool? isActive,
  }) {
    return _CategoryItem(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
    );
  }
}

const _iconChoices = <IconData>[
  Icons.restaurant_rounded,
  Icons.directions_bus_rounded,
  Icons.shopping_bag_rounded,
  Icons.sports_esports_rounded,
  Icons.home_rounded,
  Icons.health_and_safety_rounded,
  Icons.school_rounded,
  Icons.savings_rounded,
  Icons.card_giftcard_rounded,
  Icons.local_hospital_rounded,
  Icons.phone_android_rounded,
  Icons.movie_rounded,
  Icons.pets_rounded,
  Icons.fitness_center_rounded,
  Icons.flight_rounded,
];

const _categoryPalette = <Color>[
  Color(0xFF4BCB72),
  Color(0xFF4A86F7),
  Color(0xFFFFBF33),
  Color(0xFF8D5CF6),
  Color(0xFFFF5E94),
  Color(0xFF00B8D4),
  Color(0xFFFF7A59),
  Color(0xFF6D9F71),
];
