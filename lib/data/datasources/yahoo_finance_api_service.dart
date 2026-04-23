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

    try {
      final response = await _requestEnclout(
        symbols: cleanedSymbols,
        rapidApiKey: rapidApiKey,
      );
      final quotes = FinanceQuoteParser.parse(response.data);
      if (quotes.isNotEmpty) {
        return quotes;
      }
      errors.add('enclout: пустой ответ');
    } on DioException catch (error) {
      errors.add('enclout: ${_formatDioError(error)}');
    }

    try {
      final response = await _requestApidojo(
        symbols: cleanedSymbols,
        rapidApiKey: rapidApiKey,
      );
      final quotes = FinanceQuoteParser.parse(response.data);
      if (quotes.isNotEmpty) {
        return quotes;
      }
      errors.add('apidojo: пустой ответ');
    } on DioException catch (error) {
      errors.add('apidojo: ${_formatDioError(error)}');
    }

    throw Exception(
      'Не удалось получить котировки из всех Yahoo endpoints. ${errors.join(' | ')}',
    );
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
