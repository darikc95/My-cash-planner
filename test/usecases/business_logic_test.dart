import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:template/data/datasources/local_auth_service.dart';
import 'package:template/domain/entities/expense.dart';
import 'package:template/domain/entities/user.dart';
import 'package:template/domain/repositories/expense_repository.dart';
import 'package:template/domain/usecases/auth/login_use_case.dart';
import 'package:template/domain/usecases/auth/register_use_case.dart';

// ── Моки ──────────────────────────────────────────────────────────────────────

class MockLocalAuthService extends Mock implements LocalAuthService {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

// ── Фикстуры ──────────────────────────────────────────────────────────────────

final _testUser = User(
  id: 'user_1',
  email: 'test@example.com',
  name: 'Test User',
  createdAt: DateTime(2024, 1, 1),
);

Expense _makeExpense({
  String id = 'exp_1',
  String userId = 'user_1',
  String title = 'Кафе',
  double amount = 500.0,
  String category = 'Еда',
  bool isIncome = false,
  DateTime? date,
}) =>
    Expense(
      id: id,
      userId: userId,
      title: title,
      amount: amount,
      category: category,
      date: date ?? DateTime(2024, 6, 15),
      isIncome: isIncome,
    );

// ── Тесты ─────────────────────────────────────────────────────────────────────

void main() {
  // ── 1. Авторизация: успешный вход ──────────────────────────────────────────
  group('LoginUseCase', () {
    late MockLocalAuthService mockAuthService;
    late LoginUseCase loginUseCase;

    setUp(() {
      mockAuthService = MockLocalAuthService();
      loginUseCase = LoginUseCase(mockAuthService);
    });

    test('1. Успешный вход возвращает success и пользователя', () async {
      when(
        () => mockAuthService.login(
          email: 'test@example.com',
          password: 'pass123',
        ),
      ).thenAnswer((_) async => AuthActionResult.success(_testUser));

      final result = await loginUseCase(
        email: 'test@example.com',
        password: 'pass123',
      );

      expect(result.success, isTrue);
      expect(result.user, equals(_testUser));
    });

    test('2. Вход с неверным паролем возвращает failure', () async {
      when(
        () => mockAuthService.login(
          email: 'test@example.com',
          password: 'wrong',
        ),
      ).thenAnswer(
        (_) async => const AuthActionResult.failure('Неверный пароль.'),
      );

      final result = await loginUseCase(
        email: 'test@example.com',
        password: 'wrong',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Неверный пароль'));
    });
  });

  // ── 2. Регистрация ─────────────────────────────────────────────────────────
  group('RegisterUseCase', () {
    late MockLocalAuthService mockAuthService;
    late RegisterUseCase registerUseCase;

    setUp(() {
      mockAuthService = MockLocalAuthService();
      registerUseCase = RegisterUseCase(mockAuthService);
    });

    test('3. Успешная регистрация нового пользователя', () async {
      when(
        () => mockAuthService.register(
          email: 'new@example.com',
          password: 'secure123',
        ),
      ).thenAnswer((_) async => AuthActionResult.success(_testUser));

      final result = await registerUseCase(
        email: 'new@example.com',
        password: 'secure123',
      );

      expect(result.success, isTrue);
      expect(result.user, isNotNull);
    });

    test('4. Регистрация с уже занятым email возвращает failure', () async {
      when(
        () => mockAuthService.register(
          email: 'test@example.com',
          password: 'any',
        ),
      ).thenAnswer(
        (_) async => const AuthActionResult.failure(
          'Пользователь с таким email уже существует.',
        ),
      );

      final result = await registerUseCase(
        email: 'test@example.com',
        password: 'any',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('уже существует'));
    });
  });

  // ── 3. Бизнес-логика расходов (чистые вычисления, без Hive) ───────────────
  group('Expense business logic', () {
    test('5. Добавление расхода: isIncome = false', () {
      final expense = _makeExpense(isIncome: false, amount: 1500.0);

      expect(expense.isIncome, isFalse);
      expect(expense.amount, equals(1500.0));
      expect(expense.hasNote, isFalse);
    });

    test('6. Добавление дохода: isIncome = true', () {
      final income = _makeExpense(
        id: 'inc_1',
        title: 'Зарплата',
        amount: 250000.0,
        category: 'Заработная плата',
        isIncome: true,
      );

      expect(income.isIncome, isTrue);
      expect(income.amount, equals(250000.0));
    });

    test('7. Вычисление общей суммы расходов и доходов', () {
      final items = [
        _makeExpense(id: 'e1', amount: 500.0, isIncome: false),
        _makeExpense(id: 'e2', amount: 1000.0, isIncome: false),
        _makeExpense(id: 'i1', amount: 5000.0, isIncome: true),
      ];

      final totalExpenses = items
          .where((e) => !e.isIncome)
          .fold<double>(0, (sum, e) => sum + e.amount);

      final totalIncome = items
          .where((e) => e.isIncome)
          .fold<double>(0, (sum, e) => sum + e.amount);

      final balance = totalIncome - totalExpenses;

      expect(totalExpenses, equals(1500.0));
      expect(totalIncome, equals(5000.0));
      expect(balance, equals(3500.0));
    });

    test('8. Фильтрация расходов по диапазону дат', () {
      final items = [
        _makeExpense(id: 'e1', date: DateTime(2024, 6, 1)),
        _makeExpense(id: 'e2', date: DateTime(2024, 6, 15)),
        _makeExpense(id: 'e3', date: DateTime(2024, 7, 1)),
      ];

      final start = DateTime(2024, 6, 1);
      final end = DateTime(2024, 6, 30);

      final filtered = items.where((e) {
        return !e.date.isBefore(start) && !e.date.isAfter(end);
      }).toList();

      expect(filtered.length, equals(2));
      expect(filtered.map((e) => e.id), containsAll(['e1', 'e2']));
    });

    test('9. Фильтрация расходов по категории', () {
      final items = [
        _makeExpense(id: 'e1', category: 'Еда'),
        _makeExpense(id: 'e2', category: 'Транспорт'),
        _makeExpense(id: 'e3', category: 'Еда'),
      ];

      final foodExpenses = items.where((e) => e.category == 'Еда').toList();

      expect(foodExpenses.length, equals(2));
      expect(foodExpenses.every((e) => e.category == 'Еда'), isTrue);
    });
  });

  // ── 4. Расход: вспомогательные методы ─────────────────────────────────────
  group('Expense model', () {
    test('10. copyWith корректно создаёт новый объект с изменёнными полями',
        () {
      final original = _makeExpense(amount: 100.0, title: 'Обед');
      final updated = original.copyWith(amount: 200.0, title: 'Ужин');

      expect(updated.amount, equals(200.0));
      expect(updated.title, equals('Ужин'));
      expect(updated.id, equals(original.id));
      expect(updated.userId, equals(original.userId));
    });

    test('11. hasNote возвращает true только при непустой заметке', () {
      final withNote = _makeExpense().copyWith(note: 'Важная покупка');
      final withEmpty = _makeExpense().copyWith(note: '   ');
      final withNull = _makeExpense();

      expect(withNote.hasNote, isTrue);
      expect(withEmpty.hasNote, isFalse);
      expect(withNull.hasNote, isFalse);
    });
  });
}
