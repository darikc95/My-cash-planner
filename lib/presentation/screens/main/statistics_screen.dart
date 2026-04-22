import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/expense_ui_data.dart';
import '../../widgets/expense_ui_widgets.dart';
import '../app/expense_ui_routes.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

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

  void _handleCalendar(BuildContext context) {
    showFeatureStub(context, 'Выбор периода статистики');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: PrimaryFab(
        onPressed: () => context.push(ExpenseUiRoutes.addExpense),
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
                const SummaryCard(),
                const SizedBox(height: 18),
                Card(
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
                        const SizedBox(
                          height: 220,
                          child: CategoryChart(),
                        ),
                        const SizedBox(height: 14),
                        ...chartItems.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ChartLegendTile(item: entry),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
