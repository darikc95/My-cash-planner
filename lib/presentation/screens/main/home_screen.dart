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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _currencySymbols = ['EURKZT=X', 'USDKZT=X', 'RUBKZT=X'];
  static const _currencyTitleBySymbol = {
    'EURKZT=X': 'Евро',
    'USDKZT=X': 'Доллар США',
    'RUBKZT=X': 'Российский рубль',
  };
  static const _currencyPairBySymbol = {
    'EURKZT=X': 'EUR/KZT',
    'USDKZT=X': 'USD/KZT',
    'RUBKZT=X': 'RUB/KZT',
  };

  final _searchController = TextEditingController();
  final _financeApiService = YahooFinanceApiService();
  final _storageService = const HiveStorageService();
  final _authService = const LocalAuthService(HiveStorageService());

  late Future<List<FinanceQuote>> _quotesFuture;
  List<Expense> _expenses = const [];
  late Set<String> _selectedCategories;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoadingExpenses = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategories = filterItems.map((item) => item.label).toSet();
    _quotesFuture = _financeApiService.fetchQuotes(symbols: _currencySymbols);
    _searchController.addListener(_onSearchChanged);
    _loadExpenses();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoadingExpenses = true;
    });

    final currentUser = _authService.getCurrentUser();
    final expenses = currentUser == null
        ? const <Expense>[]
        : _storageService.getExpensesByUserId(currentUser.id);

    if (!mounted) {
      return;
    }

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
    final visibleExpenses = _filteredExpenses;
    final totalAmount = visibleExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

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
                leading: const Icon(Icons.receipt_long_rounded),
                title: const Text('Операций по текущему фильтру'),
                trailing: Text('${visibleExpenses.length}'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Сумма расходов'),
                trailing: Text('${totalAmount.toStringAsFixed(0)} ₸'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Активные категории'),
                trailing: Text('${_selectedCategories.length}'),
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

      if (_selectedCategories.isNotEmpty &&
          !_selectedCategories.contains(expense.category)) {
        return false;
      }

      if (_startDate != null) {
        final startDate = DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
        );
        if (expenseDate.isBefore(startDate)) {
          return false;
        }
      }

      if (_endDate != null) {
        final endDate = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
        );
        if (expenseDate.isAfter(endDate)) {
          return false;
        }
      }

      return true;
    }).toList(growable: false);
  }

  List<Expense> get _filteredExpenses {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _visibleExpenses;
    }

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

  Future<void> _openFilters() async {
    final result = await context.push<Map<String, dynamic>>(
      ExpenseUiRoutes.filters,
      extra: <String, dynamic>{
        'categories': _selectedCategories.toList(growable: false),
        'startDate': _startDate,
        'endDate': _endDate,
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _selectedCategories = Set<String>.from(
        (result['categories'] as List<dynamic>? ?? const <dynamic>[]),
      );
      _startDate = result['startDate'] as DateTime?;
      _endDate = result['endDate'] as DateTime?;
    });
  }

  Future<void> _openAddExpense() async {
    final created = await context.push<bool>(ExpenseUiRoutes.addExpense);
    if (created == true) {
      await _loadExpenses();
    }
  }

  String _normalizeCurrencySymbol(String symbol) {
    return symbol.trim().toUpperCase();
  }

  List<FinanceQuote> _prepareCurrencyQuotes(List<FinanceQuote> quotes) {
    final filtered = quotes.where((quote) {
      final symbol = _normalizeCurrencySymbol(quote.symbol);
      return _currencySymbols.contains(symbol);
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

  double get _totalFilteredExpenses => _filteredExpenses.fold<double>(
        0,
        (sum, expense) => sum + expense.amount,
      );

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final currentDate = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = currentDate.difference(targetDate).inDays;

    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');

    if (difference == 0) {
      return 'Сегодня, $hours:$minutes';
    }

    if (difference == 1) {
      return 'Вчера, $hours:$minutes';
    }

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

  _CategoryVisual _categoryVisual(String category) {
    final match = filterItems.cast<FilterItem?>().firstWhere(
          (item) => item?.label == category,
          orElse: () => null,
        );

    if (match != null) {
      return _CategoryVisual(icon: match.icon, color: match.color);
    }

    return const _CategoryVisual(
      icon: Icons.more_horiz_rounded,
      color: Color(0xFFB7BBC8),
    );
  }

  TransactionItem _mapExpenseToTransaction(Expense expense) {
    final visual = _categoryVisual(expense.category);
    final note = expense.note?.trim();

    return TransactionItem(
      title: expense.title,
      subtitle: note == null || note.isEmpty
          ? _formatDate(expense.date)
          : '${_formatDate(expense.date)} · $note',
      amount: '${expense.amount.toStringAsFixed(0)} ₸',
      icon: visual.icon,
      iconBackground: visual.color,
      isNegative: true,
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    final periodLabel = _startDate == null && _endDate == null
        ? 'Все даты'
        : '${_startDate == null ? '...' : _startDate!.day}.${_startDate!.month}.${_startDate!.year} - '
            '${_endDate == null ? '...' : _endDate!.day}.${_endDate!.month}.${_endDate!.year}';

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
                'Расходы по фильтру',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
              ),
              const Spacer(),
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.insights_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${_totalFilteredExpenses.toStringAsFixed(0)} ₸',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 36,
                ),
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
                onPressed: () {
                  _searchController.clear();
                },
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
                  Text(
                    'Курсы валют к тенге (Yahoo Finance)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Не удалось загрузить данные. Проверьте интернет и ключ RapidAPI.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
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
            if (quotes.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Курсы валют к тенге (Yahoo Finance)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Нет данных для отображения.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Курсы валют к тенге (Yahoo Finance)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: _reloadQuotes,
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Обновить',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...quotes.map((quote) {
                  final normalizedSymbol =
                      _normalizeCurrencySymbol(quote.symbol);
                  final pairLabel = _currencyPairBySymbol[normalizedSymbol] ??
                      normalizedSymbol;
                  final currencyTitle =
                      _currencyTitleBySymbol[normalizedSymbol] ?? quote.name;
                  final color = quote.isPositive
                      ? const Color(0xFF1DB954)
                      : const Color(0xFFE65252);
                  final sign = quote.change >= 0 ? '+' : '';

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$pairLabel · $currencyTitle',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${quote.price.toStringAsFixed(2)} ₸',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$sign${quote.changePercent.toStringAsFixed(2)}%',
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
                    const Spacer(),
                    TopActionButton(
                      icon: Icons.tune_rounded,
                      onPressed: _openFilters,
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
                          ? 'Пока нет расходов. Добавьте первую операцию.'
                          : 'Ничего не найдено. Попробуйте другой запрос или измените фильтры.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  ..._filteredExpenses.map((expense) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TransactionTile(
                        item: _mapExpenseToTransaction(expense),
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

class _CategoryVisual {
  const _CategoryVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}
