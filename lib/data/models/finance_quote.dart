class FinanceQuote {
  const FinanceQuote({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    this.currency,
  });

  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final String? currency;

  bool get isPositive => change >= 0;

  factory FinanceQuote.fromJson(Map<String, dynamic> json) {
    final symbol = _readString(json, ['symbol', 'ticker', 'code']);
    final name = _readString(json, ['shortName', 'longName', 'name']);

    final resolvedSymbol = symbol.isNotEmpty ? symbol : 'N/A';
    final resolvedName = name.isNotEmpty ? name : resolvedSymbol;

    return FinanceQuote(
      symbol: resolvedSymbol,
      name: resolvedName,
      price: _readDouble(json, ['regularMarketPrice', 'price', 'lastPrice']),
      change: _readDouble(json, ['regularMarketChange', 'change']),
      changePercent: _readDouble(
        json,
        ['regularMarketChangePercent', 'changePercent'],
      ),
      currency: _readNullableString(
        json,
        ['currency', 'financialCurrency', 'marketCurrency'],
      ),
    );
  }

  static String _readString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  static String? _readNullableString(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    final value = _readString(source, keys);
    return value.isEmpty ? null : value;
  }

  static double _readDouble(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return 0;
  }
}

class FinanceQuoteParser {
  const FinanceQuoteParser._();

  static List<FinanceQuote> parse(dynamic raw) {
    final items = _extractList(raw);
    return items
        .whereType<Map>()
        .map((item) => FinanceQuote.fromJson(Map<String, dynamic>.from(item)))
        .where((quote) => quote.symbol != 'N/A')
        .toList(growable: false);
  }

  static List<dynamic> _extractList(dynamic raw) {
    if (raw is List) {
      return raw;
    }

    if (raw is! Map) {
      return const [];
    }

    final map = Map<String, dynamic>.from(raw);

    final quoteResponse = map['quoteResponse'];
    if (quoteResponse is Map && quoteResponse['result'] is List) {
      return quoteResponse['result'] as List<dynamic>;
    }

    if (map['quotes'] is List) {
      return map['quotes'] as List<dynamic>;
    }

    if (map['data'] is List) {
      return map['data'] as List<dynamic>;
    }

    if (map['result'] is List) {
      return map['result'] as List<dynamic>;
    }

    return const [];
  }
}
