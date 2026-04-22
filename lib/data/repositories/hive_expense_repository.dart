import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/hive_storage_service.dart';

class HiveExpenseRepository implements ExpenseRepository {
  const HiveExpenseRepository(this._storageService);

  final HiveStorageService _storageService;

  @override
  Future<void> saveExpense(Expense expense) {
    return _storageService.saveExpense(expense);
  }

  @override
  Future<Expense?> getExpenseById(String expenseId) {
    return Future.value(_storageService.getExpenseById(expenseId));
  }

  @override
  Future<List<Expense>> getAllExpenses() {
    return Future.value(_storageService.getAllExpenses());
  }

  @override
  Future<List<Expense>> getExpensesByUserId(String userId) {
    return Future.value(_storageService.getExpensesByUserId(userId));
  }

  @override
  Future<void> deleteExpense(String expenseId) {
    return _storageService.deleteExpense(expenseId);
  }

  @override
  Future<void> clearExpenses() {
    return _storageService.clearExpenses();
  }
}
