import '../entities/expense.dart';

abstract interface class ExpenseRepository {
  Future<void> saveExpense(Expense expense);

  Future<Expense?> getExpenseById(String expenseId);

  Future<List<Expense>> getAllExpenses();

  Future<List<Expense>> getExpensesByUserId(String userId);

  Future<void> deleteExpense(String expenseId);

  Future<void> clearExpenses();
}
