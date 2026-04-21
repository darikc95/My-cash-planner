import 'package:go_router/go_router.dart';

import 'add_expense_screen.dart';
import 'filters_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'statistics_screen.dart';

abstract final class ExpenseUiRoutes {
  static const login = '/';
  static const home = '/home';
  static const register = '/register';
  static const addExpense = '/add-expense';
  static const statistics = '/statistics';
  static const filters = '/filters';
}

final GoRouter expenseUiRouter = GoRouter(
  initialLocation: ExpenseUiRoutes.login,
  routes: [
    GoRoute(
      path: ExpenseUiRoutes.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: ExpenseUiRoutes.home,
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: ExpenseUiRoutes.register,
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: ExpenseUiRoutes.addExpense,
      builder: (_, __) => const AddExpenseScreen(),
    ),
    GoRoute(
      path: ExpenseUiRoutes.statistics,
      builder: (_, __) => const StatisticsScreen(),
    ),
    GoRoute(
      path: ExpenseUiRoutes.filters,
      builder: (_, __) => const FiltersScreen(),
    ),
  ],
);
