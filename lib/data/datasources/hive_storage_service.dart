import 'dart:convert';

import 'package:hive/hive.dart';

import '../../core/constants/hive_box_names.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/user.dart';

class HiveStorageService {
  const HiveStorageService();

  Box<User> get _usersBox => Hive.box<User>(HiveBoxNames.users);
  Box<Expense> get _expensesBox => Hive.box<Expense>(HiveBoxNames.expenses);
  Box<dynamic> get _settingsBox => Hive.box<dynamic>(HiveBoxNames.settings);
  Box<dynamic> get _categoriesBox => Hive.box<dynamic>(HiveBoxNames.categories);

  Future<void> saveUser(User user) {
    return _usersBox.put(user.id, user);
  }

  User? getUserById(String userId) {
    return _usersBox.get(userId);
  }

  List<User> getAllUsers() {
    return _usersBox.values.toList(growable: false);
  }

  Future<void> deleteUser(String userId) {
    return _usersBox.delete(userId);
  }

  Future<void> clearUsers() {
    return _usersBox.clear();
  }

  Future<void> saveExpense(Expense expense) {
    return _expensesBox.put(expense.id, expense);
  }

  Expense? getExpenseById(String expenseId) {
    return _expensesBox.get(expenseId);
  }

  List<Expense> getAllExpenses() {
    final list = _expensesBox.values.toList(growable: false);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<Expense> getExpensesByUserId(String userId) {
    final list = _expensesBox.values
        .where((expense) => expense.userId == userId)
        .toList(growable: false);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> deleteExpense(String expenseId) {
    return _expensesBox.delete(expenseId);
  }

  Future<void> clearExpenses() {
    return _expensesBox.clear();
  }

  String _categoryKey(String userId) => 'categories.$userId';

  /// Returns saved expense categories as list of maps with keys:
  /// id, name, iconCodePoint, colorValue, isActive
  List<Map<String, dynamic>> getUserCategories(String userId) {
    final raw = _categoriesBox.get(_categoryKey(userId)) as String?;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveUserCategories(
    String userId,
    List<Map<String, dynamic>> categories,
  ) async {
    await _categoriesBox.put(_categoryKey(userId), jsonEncode(categories));
  }

  String _incomeCategoryKey(String userId) => 'categories_income.$userId';

  List<Map<String, dynamic>> getUserIncomeCategories(String userId) {
    final raw = _categoriesBox.get(_incomeCategoryKey(userId)) as String?;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveUserIncomeCategories(
    String userId,
    List<Map<String, dynamic>> categories,
  ) async {
    await _categoriesBox.put(
        _incomeCategoryKey(userId), jsonEncode(categories));
  }

  String _legacyBudgetKey(String userId) => 'budget_limit.$userId';

  String _budgetMonthKey(String userId, DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    return 'budget_limit.$userId.$year$month';
  }

  /// Returns budget limit for selected month.
  ///
  /// Priority:
  /// 1) Exact month value.
  /// 2) Latest previous month value.
  /// 3) Legacy non-monthly value (for backward compatibility).
  double? getUserBudgetLimit(String userId, {DateTime? month}) {
    final target = month ?? DateTime.now();

    final exactRaw = _settingsBox.get(_budgetMonthKey(userId, target));
    if (exactRaw is num) {
      return exactRaw.toDouble();
    }

    final prefix = 'budget_limit.$userId.';
    final targetYm = target.year * 100 + target.month;
    num? fallbackValue;
    var fallbackYm = -1;

    for (final key in _settingsBox.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;
      final ymPart = key.substring(prefix.length);
      if (ymPart.length != 6) continue;

      final ym = int.tryParse(ymPart);
      if (ym == null || ym > targetYm || ym < fallbackYm) continue;

      final raw = _settingsBox.get(key);
      if (raw is num) {
        fallbackYm = ym;
        fallbackValue = raw;
      }
    }

    if (fallbackValue != null) {
      return fallbackValue.toDouble();
    }

    final legacyRaw = _settingsBox.get(_legacyBudgetKey(userId));
    if (legacyRaw is num) {
      return legacyRaw.toDouble();
    }

    return null;
  }

  Future<void> saveUserBudgetLimit(
    String userId,
    double limit, {
    DateTime? month,
  }) {
    final target = month ?? DateTime.now();
    return _settingsBox.put(_budgetMonthKey(userId, target), limit);
  }

  Future<void> clearUserBudgetLimit(String userId, {DateTime? month}) {
    final target = month ?? DateTime.now();
    return _settingsBox.delete(_budgetMonthKey(userId, target));
  }

  String _currencyKey(String userId) => 'currencies.$userId';

  List<String> getUserCurrencies(String userId) {
    final raw = _settingsBox.get(_currencyKey(userId)) as String?;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<String>();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveUserCurrencies(String userId, List<String> symbols) {
    return _settingsBox.put(_currencyKey(userId), jsonEncode(symbols));
  }

  String _avatarKey(String userId) => 'avatar.$userId';

  int getUserAvatarIndex(String userId) {
    return (_settingsBox.get(_avatarKey(userId)) as int?) ?? 0;
  }

  Future<void> saveUserAvatarIndex(String userId, int index) {
    return _settingsBox.put(_avatarKey(userId), index);
  }

  String _themeModeKey([String? userId]) {
    if (userId == null || userId.isEmpty) return 'theme_mode';
    return 'theme_mode.$userId';
  }

  /// Returns 'light' or 'dark'.
  ///
  /// For user-specific preference falls back to global theme_mode.
  String getUserThemeMode({String? userId}) {
    final userRaw = _settingsBox.get(_themeModeKey(userId));
    if (userRaw is String && (userRaw == 'light' || userRaw == 'dark')) {
      return userRaw;
    }

    final globalRaw = _settingsBox.get(_themeModeKey());
    if (globalRaw is String && (globalRaw == 'light' || globalRaw == 'dark')) {
      return globalRaw;
    }

    return 'light';
  }

  Future<void> saveUserThemeMode(String mode, {String? userId}) {
    final normalized = mode == 'dark' ? 'dark' : 'light';
    return _settingsBox.put(_themeModeKey(userId), normalized);
  }

  String _budgetAlertsKey([String? userId]) {
    if (userId == null || userId.isEmpty) {
      return 'settings.notifications.budget';
    }
    return 'settings.notifications.budget.$userId';
  }

  bool getUserBudgetAlertsEnabled({String? userId}) {
    final userRaw = _settingsBox.get(_budgetAlertsKey(userId));
    if (userRaw is bool) return userRaw;

    final legacyRaw = _settingsBox.get(_budgetAlertsKey());
    if (legacyRaw is bool) return legacyRaw;

    return true;
  }

  Future<void> saveUserBudgetAlertsEnabled(
    bool enabled, {
    String? userId,
  }) {
    return _settingsBox.put(_budgetAlertsKey(userId), enabled);
  }

  String _pushNotificationsKey([String? userId]) {
    if (userId == null || userId.isEmpty) {
      return 'settings.notifications.push';
    }
    return 'settings.notifications.push.$userId';
  }

  bool getUserPushNotificationsEnabled({String? userId}) {
    final userRaw = _settingsBox.get(_pushNotificationsKey(userId));
    if (userRaw is bool) return userRaw;

    final legacyRaw = _settingsBox.get(_pushNotificationsKey());
    if (legacyRaw is bool) return legacyRaw;

    return true;
  }

  Future<void> saveUserPushNotificationsEnabled(
    bool enabled, {
    String? userId,
  }) {
    return _settingsBox.put(_pushNotificationsKey(userId), enabled);
  }
}
