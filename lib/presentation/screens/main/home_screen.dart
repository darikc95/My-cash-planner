import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/expense_ui_data.dart';
import '../../widgets/expense_ui_widgets.dart';
import '../app/expense_ui_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

  void _handleNotifications(BuildContext context) {
    showFeatureStub(context, 'Уведомления');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: PrimaryFab(
        onPressed: () => context.push(ExpenseUiRoutes.addExpense),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AppBottomBar(
        currentIndex: 0,
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
                    const Icon(Icons.menu_rounded, size: 24),
                    const SizedBox(width: 14),
                    Text(
                      'Мои расходы',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TopActionButton(
                      icon: Icons.notifications_none_rounded,
                      onPressed: () => _handleNotifications(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const BalanceCard(),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Text(
                      'Последние операции',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    TopActionButton(
                      icon: Icons.tune_rounded,
                      onPressed: () {
                        context.push(ExpenseUiRoutes.filters);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...transactions.map((transaction) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TransactionTile(item: transaction),
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
