import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../models/finance_quote.dart';

class YahooFinanceApiService {
  YahooFinanceApiService({Dio? dio}) : _dio = dio ?? _createDefaultDio();

  static const yahooBaseUrl =
      'https://apidojo-yahoo-finance-v1.p.rapidapi.com/';
  static const _quotesAbsoluteUrl =
      'https://enclout-yahoo-finance.p.rapidapi.com/show.json';
  static const _encloutHost = 'enclout-yahoo-finance.p.rapidapi.com';
  static const _apidojoHost = 'apidojo-yahoo-finance-v1.p.rapidapi.com';
  static const _apidojoQuotesPath = 'market/v2/get-quotes';

  static const _rapidApiKeyFromDefine = String.fromEnvironment(
    'RAPIDAPI_KEY',
    defaultValue: '',
  );
  static const _envAssetCandidates = [
    'env/rapidapi.json',
    '.env/rapidapi.json',
  ];

  /// Для каждого символа XXXKZT=X определяет пару через USD.
  /// multiply=true → XXXKZT = helper × USDKZT (напр. EURUSD × USDKZT)
  /// multiply=false → XXXKZT = USDKZT / helper (напр. USDKZT / USDRUB)
  static const _crossRateHelpers = <String, ({String helper, bool multiply})>{
    'EURKZT=X': (helper: 'EURUSD=X', multiply: true),
    'GBPKZT=X': (helper: 'GBPUSD=X', multiply: true),
    'CHFKZT=X': (helper: 'CHFUSD=X', multiply: true),
    'RUBKZT=X': (helper: 'USDRUB=X', multiply: false),
    'CNYKZT=X': (helper: 'USDCNY=X', multiply: false),
    'JPYKZT=X': (helper: 'USDJPY=X', multiply: false),
    'AEDKZT=X': (helper: 'USDAED=X', multiply: false),
  };

  final Dio _dio;
  Future<String>? _cachedApiKeyFuture;

  static Dio _createDefaultDio() {
    return Dio(
      BaseOptions(
        baseUrl: yahooBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<List<FinanceQuote>> fetchQuotes({
    List<String> symbols = const ['EURKZT=X', 'USDKZT=X', 'RUBKZT=X'],
  }) async {
    final cleanedSymbols = symbols
        .map((symbol) => symbol.trim().toUpperCase())
        .where((symbol) => symbol.isNotEmpty)
        .toList(growable: false);

    if (cleanedSymbols.isEmpty) {
      return const [];
    }

    final rapidApiKey = await _resolveApiKey();

    if (rapidApiKey.isEmpty) {
      throw Exception(
        'Не задан RAPIDAPI_KEY. Укажите ключ через '
        '--dart-define=RAPIDAPI_KEY=ваш_ключ или в env/rapidapi.json',
      );
    }

    if (_isPlaceholderKey(rapidApiKey)) {
      throw Exception(
        'Обнаружен плейсхолдер вместо реального ключа RapidAPI. '
        'Проверьте RAPIDAPI_KEY в --dart-define или в env/rapidapi.json.',
      );
    }

    final errors = <String>[];
    // Собираем данные из обоих endpoints, объединяя результаты
    var resultMap = <String, FinanceQuote>{};

    try {
      final response = await _requestEnclout(
        symbols: cleanedSymbols,
        rapidApiKey: rapidApiKey,
      );
      final quotes = FinanceQuoteParser.parse(response.data);
      for (final q in quotes) {
        resultMap[q.symbol.toUpperCase()] = q;
      }
      if (quotes.isEmpty) errors.add('enclout: пустой ответ');
    } on DioException catch (error) {
      errors.add('enclout: ${_formatDioError(error)}');
    }

    // Запрашиваем apidojo для символов, которых не хватает
    final missingAfterEnclout = cleanedSymbols
        .where((s) => !resultMap.containsKey(s))
        .toList(growable: false);

    if (missingAfterEnclout.isNotEmpty || resultMap.isEmpty) {
      final toFetch = resultMap.isEmpty ? cleanedSymbols : missingAfterEnclout;
      try {
        final response = await _requestApidojo(
          symbols: toFetch,
          rapidApiKey: rapidApiKey,
        );
        final quotes = FinanceQuoteParser.parse(response.data);
        for (final q in quotes) {
          resultMap[q.symbol.toUpperCase()] = q;
        }
        if (quotes.isEmpty) errors.add('apidojo: пустой ответ');
      } on DioException catch (error) {
        errors.add('apidojo: ${_formatDioError(error)}');
      }
    }

    if (resultMap.isEmpty) {
      throw Exception(
        'Не удалось получить котировки из всех Yahoo endpoints. ${errors.join(' | ')}',
      );
    }

    // Вычисляем кросс-курсы для символов, которых всё ещё нет
    final crossRates = await _computeCrossRates(
      requestedSymbols: cleanedSymbols,
      available: resultMap,
      rapidApiKey: rapidApiKey,
    );
    for (final q in crossRates) {
      resultMap.putIfAbsent(q.symbol.toUpperCase(), () => q);
    }

    return resultMap.values.toList(growable: false);
  }

  /// Вычисляет кросс-курсы через USD для символов, отсутствующих в [available].
  ///
  /// Формула:
  /// - XXXUSD=X (multiply=true):  XXXKZT = helper_price × USDKZT
  /// - USDXXX=X (multiply=false): XXXKZT = USDKZT / helper_price
  Future<List<FinanceQuote>> _computeCrossRates({
    required List<String> requestedSymbols,
    required Map<String, FinanceQuote> available,
    required String rapidApiKey,
  }) async {
    final missing = requestedSymbols
        .map((s) => s.toUpperCase())
        .where(
          (s) => !available.containsKey(s) && _crossRateHelpers.containsKey(s),
        )
        .toList(growable: false);

    if (missing.isEmpty) return const [];

    // Собираем вспомогательные пары для запроса
    final helpersNeeded = <String>{};
    for (final sym in missing) {
      helpersNeeded.add(_crossRateHelpers[sym]!.helper);
    }
    // USDKZT=X нужен как база для всех вычислений
    helpersNeeded.add('USDKZT=X');

    final toFetch =
        helpersNeeded.where((s) => !available.containsKey(s)).toList();

    final helperMap = Map<String, FinanceQuote>.from(available);

    if (toFetch.isNotEmpty) {
      try {
        final response = await _requestApidojo(
          symbols: toFetch,
          rapidApiKey: rapidApiKey,
        );
        final fetched = FinanceQuoteParser.parse(response.data);
        for (final q in fetched) {
          helperMap[q.symbol.toUpperCase()] = q;
        }
      } catch (_) {
        // Если вспомогательные пары не загрузились — пропускаем кросс-расчёт
      }
    }

    final usdKzt = helperMap['USDKZT=X'];
    if (usdKzt == null || usdKzt.price <= 0) return const [];

    final crossRates = <FinanceQuote>[];
    for (final sym in missing) {
      final config = _crossRateHelpers[sym]!;
      final helper = helperMap[config.helper];
      if (helper == null || helper.price <= 0) continue;

      final crossPrice = config.multiply
          ? helper.price * usdKzt.price
          : usdKzt.price / helper.price;

      crossRates.add(
        FinanceQuote(
          symbol: sym,
          name: helper.name,
          price: crossPrice,
          change: 0,
          changePercent: 0,
        ),
      );
    }

    return crossRates;
  }

  Future<Response<dynamic>> _requestEnclout({
    required List<String> symbols,
    required String rapidApiKey,
  }) {
    return _dio.get<dynamic>(
      _quotesAbsoluteUrl,
      queryParameters: {
        'text': symbols.join(', '),
      },
      options: Options(
        headers: {
          'x-rapidapi-host': _encloutHost,
          'x-rapidapi-key': rapidApiKey,
        },
      ),
    );
  }

  Future<Response<dynamic>> _requestApidojo({
    required List<String> symbols,
    required String rapidApiKey,
  }) {
    return _dio.get<dynamic>(
      _apidojoQuotesPath,
      queryParameters: {
        'region': 'US',
        'symbols': symbols.join(','),
      },
      options: Options(
        headers: {
          'x-rapidapi-host': _apidojoHost,
          'x-rapidapi-key': rapidApiKey,
        },
      ),
    );
  }

  Future<String> _resolveApiKey() {
    _cachedApiKeyFuture ??= _loadApiKey();
    return _cachedApiKeyFuture!;
  }

  Future<String> _loadApiKey() async {
    final fromDefine = _sanitizeKey(_rapidApiKeyFromDefine);
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }

    for (final assetPath in _envAssetCandidates) {
      try {
        final fileContent = await rootBundle.loadString(assetPath);
        final decoded = jsonDecode(fileContent);
        if (decoded is Map<String, dynamic>) {
          final fromFile = _sanitizeKey(decoded['RAPIDAPI_KEY']?.toString());
          if (fromFile.isNotEmpty) {
            return fromFile;
          }
        }
      } catch (_) {
        // Пробуем следующий путь.
      }
    }

    return '';
  }

  bool _isPlaceholderKey(String key) {
    final upper = key.trim().toUpperCase();
    return upper == 'YOUR_RAPIDAPI_KEY' ||
        upper == 'PASTE_YOUR_REAL_RAPIDAPI_KEY_HERE';
  }

  String _sanitizeKey(String? raw) {
    if (raw == null) {
      return '';
    }

    var value = raw.trim();

    while (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1).trim();
    }

    if (value.endsWith("'")) {
      value = value.substring(0, value.length - 1).trim();
    }

    return value;
  }

  String _formatDioError(DioException error) {
    final status = error.response?.statusCode;
    final message = error.response?.data?.toString() ?? error.message;
    return '($status) $message';
  }
}
