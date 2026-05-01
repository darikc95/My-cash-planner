import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/datasources/hive_storage_service.dart';
import '../../../data/datasources/local_auth_service.dart';
import '../../../data/datasources/yahoo_finance_api_service.dart';
import '../../../data/models/finance_quote.dart';
import '../../../domain/entities/expense.dart';
import '../../widgets/expense_ui_data.dart';
import '../../widgets/expense_ui_widgets.dart';
import '../app/expense_ui_routes.dart';

const _allCurrencies = <Map<String, String>>[
  {'symbol': 'EURKZT=X', 'pair': 'EUR/KZT', 'title': 'Евро'},
  {'symbol': 'USDKZT=X', 'pair': 'USD/KZT', 'title': 'Доллар США'},
  {'symbol': 'RUBKZT=X', 'pair': 'RUB/KZT', 'title': 'Российский рубль'},
  {'symbol': 'GBPKZT=X', 'pair': 'GBP/KZT', 'title': 'Британский фунт'},
  {'symbol': 'CNYKZT=X', 'pair': 'CNY/KZT', 'title': 'Китайский юань'},
  {'symbol': 'JPYKZT=X', 'pair': 'JPY/KZT', 'title': 'Японская иена'},
  {'symbol': 'CHFKZT=X', 'pair': 'CHF/KZT', 'title': 'Швейцарский франк'},
  {'symbol': 'AEDKZT=X', 'pair': 'AED/KZT', 'title': 'Дирхам ОАЭ'},
];

const _defaultCurrencySymbols = ['EURKZT=X', 'USDKZT=X', 'RUBKZT=X'];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _financeApiService = YahooFinanceApiService();
  final _storageService = const HiveStorageService();
  final _authService = const LocalAuthService(HiveStorageService());

  late List<String> _currencySymbols;
  late Future<List<FinanceQuote>> _quotesFuture;
  List<Expense> _expenses = const [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoadingExpenses = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCurrencyPreferences();
    _searchController.addListener(_onSearchChanged);
    // Set default period to last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    _loadExpenses();
  }

  void _loadCurrencyPreferences() {
    final userId = _authService.getCurrentUser()?.id;
    final saved =
        userId != null ? _storageService.getUserCurrencies(userId) : <String>[];
    final allowedSymbols = _allCurrencies
        .map((c) => _normalizeCurrencySymbol(c['symbol']!))
        .toSet();
    final normalizedSaved = saved
        .map(_normalizeCurrencySymbol)
        .where((symbol) => allowedSymbols.contains(symbol))
        .toList(growable: false);

    _currencySymbols = normalizedSaved.isNotEmpty
        ? normalizedSaved
        : List.of(_defaultCurrencySymbols);
    _quotesFuture = _financeApiService.fetchQuotes(symbols: _currencySymbols);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text);
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoadingExpenses = true);
    final currentUser = _authService.getCurrentUser();
    final expenses = currentUser == null
        ? const <Expense>[]
        : _storageService.getExpensesByUserId(currentUser.id);
    if (!mounted) return;
    setState(() {
      _expenses = expenses;
      _isLoadingExpenses = false;
    });
  }

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

  Future<void> _handleNotifications(BuildContext context) async {
    final totalIncome = _totalIncome;
    final totalExpenses = _totalExpenses;
    final balance = _balance;
    final now = DateTime.now();
    final budgetMonth = DateTime(now.year, now.month);
    final monthExpenses = _expenses
        .where(
          (e) =>
              !e.isIncome &&
              e.date.year == budgetMonth.year &&
              e.date.month == budgetMonth.month,
        )
        .fold<double>(0, (sum, e) => sum + e.amount);

    final userId = _authService.getCurrentUser()?.id;
    final budgetLimit = userId != null
        ? _storageService.getUserBudgetLimit(userId, month: budgetMonth)
        : null;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Сводка',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.arrow_downward_rounded,
                    color: Color(0xFF1DB954)),
                title: const Text('Доходы'),
                trailing: Text('${totalIncome.toStringAsFixed(0)} ₸'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.arrow_upward_rounded,
                    color: Color(0xFFFF5F67)),
                title: const Text('Расходы'),
                trailing: Text('${totalExpenses.toStringAsFixed(0)} ₸'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  balance >= 0
                      ? Icons.account_balance_wallet_outlined
                      : Icons.warning_amber_rounded,
                  color: balance >= 0
                      ? const Color(0xFF6C45E3)
                      : const Color(0xFFFF5F67),
                ),
                title: const Text('Баланс'),
                trailing: Text(
                  '${balance >= 0 ? '+' : ''}${balance.toStringAsFixed(0)} ₸',
                  style: TextStyle(
                    color: balance >= 0
                        ? const Color(0xFF1DB954)
                        : const Color(0xFFFF5F67),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (budgetLimit != null && budgetLimit > 0)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    monthExpenses >= budgetLimit
                        ? Icons.warning_amber_rounded
                        : Icons.shield_outlined,
                    color: monthExpenses >= budgetLimit
                        ? const Color(0xFFFF5F67)
                        : const Color(0xFF6C45E3),
                  ),
                  title:
                      Text('Лимит бюджета (${_formatMonthYear(budgetMonth)})'),
                  trailing: Text(
                    '${budgetLimit.toStringAsFixed(0)} ₸'
                    '${monthExpenses >= budgetLimit ? ' ⚠️' : ''}',
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _reloadQuotes();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Обновить курсы валют'),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Expense> get _visibleExpenses {
    return _expenses.where((expense) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      if (_startDate != null) {
        final startDate = DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
        );
        if (expenseDate.isBefore(startDate)) return false;
      }

      if (_endDate != null) {
        final endDate = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
        );
        if (expenseDate.isAfter(endDate)) return false;
      }

      return true;
    }).toList(growable: false);
  }

  List<Expense> get _filteredExpenses {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _visibleExpenses;

    final numericQuery = query.replaceAll(RegExp(r'[^0-9.,]'), '');

    return _visibleExpenses.where((expense) {
      final title = expense.title.toLowerCase();
      final category = expense.category.toLowerCase();
      final note = (expense.note ?? '').toLowerCase();
      final amount = expense.amount.toStringAsFixed(2);
      final normalizedAmount = amount.replaceAll(RegExp(r'[^0-9.,]'), '');

      final matchesText = title.contains(query) ||
          category.contains(query) ||
          note.contains(query);
      final matchesAmount = amount.contains(query) ||
          (numericQuery.isNotEmpty && normalizedAmount.contains(numericQuery));

      return matchesText || matchesAmount;
    }).toList(growable: false);
  }

  void _reloadQuotes() {
    setState(() {
      _quotesFuture = _financeApiService.fetchQuotes(symbols: _currencySymbols);
    });
  }

  Future<void> _openPeriodSelector() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Период отображения',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildPeriodOption('Последние 7 дней', 7),
              _buildPeriodOption('Последние 30 дней', 30),
              _buildPeriodOption('Последние 90 дней', 90),
              _buildPeriodOption('Текущий месяц', null),
              _buildPeriodOption('Все время', -1),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodOption(String label, int? days) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FilledButton(
        onPressed: () {
          setState(() {
            if (days == -1) {
              _startDate = null;
              _endDate = null;
            } else if (days == null) {
              // Current month
              final now = DateTime.now();
              _startDate = DateTime(now.year, now.month, 1);
              _endDate = now;
            } else {
              _endDate = DateTime.now();
              _startDate = _endDate!.subtract(Duration(days: days));
            }
          });
          Navigator.of(context).pop();
        },
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: const Color(0xFF6C45E3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Future<void> _openAddExpense() async {
    final created = await context.push<bool>(ExpenseUiRoutes.addExpense);
    if (created == true) await _loadExpenses();
  }

  Future<void> _openEditExpense(Expense expense) async {
    final updated = await context.push<bool>(
      ExpenseUiRoutes.editExpense,
      extra: expense,
    );
    if (updated == true) await _loadExpenses();
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить операцию?'),
        content: Text(
          '${expense.isIncome ? 'Доход' : 'Расход'} "${expense.title}" '
          '${expense.amount.toStringAsFixed(0)} ₸ будет удалён.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF5F67)),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    await _storageService.deleteExpense(expense.id);
    await _loadExpenses();
  }

  Future<void> _openCurrencySelector() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _CurrencySelectorDialog(
        selected: List.from(_currencySymbols),
        allCurrencies: _allCurrencies,
        onSave: (symbols) async {
          final normalized = symbols
              .map(_normalizeCurrencySymbol)
              .where((s) => s.isNotEmpty)
              .toList(growable: false);
          final effectiveSymbols = normalized.isNotEmpty
              ? normalized
              : List.of(_defaultCurrencySymbols);

          final userId = _authService.getCurrentUser()?.id;
          if (userId != null) {
            await _storageService.saveUserCurrencies(userId, effectiveSymbols);
          }
          if (!mounted) return;
          setState(() {
            _currencySymbols = effectiveSymbols;
            _quotesFuture =
                _financeApiService.fetchQuotes(symbols: effectiveSymbols);
          });
        },
      ),
    );
  }

  String _normalizeCurrencySymbol(String symbol) => symbol.trim().toUpperCase();

  List<FinanceQuote> _prepareCurrencyQuotes(List<FinanceQuote> quotes) {
    final normalizedSelected =
        _currencySymbols.map(_normalizeCurrencySymbol).toSet();

    final filtered = quotes.where((quote) {
      final symbol = _normalizeCurrencySymbol(quote.symbol);
      return normalizedSelected.contains(symbol);
    }).toList(growable: false);

    final ordered = [...filtered];
    ordered.sort((a, b) {
      final indexA =
          _currencySymbols.indexOf(_normalizeCurrencySymbol(a.symbol));
      final indexB =
          _currencySymbols.indexOf(_normalizeCurrencySymbol(b.symbol));
      return indexA.compareTo(indexB);
    });
    return ordered;
  }

  List<Expense> get _periodExpenses {
    return _expenses.where((expense) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      if (_startDate != null) {
        final startDate = DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
        );
        if (expenseDate.isBefore(startDate)) return false;
      }

      if (_endDate != null) {
        final endDate = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
        );
        if (expenseDate.isAfter(endDate)) return false;
      }

      return true;
    }).toList(growable: false);
  }

  double get _totalIncome => _periodExpenses
      .where((e) => e.isIncome)
      .fold<double>(0, (s, e) => s + e.amount);

  double get _totalExpenses => _periodExpenses
      .where((e) => !e.isIncome)
      .fold<double>(0, (s, e) => s + e.amount);

  double get _balance => _totalIncome - _totalExpenses;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final currentDate = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = currentDate.difference(targetDate).inDays;

    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');

    if (difference == 0) return 'Сегодня, $hours:$minutes';
    if (difference == 1) return 'Вчера, $hours:$minutes';

    const months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    return '${date.day} ${months[date.month - 1]}, $hours:$minutes';
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  _CategoryVisual _categoryVisual(String category) {
    // First, check user-customized categories in Hive (including modified default ones)
    final userId = _authService.getCurrentUser()?.id;
    if (userId != null) {
      // Check expense categories
      final cats = _storageService.getUserCategories(userId);
      final cat = cats.cast<Map<String, dynamic>?>().firstWhere(
            (c) => c?['name'] == category,
            orElse: () => null,
          );
      if (cat != null) {
        return _CategoryVisual(
          icon: IconData(
            cat['iconCodePoint'] as int,
            fontFamily: 'MaterialIcons',
          ),
          color: Color(cat['colorValue'] as int),
        );
      }
      // Check income categories
      final incomeCats = _storageService.getUserIncomeCategories(userId);
      final incomeCat = incomeCats.cast<Map<String, dynamic>?>().firstWhere(
            (c) => c?['name'] == category,
            orElse: () => null,
          );
      if (incomeCat != null) {
        return _CategoryVisual(
          icon: IconData(
            incomeCat['iconCodePoint'] as int,
            fontFamily: 'MaterialIcons',
          ),
          color: Color(incomeCat['colorValue'] as int),
        );
      }
    }
    // Then, check default expense categories
    final match = filterItems.cast<FilterItem?>().firstWhere(
          (item) => item?.label == category,
          orElse: () => null,
        );
    if (match != null) {
      return _CategoryVisual(icon: match.icon, color: match.color);
    }
    // Check default income categories
    final incomeMatch = filterIncomeItems.cast<FilterItem?>().firstWhere(
          (item) => item?.label == category,
          orElse: () => null,
        );
    if (incomeMatch != null) {
      return _CategoryVisual(icon: incomeMatch.icon, color: incomeMatch.color);
    }
    return const _CategoryVisual(
      icon: Icons.more_horiz_rounded,
      color: Color(0xFFB7BBC8),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    final periodLabel = _startDate == null && _endDate == null
        ? 'Все даты'
        : '${_startDate == null ? '...' : '${_startDate!.day}.${_startDate!.month}.${_startDate!.year}'}'
            ' - '
            '${_endDate == null ? '...' : '${_endDate!.day}.${_endDate!.month}.${_endDate!.year}'}';

    final balance = _balance;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7D57F2), Color(0xFF5B35D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Баланс',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
              ),
              const Spacer(),
              InkWell(
                onTap: _openPeriodSelector,
                borderRadius: BorderRadius.circular(21),
                child: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_month_outlined,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${balance >= 0 ? '' : '-'}${balance.abs().toStringAsFixed(0)} ₸',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 36,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _OverviewStat(
                label: 'Доходы',
                value: '${_totalIncome.toStringAsFixed(0)} ₸',
                icon: Icons.arrow_downward_rounded,
                color: const Color(0xFF4ADE80),
              ),
              const SizedBox(width: 24),
              _OverviewStat(
                label: 'Расходы',
                value: '${_totalExpenses.toStringAsFixed(0)} ₸',
                icon: Icons.arrow_upward_rounded,
                color: const Color(0xFFFF8FA3),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$periodLabel · ${_filteredExpenses.length} операций',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: 'Поиск по описанию или сумме',
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                onPressed: () => _searchController.clear(),
                icon: const Icon(Icons.close_rounded),
              ),
      ),
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  Widget _buildFinanceSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<FinanceQuote>>(
          future: _quotesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 72,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            if (snapshot.hasError) {
              final errorText =
                  snapshot.error?.toString() ?? 'Неизвестная ошибка';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _currencyHeader(context),
                  const SizedBox(height: 8),
                  Text(
                    'Не удалось загрузить данные.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    errorText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFE65252),
                        ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _reloadQuotes,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Повторить'),
                  ),
                ],
              );
            }

            final quotes = _prepareCurrencyQuotes(
              snapshot.data ?? const <FinanceQuote>[],
            );
            final quotesBySymbol = {
              for (final quote in quotes)
                _normalizeCurrencySymbol(quote.symbol): quote,
            };
            final orderedSymbols =
                _currencySymbols.map(_normalizeCurrencySymbol).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _currencyHeader(context),
                if (orderedSymbols.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Нет данных для отображения.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  ...orderedSymbols.map((normalizedSymbol) {
                    final quote = quotesBySymbol[normalizedSymbol];
                    final currencyInfo =
                        _allCurrencies.cast<Map<String, String>?>().firstWhere(
                              (c) => c?['symbol'] == normalizedSymbol,
                              orElse: () => null,
                            );
                    final pairLabel = currencyInfo?['pair'] ?? normalizedSymbol;
                    final currencyTitle = currencyInfo?['title'] ??
                        (quote?.name ?? 'Неизвестная валюта');
                    final color = quote == null
                        ? const Color(0xFF9AA0B4)
                        : (quote.isPositive
                            ? const Color(0xFF1DB954)
                            : const Color(0xFFE65252));
                    final sign = quote != null && quote.change >= 0 ? '+' : '';

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$pairLabel · $currencyTitle',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            quote == null
                                ? 'Нет данных'
                                : '${quote.price.toStringAsFixed(2)} ₸',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            quote == null
                                ? '—'
                                : '$sign${quote.changePercent.toStringAsFixed(2)}%',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _currencyHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Курсы валют (Yahoo Finance)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          onPressed: _openCurrencySelector,
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Выбрать валюты',
        ),
        IconButton(
          onPressed: _reloadQuotes,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Обновить',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: PrimaryFab(
        onPressed: _openAddExpense,
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
                    Text(
                      'Мои финансы',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TopActionButton(
                      icon: Icons.info_outline_rounded,
                      onPressed: () => _handleNotifications(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildOverviewCard(context),
                const SizedBox(height: 16),
                _buildFinanceSection(context),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Text(
                      'Последние операции',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSearchField(context),
                const SizedBox(height: 14),
                if (_isLoadingExpenses)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_filteredExpenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      _expenses.isEmpty
                          ? 'Пока нет операций. Добавьте первую запись.'
                          : 'Ничего не найдено. Попробуйте другой запрос.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  ..._filteredExpenses.map((expense) {
                    final visual = _categoryVisual(expense.category);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ExpenseTile(
                        expense: expense,
                        visual: visual,
                        formatDate: _formatDate,
                        onEdit: () => _openEditExpense(expense),
                        onDelete: () => _deleteExpense(expense),
                      ),
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

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.visual,
    required this.formatDate,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final _CategoryVisual visual;
  final String Function(DateTime) formatDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final note = expense.note?.trim();
    final subtitle = note == null || note.isEmpty
        ? formatDate(expense.date)
        : '${formatDate(expense.date)} · $note';

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5F67),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onLongPress: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: visual.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(visual.icon, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF242938),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${expense.isIncome ? '+' : '-'}${expense.amount.toStringAsFixed(0)} ₸',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: expense.isIncome
                                ? const Color(0xFF1DB954)
                                : const Color(0xFFFF5F67),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onEdit,
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Color(0xFF9AA0B4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Color(0xFF9AA0B4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryVisual {
  const _CategoryVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

class _CurrencySelectorDialog extends StatefulWidget {
  const _CurrencySelectorDialog({
    required this.selected,
    required this.allCurrencies,
    required this.onSave,
  });

  final List<String> selected;
  final List<Map<String, String>> allCurrencies;
  final Future<void> Function(List<String> symbols) onSave;

  @override
  State<_CurrencySelectorDialog> createState() =>
      _CurrencySelectorDialogState();
}

class _CurrencySelectorDialogState extends State<_CurrencySelectorDialog> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    // Build ordered list: selected first (preserving original order), then rest
    final orderedSymbols =
        widget.allCurrencies.map((c) => c['symbol']!).toList();

    return AlertDialog(
      title: const Text('Выбор валют'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выберите до 5 валют. ⭐ — первые 2 избранные.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ...orderedSymbols.map((symbol) {
              final c =
                  widget.allCurrencies.firstWhere((m) => m['symbol'] == symbol);
              final isChecked = _selected.contains(symbol);
              final orderedSelected =
                  orderedSymbols.where(_selected.contains).toList();
              final favIdx = orderedSelected.indexOf(symbol);
              final isFav = isChecked && favIdx < 2;

              return CheckboxListTile(
                value: isChecked,
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    if (isFav)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.star_rounded,
                            color: Color(0xFFFFBF33), size: 16),
                      ),
                    Text('${c['pair']} · ${c['title']}'),
                  ],
                ),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      if (_selected.length < 5) _selected.add(symbol);
                    } else {
                      _selected.remove(symbol);
                    }
                  });
                },
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () async {
            final ordered = orderedSymbols.where(_selected.contains).toList();
            Navigator.of(context).pop();
            await widget.onSave(ordered);
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
