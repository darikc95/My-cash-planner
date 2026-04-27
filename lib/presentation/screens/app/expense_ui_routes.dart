import 'package:go_router/go_router.dart';

import '../../../data/datasources/hive_storage_service.dart';
import '../../../data/datasources/local_auth_service.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/filters_screen.dart';
import '../main/categories_screen.dart';
import '../main/home_screen.dart';
import '../main/profile_screen.dart';
import '../main/statistics_screen.dart';

abstract final class ExpenseUiRoutes {
  static const login = '/';
  static const home = '/home';
  static const register = '/register';
  static const addExpense = '/add-expense';
  static const statistics = '/statistics';
  static const categories = '/categories';
  static const profile = '/profile';
  static const filters = '/filters';
}

final GoRouter expenseUiRouter = GoRouter(
  initialLocation: ExpenseUiRoutes.login,
  redirect: (_, state) {
    const authService = LocalAuthService(HiveStorageService());
    final isAuthenticated = authService.isAuthenticated;
    final isAuthPage = state.matchedLocation == ExpenseUiRoutes.login ||
        state.matchedLocation == ExpenseUiRoutes.register;

    if (!isAuthenticated && !isAuthPage) {
      return ExpenseUiRoutes.login;
    }

    if (isAuthenticated && isAuthPage) {
      return ExpenseUiRoutes.home;
    }

    return null;
  },
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
      path: ExpenseUiRoutes.categories,
      builder: (_, __) => const CategoriesScreen(),
    ),
    GoRoute(
      path: ExpenseUiRoutes.profile,
      builder: (_, __) => const ProfileScreen(),
    ),
    GoRoute(
      path: ExpenseUiRoutes.filters,
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;

        return FiltersScreen(
          initialSelectedCategories: extra == null
              ? null
              : List<String>.from(
                  (extra['categories'] as List<dynamic>? ?? const []),
                ),
          initialStartDate: extra?['startDate'] as DateTime?,
          initialEndDate: extra?['endDate'] as DateTime?,
        );
      },
    ),
  ],
);
