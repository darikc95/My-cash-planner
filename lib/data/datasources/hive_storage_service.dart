import 'package:hive/hive.dart';

import '../../core/constants/hive_box_names.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/user.dart';

class HiveStorageService {
  const HiveStorageService();

  Box<User> get _usersBox => Hive.box<User>(HiveBoxNames.users);
  Box<Expense> get _expensesBox => Hive.box<Expense>(HiveBoxNames.expenses);

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
}
