import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../application/planner_facade.dart';
import '../../../core/utils/icon_utils.dart';
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
  final _planner = PlannerFacade.instance;

  late Set<String> _selectedCategories;
  DateTime? _startDate;
  DateTime? _endDate;

  List<_CombinedCategory> get _allCategories {
    final combined = <_CombinedCategory>[];

    final userCatsMap = <String, Map<String, dynamic>>{};
    final userId = _planner.getCurrentUser()?.id;
    if (userId != null) {
      final userCats = _planner.getUserCategories(userId);
      for (final cat in userCats) {
        userCatsMap[cat['name'] as String] = cat;
      }
    }

    for (final item in filterItems) {
      final userVersion = userCatsMap[item.label];
      if (userVersion != null) {
        combined.add(_CombinedCategory(
          label: item.label,
          icon: createMaterialIcon(userVersion['iconCodePoint'] as int),
          color: Color(userVersion['colorValue'] as int),
        ));
      } else {
        combined.add(_CombinedCategory(
          label: item.label,
          icon: item.icon,
          color: item.color,
        ));
      }
    }

    for (final entry in userCatsMap.entries) {
      if (!filterItems.any((item) => item.label == entry.key)) {
        combined.add(_CombinedCategory(
          label: entry.key,
          icon: createMaterialIcon(entry.value['iconCodePoint'] as int),
          color: Color(entry.value['colorValue'] as int),
        ));
      }
    }

    return combined;
  }

  @override
  void initState() {
    super.initState();
    final defaultLabels = filterItems.map((item) => item.label).toSet();
    _selectedCategories = widget.initialSelectedCategories == null ||
            widget.initialSelectedCategories!.isEmpty
        ? defaultLabels
        : widget.initialSelectedCategories!.toSet();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  void _handleReset() {
    setState(() {
      _selectedCategories = filterItems.map((item) => item.label).toSet();
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
                        ..._allCategories.map((cat) {
                          final isSelected =
                              _selectedCategories.contains(cat.label);

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
                                      color: cat.color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      cat.icon,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      cat.label,
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedCategories.add(cat.label);
                                        } else {
                                          _selectedCategories.remove(cat.label);
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

class _CombinedCategory {
  const _CombinedCategory({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
