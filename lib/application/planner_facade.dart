import '../core/notifications/local_notifications_service.dart';
import '../data/datasources/hive_storage_service.dart';
import '../data/datasources/local_auth_service.dart';
import '../data/datasources/yahoo_finance_api_service.dart';
import '../data/models/finance_quote.dart';
import '../domain/entities/expense.dart';
import '../domain/entities/user.dart';
import '../domain/entities/auth_action_result.dart';

class PlannerFacade {
  PlannerFacade._();

  static final PlannerFacade instance = PlannerFacade._();

  final HiveStorageService _storage = const HiveStorageService();
  final LocalAuthService _auth = const LocalAuthService(HiveStorageService());
  final YahooFinanceApiService _finance = YahooFinanceApiService();

  User? getCurrentUser() => _auth.getCurrentUser();

  bool get isAuthenticated => _auth.isAuthenticated;

  Future<AuthActionResult> updateProfile({
    required String userId,
    required String name,
  }) {
    return _auth.updateProfile(userId: userId, name: name);
  }

  Future<AuthActionResult> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) {
    return _auth.changePassword(
      userId: userId,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<AuthActionResult> resetPassword({
    required String email,
    required String newPassword,
  }) {
    return _auth.resetPassword(email: email, newPassword: newPassword);
  }

  Future<void> logout() => _auth.logout();

  Future<void> saveExpense(Expense expense) => _storage.saveExpense(expense);

  Future<void> deleteExpense(String expenseId) =>
      _storage.deleteExpense(expenseId);

  List<Expense> getExpensesByUserId(String userId) =>
      _storage.getExpensesByUserId(userId);

  List<Map<String, dynamic>> getUserCategories(String userId) =>
      _storage.getUserCategories(userId);

  Future<void> saveUserCategories(
    String userId,
    List<Map<String, dynamic>> categories,
  ) {
    return _storage.saveUserCategories(userId, categories);
  }

  List<Map<String, dynamic>> getUserIncomeCategories(String userId) =>
      _storage.getUserIncomeCategories(userId);

  Future<void> saveUserIncomeCategories(
    String userId,
    List<Map<String, dynamic>> categories,
  ) {
    return _storage.saveUserIncomeCategories(userId, categories);
  }

  double? getUserBudgetLimit(String userId, {DateTime? month}) =>
      _storage.getUserBudgetLimit(userId, month: month);

  Future<void> saveUserBudgetLimit(String userId, double limit,
      {DateTime? month}) {
    return _storage.saveUserBudgetLimit(userId, limit, month: month);
  }

  Future<void> clearUserBudgetLimit(String userId, {DateTime? month}) {
    return _storage.clearUserBudgetLimit(userId, month: month);
  }

  List<String> getUserCurrencies(String userId) =>
      _storage.getUserCurrencies(userId);

  Future<void> saveUserCurrencies(String userId, List<String> symbols) {
    return _storage.saveUserCurrencies(userId, symbols);
  }

  int getUserAvatarIndex(String userId) => _storage.getUserAvatarIndex(userId);

  Future<void> saveUserAvatarIndex(String userId, int index) {
    return _storage.saveUserAvatarIndex(userId, index);
  }

  String getUserThemeMode({String? userId}) =>
      _storage.getUserThemeMode(userId: userId);

  Future<void> saveUserThemeMode(String mode, {String? userId}) {
    return _storage.saveUserThemeMode(mode, userId: userId);
  }

  bool getUserBudgetAlertsEnabled({String? userId}) =>
      _storage.getUserBudgetAlertsEnabled(userId: userId);

  Future<void> saveUserBudgetAlertsEnabled(bool enabled, {String? userId}) {
    return _storage.saveUserBudgetAlertsEnabled(enabled, userId: userId);
  }

  bool getUserPushNotificationsEnabled({String? userId}) =>
      _storage.getUserPushNotificationsEnabled(userId: userId);

  Future<void> saveUserPushNotificationsEnabled(bool enabled,
      {String? userId}) {
    return _storage.saveUserPushNotificationsEnabled(enabled, userId: userId);
  }

  Future<List<FinanceQuote>> fetchQuotes({
    List<String> symbols = const ['EURKZT=X', 'USDKZT=X', 'RUBKZT=X'],
  }) {
    return _finance.fetchQuotes(symbols: symbols);
  }

  Future<bool> syncDailyExpenseReminder({required bool enabled}) {
    return LocalNotificationsService.instance
        .syncDailyExpenseReminder(enabled: enabled);
  }

  Future<void> showBudgetLimitReached({
    required double total,
    required double limit,
    required DateTime month,
  }) {
    return LocalNotificationsService.instance.showBudgetLimitReached(
      total: total,
      limit: limit,
      month: month,
    );
  }
}
