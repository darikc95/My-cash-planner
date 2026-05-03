import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../application/planner_facade.dart';
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
  final _planner = PlannerFacade.instance;

  List<Expense> _expenses = const [];
  bool _isLoading = true;
  DateTimeRange? _selectedRange;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    final currentUser = _planner.getCurrentUser();
    final expenses = currentUser == null
        ? const <Expense>[]
        : _planner.getExpensesByUserId(currentUser.id);

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

  double get _totalAmount => _filteredExpenses
      .where((e) => !e.isIncome)
      .fold<double>(0, (sum, e) => sum + e.amount);

  double get _totalIncome => _filteredExpenses
      .where((e) => e.isIncome)
      .fold<double>(0, (sum, e) => sum + e.amount);

  List<Expense> get _onlyExpenses =>
      _filteredExpenses.where((e) => !e.isIncome).toList(growable: false);

  Color _getCategoryColor(String category) {
    final userId = _planner.getCurrentUser()?.id;
    if (userId != null) {
      final cats = _planner.getUserCategories(userId);
      final cat = cats.cast<Map<String, dynamic>?>().firstWhere(
            (c) => c?['name'] == category,
            orElse: () => null,
          );
      if (cat != null) {
        return Color(cat['colorValue'] as int);
      }
    }
    final match = filterItems.cast<FilterItem?>().firstWhere(
          (item) => item?.label == category,
          orElse: () => null,
        );
    if (match != null) {
      return match.color;
    }
    return const Color(0xFFB7BBC8);
  }

  List<ChartItem> get _chartEntries {
    final expensesOnly = _onlyExpenses;
    if (expensesOnly.isEmpty) {
      return const [];
    }

    final totalsByCategory = <String, double>{};
    for (final expense in expensesOnly) {
      totalsByCategory.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final entries = totalsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = _totalAmount;

    return entries.map((entry) {
      final percent = math.max(
        1,
        ((entry.value / (total == 0 ? 1 : total)) * 100).round(),
      );

      return ChartItem(
        entry.key,
        percent,
        '${entry.value.toStringAsFixed(0)} ₸',
        _getCategoryColor(entry.key),
      );
    }).toList(growable: false);
  }

  /// Группирует расходы по месяцам для вкладки Тренды
  List<_MonthlyData> get _monthlyExpenses {
    final expensesOnly = _onlyExpenses;
    final incomeOnly = _filteredExpenses.where((e) => e.isIncome).toList();

    final expMap = <String, double>{};
    final incMap = <String, double>{};

    void process(List<Expense> items, Map<String, double> target) {
      for (final e in items) {
        final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
        target.update(key, (v) => v + e.amount, ifAbsent: () => e.amount);
      }
    }

    process(expensesOnly, expMap);
    process(incomeOnly, incMap);

    final allKeys = <String>{...expMap.keys, ...incMap.keys}.toList()..sort();

    return allKeys.map((key) {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      return _MonthlyData(
        label: _monthLabel(month, year),
        expenses: expMap[key] ?? 0,
        income: incMap[key] ?? 0,
      );
    }).toList();
  }

  static String _monthLabel(int month, int year) {
    const names = [
      'Янв',
      'Фев',
      'Мар',
      'Апр',
      'Май',
      'Июн',
      'Июл',
      'Авг',
      'Сен',
      'Окт',
      'Ноя',
      'Дек',
    ];
    return '${names[month - 1]} $year';
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
    final expCount = _onlyExpenses.length;
    final average = expCount == 0 ? 0.0 : _totalAmount / expCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Расходы',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${_totalAmount.toStringAsFixed(0)} ₸',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 30),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Доходы',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${_totalIncome.toStringAsFixed(0)} ₸',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontSize: 30,
                              color: const Color(0xFF1DB954),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$_periodLabel · $expCount операций',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Средний расход: ${average.toStringAsFixed(0)} ₸',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
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

  Widget _buildCategoriesTab(BuildContext context) {
    final entries = _chartEntries;
    if (entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'Нет расходов за выбранный период.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final maxAmount = entries
        .map((e) =>
            double.tryParse(
              e.amount.replaceAll(' ₸', '').replaceAll(' ', ''),
            ) ??
            0)
        .fold(0.0, math.max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'По категориям',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            ...entries.map((entry) {
              final amt = double.tryParse(
                    entry.amount.replaceAll(' ₸', '').replaceAll(' ', ''),
                  ) ??
                  0;
              final fraction = maxAmount == 0 ? 0.0 : amt / maxAmount;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: entry.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.label,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          entry.amount,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.percent}%',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: entry.color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 8,
                        backgroundColor: entry.color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(entry.color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsTab(BuildContext context) {
    final monthly = _monthlyExpenses;

    if (monthly.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'Нет данных для построения трендов.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final maxVal = monthly.fold<double>(
      0,
      (m, d) => math.max(m, math.max(d.expenses, d.income)),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Тренды по месяцам',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Row(
              children: [
                _LegendDot(color: Color(0xFFE05454), label: 'Расходы'),
                SizedBox(width: 16),
                _LegendDot(color: Color(0xFF1DB954), label: 'Доходы'),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (monthly.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxVal * 1.1,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}к',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6F7486),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= monthly.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              monthly[idx].label,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF6F7486),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        monthly.length,
                        (i) => FlSpot(i.toDouble(), monthly[i].expenses),
                      ),
                      isCurved: true,
                      color: const Color(0xFFE05454),
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFFE05454).withValues(alpha: 0.12),
                      ),
                    ),
                    LineChartBarData(
                      spots: List.generate(
                        monthly.length,
                        (i) => FlSpot(i.toDouble(), monthly[i].income),
                      ),
                      isCurved: true,
                      color: const Color(0xFF1DB954),
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF1DB954).withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...monthly.map((m) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        m.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '−${m.expenses.toStringAsFixed(0)} ₸',
                      style: const TextStyle(
                        color: Color(0xFFE05454),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '+${m.income.toStringAsFixed(0)} ₸',
                      style: const TextStyle(
                        color: Color(0xFF1DB954),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
                StatsTabs(
                  selectedIndex: _selectedTab,
                  onTap: (i) => setState(() => _selectedTab = i),
                ),
                const SizedBox(height: 18),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_selectedTab == 0) ...[
                  _buildSummaryCard(context),
                  const SizedBox(height: 18),
                  _buildChartCard(context),
                ] else if (_selectedTab == 1) ...[
                  _buildCategoriesTab(context),
                ] else if (_selectedTab == 2) ...[
                  _buildTrendsTab(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthlyData {
  const _MonthlyData({
    required this.label,
    required this.expenses,
    required this.income,
  });

  final String label;
  final double expenses;
  final double income;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
