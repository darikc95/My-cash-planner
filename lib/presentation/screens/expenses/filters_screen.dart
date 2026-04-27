import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/expense_ui_data.dart';
import '../../widgets/expense_ui_widgets.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({
    super.key,
    this.initialSelectedCategories,
    this.initialStartDate,
    this.initialEndDate,
  });

  final List<String>? initialSelectedCategories;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late Set<String> _selectedCategories;
  DateTime? _startDate;
  DateTime? _endDate;

  List<FilterItem> get _items => filterItems;

  @override
  void initState() {
    super.initState();
    _selectedCategories = widget.initialSelectedCategories == null ||
            widget.initialSelectedCategories!.isEmpty
        ? _items.map((item) => item.label).toSet()
        : widget.initialSelectedCategories!.toSet();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  void _handleReset() {
    setState(() {
      _selectedCategories = _items.map((item) => item.label).toSet();
      _startDate = null;
      _endDate = null;
    });
  }

  void _handleApply() {
    context.pop(<String, dynamic>{
      'categories': _selectedCategories.toList(growable: false),
      'startDate': _startDate,
      'endDate': _endDate,
    });
  }

  Future<void> _pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _startDate = selected;
      if (_endDate != null && _endDate!.isBefore(selected)) {
        _endDate = selected;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _endDate = selected;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Не выбран';
    }

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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TopActionButton(
                        icon: Icons.close_rounded,
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                      Text(
                        'Фильтры',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _handleReset,
                        child: const Text('Сброс'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Категории',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView(
                      children: [
                        ..._items.map((item) {
                          final isSelected =
                              _selectedCategories.contains(item.label);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    height: 36,
                                    width: 36,
                                    decoration: BoxDecoration(
                                      color: item.color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      item.icon,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedCategories.add(item.label);
                                        } else {
                                          _selectedCategories
                                              .remove(item.label);
                                        }
                                      });
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    activeColor: const Color(0xFF6C45E3),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                        Text(
                          'Период',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 14),
                        Card(
                          child: ListTile(
                            onTap: _pickStartDate,
                            title: const Text('С'),
                            subtitle: Text(_formatDate(_startDate)),
                            trailing: const Icon(Icons.calendar_month_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: ListTile(
                            onTap: _pickEndDate,
                            title: const Text('По'),
                            subtitle: Text(_formatDate(_endDate)),
                            trailing: const Icon(Icons.calendar_month_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _handleApply,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: const Color(0xFF6C45E3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Применить фильтры'),
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
