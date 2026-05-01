import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/datasources/hive_storage_service.dart';
import '../../../data/datasources/local_auth_service.dart';
import '../../widgets/expense_ui_data.dart';
import '../../widgets/expense_ui_widgets.dart';
import '../app/expense_ui_routes.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  final _storageService = const HiveStorageService();
  final _authService = const LocalAuthService(HiveStorageService());

  late TabController _tabController;
  late List<_CategoryItem> _expenseCategories;
  late List<_CategoryItem> _incomeCategories;

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
    _tabController = TabController(length: 2, vsync: this);
    _expenseCategories = [];
    _incomeCategories = [];
    _loadExpenseCategories();
    _loadIncomeCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Expense categories ───────────────────────────────────────────────────

  void _loadExpenseCategories() {
    final userId = _authService.getCurrentUser()?.id;
    if (userId == null) {
      _setDefaultExpenseCategories();
      return;
    }
    final saved = _storageService.getUserCategories(userId);
    if (saved.isEmpty) {
      _setDefaultExpenseCategories();
      _persistExpenseCategories();
    } else {
      setState(() {
        _expenseCategories = saved.map((m) {
          return _CategoryItem(
            id: m['id'] as String,
            name: m['name'] as String,
            icon: IconData(
              m['iconCodePoint'] as int,
              fontFamily: 'MaterialIcons',
            ),
            color: Color(m['colorValue'] as int),
            isActive: (m['isActive'] as bool?) ?? true,
          );
        }).toList();
      });
    }
  }

  void _setDefaultExpenseCategories() {
    setState(() {
      _expenseCategories = filterItems
          .asMap()
          .entries
          .map((entry) => _CategoryItem(
                id: 'category_${entry.key}',
                name: entry.value.label,
                icon: entry.value.icon,
                color: entry.value.color,
                isActive: entry.value.selected,
              ))
          .toList();
    });
  }

  Future<void> _persistExpenseCategories() async {
    final userId = _authService.getCurrentUser()?.id;
    if (userId == null) return;
    await _storageService.saveUserCategories(
      userId,
      _expenseCategories
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'iconCodePoint': c.icon.codePoint,
                'colorValue': c.color.toARGB32(),
                'isActive': c.isActive,
              })
          .toList(),
    );
  }

  // ─── Income categories ────────────────────────────────────────────────────

  void _loadIncomeCategories() {
    final userId = _authService.getCurrentUser()?.id;
    if (userId == null) {
      _setDefaultIncomeCategories();
      return;
    }
    final saved = _storageService.getUserIncomeCategories(userId);
    if (saved.isEmpty) {
      _setDefaultIncomeCategories();
      _persistIncomeCategories();
    } else {
      setState(() {
        _incomeCategories = saved.map((m) {
          return _CategoryItem(
            id: m['id'] as String,
            name: m['name'] as String,
            icon: IconData(
              m['iconCodePoint'] as int,
              fontFamily: 'MaterialIcons',
            ),
            color: Color(m['colorValue'] as int),
            isActive: (m['isActive'] as bool?) ?? true,
          );
        }).toList();
      });
    }
  }

  void _setDefaultIncomeCategories() {
    setState(() {
      _incomeCategories = filterIncomeItems
          .asMap()
          .entries
          .map((entry) => _CategoryItem(
                id: 'income_category_${entry.key}',
                name: entry.value.label,
                icon: entry.value.icon,
                color: entry.value.color,
                isActive: entry.value.selected,
              ))
          .toList();
    });
  }

  Future<void> _persistIncomeCategories() async {
    final userId = _authService.getCurrentUser()?.id;
    if (userId == null) return;
    await _storageService.saveUserIncomeCategories(
      userId,
      _incomeCategories
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'iconCodePoint': c.icon.codePoint,
                'colorValue': c.color.toARGB32(),
                'isActive': c.isActive,
              })
          .toList(),
    );
  }

  // ─── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> _createCategory() async {
    final isIncomeTab = _tabController.index == 1;
    final draft = await showDialog<_CategoryDraft>(
      context: context,
      builder: (_) => const _CategoryEditorDialog(
        title: 'Новая категория',
        actionLabel: 'Создать',
      ),
    );
    if (!mounted || draft == null) return;

    if (isIncomeTab) {
      setState(() {
        _incomeCategories = [
          ..._incomeCategories,
          _CategoryItem(
            id: 'income_category_${DateTime.now().millisecondsSinceEpoch}',
            name: draft.name,
            icon: draft.icon,
            color: draft.color,
            isActive: true,
          ),
        ];
      });
      await _persistIncomeCategories();
    } else {
      setState(() {
        _expenseCategories = [
          ..._expenseCategories,
          _CategoryItem(
            id: 'category_${DateTime.now().millisecondsSinceEpoch}',
            name: draft.name,
            icon: draft.icon,
            color: draft.color,
            isActive: true,
          ),
        ];
      });
      await _persistExpenseCategories();
    }
  }

  Future<void> _editCategory(
    _CategoryItem item, {
    required bool isIncome,
  }) async {
    final draft = await showDialog<_CategoryDraft>(
      context: context,
      builder: (_) => _CategoryEditorDialog(
        title: 'Редактировать категорию',
        actionLabel: 'Сохранить',
        initialName: item.name,
        initialIcon: item.icon,
        initialColor: item.color,
      ),
    );
    if (!mounted || draft == null) return;

    if (isIncome) {
      setState(() {
        _incomeCategories = _incomeCategories
            .map((c) => c.id == item.id
                ? c.copyWith(
                    name: draft.name, icon: draft.icon, color: draft.color)
                : c)
            .toList();
      });
      await _persistIncomeCategories();
    } else {
      setState(() {
        _expenseCategories = _expenseCategories
            .map((c) => c.id == item.id
                ? c.copyWith(
                    name: draft.name, icon: draft.icon, color: draft.color)
                : c)
            .toList();
      });
      await _persistExpenseCategories();
    }
  }

  Future<void> _deleteCategory(
    _CategoryItem item, {
    required bool isIncome,
  }) async {
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
    if (!mounted || shouldDelete != true) return;

    if (isIncome) {
      setState(() {
        _incomeCategories =
            _incomeCategories.where((c) => c.id != item.id).toList();
      });
      await _persistIncomeCategories();
    } else {
      setState(() {
        _expenseCategories =
            _expenseCategories.where((c) => c.id != item.id).toList();
      });
      await _persistExpenseCategories();
    }
  }

  void _toggleCategory(
    _CategoryItem item,
    bool value, {
    required bool isIncome,
  }) {
    if (isIncome) {
      setState(() {
        _incomeCategories = _incomeCategories
            .map((c) => c.id == item.id ? c.copyWith(isActive: value) : c)
            .toList();
      });
      _persistIncomeCategories();
    } else {
      setState(() {
        _expenseCategories = _expenseCategories
            .map((c) => c.id == item.id ? c.copyWith(isActive: value) : c)
            .toList();
      });
      _persistExpenseCategories();
    }
  }

  void _onMenuAction(
    _CategoryAction action,
    _CategoryItem item, {
    required bool isIncome,
  }) {
    switch (action) {
      case _CategoryAction.edit:
        _editCategory(item, isIncome: isIncome);
      case _CategoryAction.delete:
        _deleteCategory(item, isIncome: isIncome);
    }
  }

  Widget _buildCategoryList(
    List<_CategoryItem> items, {
    required bool isIncome,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: [
        if (items.isEmpty)
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
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CategoryStatusTile(
                item: item,
                onChanged: (value) =>
                    _toggleCategory(item, value, isIncome: isIncome),
                onAction: (action) =>
                    _onMenuAction(action, item, isIncome: isIncome),
              ),
            );
          }),
      ],
    );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 12),
                      TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'Расходы'),
                          Tab(text: 'Доходы'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCategoryList(
                        _expenseCategories,
                        isIncome: false,
                      ),
                      _buildCategoryList(
                        _incomeCategories,
                        isIncome: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
    this.initialColor,
  });

  final String title;
  final String actionLabel;
  final String? initialName;
  final IconData? initialIcon;
  final Color? initialColor;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _nameController;
  late IconData _selectedIcon;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedIcon = widget.initialIcon ?? _iconChoices.first;
    _selectedColor = widget.initialColor ?? _categoryPalette.first;
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
      _CategoryDraft(name: name, icon: _selectedIcon, color: _selectedColor),
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
            const SizedBox(height: 16),
            Text(
              'Цвет',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categoryPalette.map((color) {
                final isSelected = color == _selectedColor;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
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
  const _CategoryDraft({
    required this.name,
    required this.icon,
    required this.color,
  });

  final String name;
  final IconData icon;
  final Color color;
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
