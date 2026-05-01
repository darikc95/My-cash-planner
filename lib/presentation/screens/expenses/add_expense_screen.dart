import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/local_notifications_service.dart';
import '../../../data/datasources/hive_storage_service.dart';
import '../../../data/datasources/local_auth_service.dart';
import '../../../domain/entities/expense.dart';
import '../../widgets/expense_ui_data.dart';
import '../../widgets/expense_ui_widgets.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? editExpense;

  const AddExpenseScreen({super.key, this.editExpense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _storageService = const HiveStorageService();
  final _authService = const LocalAuthService(HiveStorageService());

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isIncome = false;

  List<_CatEntry> _categories = const [];

  @override
  void initState() {
    super.initState();
    final edit = widget.editExpense;
    if (edit != null) {
      _amountController.text = edit.amount.toStringAsFixed(0);
      _descriptionController.text = edit.note ?? '';
      _selectedCategory = edit.category;
      _selectedDate = edit.date;
      _isIncome = edit.isIncome;
    }
    _loadCategories();
  }

  void _loadCategories() {
    final userId = _authService.getCurrentUser()?.id;
    final List<_CatEntry> entries;
    if (userId != null) {
      final saved = _isIncome
          ? _storageService.getUserIncomeCategories(userId)
          : _storageService.getUserCategories(userId);
      if (saved.isNotEmpty) {
        entries = saved
            .where((m) => (m['isActive'] as bool?) != false)
            .map(
              (m) => _CatEntry(
                name: m['name'] as String,
                icon: IconData(
                  m['iconCodePoint'] as int,
                  fontFamily: 'MaterialIcons',
                ),
                color: Color(m['colorValue'] as int),
              ),
            )
            .toList();
      } else {
        entries = _isIncome
            ? filterIncomeItems
                .map((f) =>
                    _CatEntry(name: f.label, icon: f.icon, color: f.color))
                .toList()
            : filterItems
                .map((f) =>
                    _CatEntry(name: f.label, icon: f.icon, color: f.color))
                .toList();
      }
    } else {
      entries = _isIncome
          ? filterIncomeItems
              .map(
                  (f) => _CatEntry(name: f.label, icon: f.icon, color: f.color))
              .toList()
          : filterItems
              .map(
                  (f) => _CatEntry(name: f.label, icon: f.icon, color: f.color))
              .toList();
    }
    setState(() {
      _categories = entries;
      // При смене типа сбрасываем выбор, если старая категория не подходит
      if (_selectedCategory == null ||
          !entries.any((c) => c.name == _selectedCategory)) {
        _selectedCategory = entries.isNotEmpty ? entries.first.name : null;
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (!mounted || selected == null) return;

    setState(() {
      _selectedDate = selected;
    });
  }

  Future<void> _saveExpense() async {
    FocusScope.of(context).unfocus();

    final currentUser = _authService.getCurrentUser();
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(' ', '').replaceAll(',', '.'),
    );

    if (currentUser == null) {
      _showMessage('Сессия не найдена. Войдите заново.');
      return;
    }

    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      _showMessage('Выберите категорию.');
      return;
    }

    if (amount == null || amount <= 0) {
      _showMessage('Введите корректную сумму.');
      return;
    }

    setState(() => _isSaving = true);

    final catEntry = _categories
        .cast<_CatEntry?>()
        .firstWhere((c) => c?.name == _selectedCategory, orElse: () => null);
    final description = _descriptionController.text.trim();

    final editId = widget.editExpense?.id;

    try {
      final expense = Expense(
        id: editId ?? 'expense_${DateTime.now().microsecondsSinceEpoch}',
        userId: currentUser.id,
        title: _selectedCategory!,
        amount: amount,
        category: _selectedCategory!,
        date: _selectedDate,
        note: description.isEmpty ? null : description,
        iconCodePoint: catEntry?.icon.codePoint,
        isIncome: _isIncome,
      );

      await _storageService.saveExpense(expense);

      // Сразу снимаем состояние сохранения: уведомления не должны блокировать UI.
      if (mounted) {
        setState(() => _isSaving = false);
      }

      // Check budget limit for month of operation
      if (!_isIncome) {
        final budgetAlertsEnabled =
            _storageService.getUserBudgetAlertsEnabled(userId: currentUser.id);

        if (budgetAlertsEnabled) {
          final budgetMonth = DateTime(_selectedDate.year, _selectedDate.month);
          final limit = _storageService.getUserBudgetLimit(currentUser.id,
              month: budgetMonth);
          if (limit != null && limit > 0 && mounted) {
            final monthExpenses = _storageService
                .getExpensesByUserId(currentUser.id)
                .where(
                  (e) =>
                      !e.isIncome &&
                      e.date.year == budgetMonth.year &&
                      e.date.month == budgetMonth.month,
                )
                .fold<double>(0, (s, e) => s + e.amount);
            if (monthExpenses >= limit) {
              final pushEnabled =
                  _storageService.getUserPushNotificationsEnabled(
                userId: currentUser.id,
              );
              if (pushEnabled) {
                try {
                  await LocalNotificationsService.instance
                      .showBudgetLimitReached(
                        total: monthExpenses,
                        limit: limit,
                        month: budgetMonth,
                      )
                      .timeout(const Duration(seconds: 2));
                } catch (_) {
                  // Не блокируем сохранение, если уведомление не отправилось.
                }
              }
              await _showBudgetAlert(monthExpenses, limit, budgetMonth);
            }
          }
        }
      }

      if (!mounted) return;

      _showMessage(
          editId != null ? 'Операция обновлена.' : 'Операция сохранена.');
      context.pop(true);
    } catch (_) {
      if (!mounted) return;
      if (_isSaving) {
        setState(() => _isSaving = false);
      }
      _showMessage('Не удалось сохранить операцию. Попробуйте снова.');
    }
  }

  Future<void> _showBudgetAlert(
    double total,
    double limit,
    DateTime month,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('⚠️ Превышен лимит бюджета'),
        content: Text(
          'Расходы за ${_formatMonthYear(month)} составляют '
          '${total.toStringAsFixed(0)} ₸, что превышает лимит '
          '${limit.toStringAsFixed(0)} ₸.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    const months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'январь',
      'февраль',
      'март',
      'апрель',
      'май',
      'июнь',
      'июль',
      'август',
      'сентябрь',
      'октябрь',
      'ноябрь',
      'декабрь',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editExpense != null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TopActionButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? 'Редактировать' : 'Новая операция',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Income / Expense toggle
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TypeButton(
                              label: 'Расход',
                              icon: Icons.arrow_upward_rounded,
                              color: const Color(0xFFFF5F67),
                              selected: !_isIncome,
                              onTap: () {
                                _isIncome = false;
                                _selectedCategory = null;
                                _loadCategories();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TypeButton(
                              label: 'Доход',
                              icon: Icons.arrow_downward_rounded,
                              color: const Color(0xFF1DB954),
                              selected: _isIncome,
                              onTap: () {
                                _isIncome = true;
                                _selectedCategory = null;
                                _loadCategories();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Сумма',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Например, 5000',
                              suffixText: '₸',
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontSize: 34),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Категория',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _categories
                                    .any((c) => c.name == _selectedCategory)
                                ? _selectedCategory
                                : null,
                            decoration: const InputDecoration(
                              hintText: 'Выберите категорию',
                            ),
                            items: _categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.name,
                                    child: Row(
                                      children: [
                                        Icon(c.icon, color: c.color, size: 20),
                                        const SizedBox(width: 8),
                                        Text(c.name),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      onTap: _pickDate,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: const Text('Дата'),
                      subtitle: Text(_formatDate(_selectedDate)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DescriptionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Описание',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _descriptionController,
                          minLines: 3,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            hintText: 'Напишите заметку к операции',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveExpense,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: _isIncome
                          ? const Color(0xFF1DB954)
                          : const Color(0xFF6C45E3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      _isSaving
                          ? 'Сохраняем...'
                          : (isEdit
                              ? 'Обновить'
                              : (_isIncome
                                  ? 'Сохранить доход'
                                  : 'Сохранить расход')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : const Color(0xFFE5E7EB),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: selected ? color : const Color(0xFF9AA0B4), size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: selected ? color : const Color(0xFF9AA0B4),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatEntry {
  const _CatEntry({
    required this.name,
    required this.icon,
    required this.color,
  });

  final String name;
  final IconData icon;
  final Color color;
}
