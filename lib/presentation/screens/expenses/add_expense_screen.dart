import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/datasources/hive_storage_service.dart';
import '../../../data/datasources/local_auth_service.dart';
import '../../../domain/entities/expense.dart';
import '../../widgets/expense_ui_data.dart';
import '../../widgets/expense_ui_widgets.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

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

  static final Map<String, IconData> _iconByCategory = {
    for (final item in filterItems) item.label: item.icon,
  };

  List<String> get _categories =>
      filterItems.map((item) => item.label).toList(growable: false);

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

    if (!mounted || selected == null) {
      return;
    }

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

    setState(() {
      _isSaving = true;
    });

    final description = _descriptionController.text.trim();
    final expense = Expense(
      id: 'expense_${DateTime.now().microsecondsSinceEpoch}',
      userId: currentUser.id,
      title: _selectedCategory!,
      amount: amount,
      category: _selectedCategory!,
      date: _selectedDate,
      note: description.isEmpty ? null : description,
      iconCodePoint: _iconByCategory[_selectedCategory!]?.codePoint,
    );

    await _storageService.saveExpense(expense);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    _showMessage('Расход сохранён.');
    context.pop(true);
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

  @override
  Widget build(BuildContext context) {
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
                        'Добавить расход',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(
                              hintText: 'Выберите категорию',
                            ),
                            items: _categories
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
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
                          minLines: 4,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            hintText: 'Напишите, на что потратили деньги',
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
                      backgroundColor: const Color(0xFF6C45E3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child:
                        Text(_isSaving ? 'Сохраняем...' : 'Сохранить расход'),
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
