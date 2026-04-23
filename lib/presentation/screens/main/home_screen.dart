import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/datasources/yahoo_finance_api_service.dart';
import '../../../data/models/finance_quote.dart';
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

  late Future<List<FinanceQuote>> _quotesFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _quotesFuture = _financeApiService.fetchQuotes(symbols: _currencySymbols);
    _searchController.addListener(_onSearchChanged);
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

  void _handleNotifications(BuildContext context) {
    showFeatureStub(context, 'Уведомления');
  }

  List<TransactionItem> get _filteredTransactions {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return transactions;
    }

    final numericQuery = query.replaceAll(RegExp(r'[^0-9.,]'), '');

    return transactions.where((item) {
      final title = item.title.toLowerCase();
      final subtitle = item.subtitle.toLowerCase();
      final amount = item.amount.toLowerCase();
      final normalizedAmount = amount.replaceAll(RegExp(r'[^0-9.,]'), '');

      final matchesText = title.contains(query) || subtitle.contains(query);
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
        onPressed: () => context.push(ExpenseUiRoutes.addExpense),
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
                const BalanceCard(),
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
                      onPressed: () {
                        context.push(ExpenseUiRoutes.filters);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSearchField(context),
                const SizedBox(height: 14),
                ..._filteredTransactions.map((transaction) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TransactionTile(item: transaction),
                  );
                }),
                if (_filteredTransactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'Ничего не найдено. Попробуйте другой запрос.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
