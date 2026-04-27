import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/datasources/hive_storage_service.dart';
import '../../../data/datasources/local_auth_service.dart';
import '../../../domain/entities/expense.dart';
import '../../widgets/expense_ui_data.dart';
import '../../widgets/expense_ui_widgets.dart';
import '../app/expense_ui_routes.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _storageService = const HiveStorageService();
  final _authService = const LocalAuthService(HiveStorageService());

  List<Expense> _expenses = const [];
  bool _isLoading = true;
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    final currentUser = _authService.getCurrentUser();
    final expenses = currentUser == null
        ? const <Expense>[]
        : _storageService.getExpensesByUserId(currentUser.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _expenses = expenses;
      _isLoading = false;
    });
  }

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

  Future<void> _handleCalendar(BuildContext context) async {
    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _selectedRange = selected;
    });
  }

  Future<void> _openAddExpense() async {
    final created = await context.push<bool>(ExpenseUiRoutes.addExpense);
    if (created == true) {
      await _loadExpenses();
    }
  }

  List<Expense> get _filteredExpenses {
    if (_selectedRange == null) {
      return _expenses;
    }

    final startDate = DateTime(
      _selectedRange!.start.year,
      _selectedRange!.start.month,
      _selectedRange!.start.day,
    );
    final endDate = DateTime(
      _selectedRange!.end.year,
      _selectedRange!.end.month,
      _selectedRange!.end.day,
    );

    return _expenses.where((expense) {
      final date =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      return !date.isBefore(startDate) && !date.isAfter(endDate);
    }).toList(growable: false);
  }

  double get _totalAmount => _filteredExpenses.fold<double>(
        0,
        (sum, expense) => sum + expense.amount,
      );

  List<ChartItem> get _chartEntries {
    if (_filteredExpenses.isEmpty) {
      return const [];
    }

    final totalsByCategory = <String, double>{};
    for (final expense in _filteredExpenses) {
      totalsByCategory.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final entries = totalsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.map((entry) {
      final filterItem = filterItems.cast<FilterItem?>().firstWhere(
            (item) => item?.label == entry.key,
            orElse: () => null,
          );
      final percent = math.max(
        1,
        ((entry.value / _totalAmount) * 100).round(),
      );

      return ChartItem(
        entry.key,
        percent,
        '${entry.value.toStringAsFixed(0)} ₸',
        filterItem?.color ?? const Color(0xFFB7BBC8),
      );
    }).toList(growable: false);
  }

  String get _periodLabel {
    if (_selectedRange == null) {
      return 'Все время';
    }

    final start = _selectedRange!.start;
    final end = _selectedRange!.end;
    return '${start.day}.${start.month}.${start.year} - ${end.day}.${end.month}.${end.year}';
  }

  Widget _buildSummaryCard(BuildContext context) {
    final average = _filteredExpenses.isEmpty
        ? 0.0
        : _totalAmount / _filteredExpenses.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Потрачено всего',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    '${_totalAmount.toStringAsFixed(0)} ₸',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 34,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_periodLabel · ${_filteredExpenses.length} операций',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Средний расход: ${average.toStringAsFixed(0)} ₸',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              height: 48,
              width: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFF0EAFE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.show_chart_rounded,
                color: Color(0xFF8D6AF2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context) {
    if (_chartEntries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'Нет данных для построения статистики за выбранный период.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Расходы по категориям',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 48,
                      sectionsSpace: 0,
                      startDegreeOffset: -90,
                      sections: _chartEntries.map((item) {
                        return PieChartSectionData(
                          color: item.color,
                          value: item.percent.toDouble(),
                          showTitle: false,
                          radius: 22,
                        );
                      }).toList(growable: false),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_totalAmount.toStringAsFixed(0)} ₸',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFF252A39),
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text('Итого',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ..._chartEntries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ChartLegendTile(item: entry),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: PrimaryFab(
        onPressed: _openAddExpense,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AppBottomBar(
        currentIndex: 1,
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
                    const Spacer(),
                    Text(
                      'Статистика',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TopActionButton(
                      icon: Icons.calendar_today_outlined,
                      onPressed: () => _handleCalendar(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const StatsTabs(),
                const SizedBox(height: 18),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _buildSummaryCard(context),
                  const SizedBox(height: 18),
                  _buildChartCard(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
