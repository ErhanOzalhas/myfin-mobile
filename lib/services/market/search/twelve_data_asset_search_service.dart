import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/asset_category.dart';
import '../registry/asset_info.dart';

class TwelveDataAssetSearchService {
  TwelveDataAssetSearchService({
    String? apiKey,
    http.Client? client,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 12),
  })  : _apiKeyOverride = apiKey?.trim(),
        _client = client ?? http.Client(),
        _baseUri = baseUri ??
            Uri.parse('https://api.twelvedata.com');

  final String? _apiKeyOverride;
  final http.Client _client;
  final Uri _baseUri;
  final Duration timeout;

  final Map<String, List<AssetInfo>> _cache = {};

  String get _apiKey {
    return (_apiKeyOverride ??
            dotenv.env['TWELVE_DATA_API_KEY'] ??
            '')
        .trim();
  }

  Future<List<AssetInfo>> search(
    String query, {
    int limit = 15,
  }) async {
    final normalized = query.trim();

    if (normalized.length < 2 || _apiKey.isEmpty) {
      return const [];
    }

    final cacheKey = normalized.toUpperCase();
    final cached = _cache[cacheKey];

    if (cached != null) {
      return cached.take(limit).toList();
    }

    final results = <AssetInfo>[];

    results.addAll(
      await _symbolSearch(normalized, limit: limit),
    );

    // AEFES, ADEL, SAP gibi doğrudan ticker sorgularında
    // symbol_search plan/kapsam nedeniyle boş dönerse quote ile
    // kesin sembol kontrolü yapılır.
    if (_looksLikeTicker(normalized) &&
        !results.any(
          (asset) =>
              asset.symbol.toUpperCase() ==
              normalized.toUpperCase(),
        )) {
      final exact = await _exactTickerLookup(normalized);

      if (exact != null) {
        results.insert(0, exact);
      }
    }

    final unique = <String, AssetInfo>{};

    for (final asset in results) {
      final key =
          '${asset.symbol.toUpperCase()}::'
          '${asset.exchange.toUpperCase()}';
      unique.putIfAbsent(key, () => asset);
    }

    final finalResults = unique.values.toList()
      ..sort(
        (first, second) => second
            .searchScore(normalized)
            .compareTo(first.searchScore(normalized)),
      );

    _cache[cacheKey] = finalResults;

    debugPrint(
      'TWELVE SEARCH "$normalized": '
      '${finalResults.length} result',
    );

    return finalResults.take(limit).toList();
  }

  Future<List<AssetInfo>> _symbolSearch(
    String query, {
    required int limit,
  }) async {
    final uri = _baseUri.replace(
      path: '${_baseUri.path}/symbol_search',
      queryParameters: {
        'symbol': query,
        'outputsize': '$limit',
        'apikey': _apiKey,
      },
    );

    final response = await _get(uri);

    if (response == null) {
      return const [];
    }

    final decoded = _decode(response.body);

    if (decoded is! Map<String, dynamic>) {
      return const [];
    }

    if ((decoded['status'] ?? '').toString() == 'error') {
      debugPrint(
        'TWELVE SYMBOL SEARCH ERROR: '
        '${decoded['message']}',
      );
      return const [];
    }

    final data = decoded['data'];

    if (data is! List) {
      return const [];
    }

    return [
      for (final item in data)
        if (item is Map)
          _mapSearchResult(
            Map<String, dynamic>.from(item),
          ),
    ].whereType<AssetInfo>().toList();
  }

  Future<AssetInfo?> _exactTickerLookup(
    String symbol,
  ) async {
    for (final exchange in <String?>[
      'XIST',
      null,
    ]) {
      final queryParameters = <String, String>{
        'symbol': symbol.toUpperCase(),
        'apikey': _apiKey,
      };

      if (exchange != null) {
        queryParameters['exchange'] = exchange;
      }

      final uri = _baseUri.replace(
        path: '${_baseUri.path}/quote',
        queryParameters: queryParameters,
      );

      final response = await _get(uri);

      if (response == null) continue;

      final decoded = _decode(response.body);

      if (decoded is! Map<String, dynamic>) continue;
      if ((decoded['status'] ?? '').toString() == 'error') {
        continue;
      }

      final returnedSymbol =
          (decoded['symbol'] ?? symbol).toString().trim();

      final price = _toDouble(
        decoded['close'] ??
            decoded['price'] ??
            decoded['last'],
      );

      if (returnedSymbol.isEmpty || price <= 0) {
        continue;
      }

      return AssetInfo(
        symbol: returnedSymbol.toUpperCase(),
        name: (decoded['name'] ??
                decoded['instrument_name'] ??
                returnedSymbol)
            .toString(),
        category: _categoryFor(
          type: (decoded['type'] ?? '').toString(),
          exchange: (decoded['exchange'] ??
                  decoded['mic_code'] ??
                  exchange ??
                  'GLOBAL')
              .toString(),
          symbol: returnedSymbol,
        ),
        exchange: (decoded['exchange'] ??
                decoded['mic_code'] ??
                exchange ??
                'GLOBAL')
            .toString()
            .toUpperCase(),
        currency:
            (decoded['currency'] ?? 'USD').toString().toUpperCase(),
        countryCode: exchange == 'XIST' ? 'TR' : 'GLOBAL',
        provider: 'TwelveData',
        supportStatus: exchange == 'XIST'
            ? AssetSupportStatus.delayed
            : AssetSupportStatus.live,
        riskLevel: AssetRiskLevel.unknown,
        keywords: [
          returnedSymbol,
          (decoded['name'] ?? '').toString(),
        ],
      );
    }

    return null;
  }

  AssetInfo? _mapSearchResult(
    Map<String, dynamic> row,
  ) {
    final symbol =
        (row['symbol'] ?? '').toString().trim();
    final name = (row['instrument_name'] ??
            row['name'] ??
            symbol)
        .toString()
        .trim();

    if (symbol.isEmpty) return null;

    final exchange = (row['exchange'] ??
            row['mic_code'] ??
            'GLOBAL')
        .toString()
        .trim()
        .toUpperCase();
    final currency = (row['currency'] ?? 'USD')
        .toString()
        .trim()
        .toUpperCase();
    final country =
        (row['country'] ?? 'GLOBAL').toString().trim();
    final type = (row['instrument_type'] ??
            row['type'] ??
            '')
        .toString()
        .toLowerCase();

    return AssetInfo(
      symbol: symbol.toUpperCase(),
      name: name.isEmpty ? symbol : name,
      category: _categoryFor(
        type: type,
        exchange: exchange,
        symbol: symbol,
      ),
      exchange: exchange,
      currency: currency,
      countryCode: _countryCode(country, exchange),
      provider: 'TwelveData',
      supportStatus: exchange.contains('XIST')
          ? AssetSupportStatus.delayed
          : AssetSupportStatus.live,
      riskLevel: AssetRiskLevel.unknown,
      keywords: [
        symbol,
        name,
        exchange,
        country,
      ],
    );
  }

  Future<http.Response?> _get(Uri uri) async {
    try {
      final response =
          await _client.get(uri).timeout(timeout);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        debugPrint(
          'TWELVE HTTP ${response.statusCode}: ${response.body}',
        );
        return null;
      }

      return response;
    } catch (error) {
      debugPrint('TWELVE SEARCH NETWORK ERROR: $error');
      return null;
    }
  }

  Object? _decode(String body) {
    try {
      return jsonDecode(body);
    } catch (error) {
      debugPrint('TWELVE SEARCH JSON ERROR: $error');
      return null;
    }
  }

  bool _looksLikeTicker(String query) {
    return RegExp(r'^[A-Za-z0-9./_-]{2,15}$')
        .hasMatch(query);
  }

  AssetCategory _categoryFor({
    required String type,
    required String exchange,
    required String symbol,
  }) {
    final normalizedType = type.toLowerCase();
    final normalizedExchange = exchange.toUpperCase();

    if (normalizedType.contains('etf')) {
      return AssetCategory.etf;
    }
    if (normalizedType.contains('index')) {
      return AssetCategory.marketIndex;
    }
    if (normalizedType.contains('fund')) {
      return AssetCategory.fund;
    }
    if (normalizedType.contains('forex') ||
        symbol.contains('/')) {
      return AssetCategory.currency;
    }
    if (normalizedType.contains('commodity')) {
      return AssetCategory.commodity;
    }
    if (normalizedExchange.contains('XIST')) {
      return AssetCategory.bist;
    }

    const us = {
      'NASDAQ',
      'NYSE',
      'AMEX',
      'XNAS',
      'XNYS',
      'ARCX',
    };
    if (us.any(normalizedExchange.contains)) {
      return AssetCategory.usStock;
    }

    const europe = {
      'XETR',
      'XLON',
      'XPAR',
      'XAMS',
      'XMIL',
      'XMAD',
      'XSWX',
      'EURONEXT',
      'LSE',
      'XETRA',
    };
    if (europe.any(normalizedExchange.contains)) {
      return AssetCategory.euStock;
    }

    const asia = {
      'XTKS',
      'XHKG',
      'XSES',
      'XSHG',
      'XSHE',
      'XKRX',
      'XNSE',
      'XBOM',
    };
    if (asia.any(normalizedExchange.contains)) {
      return AssetCategory.asiaStock;
    }

    return AssetCategory.unknown;
  }

  String _countryCode(String country, String exchange) {
    final normalized = country.toUpperCase();

    if (exchange.contains('XIST') ||
        normalized.contains('TURKEY') ||
        normalized.contains('TÜRKIYE')) {
      return 'TR';
    }
    if (normalized.contains('UNITED STATES')) return 'US';
    if (normalized.contains('GERMANY')) return 'DE';
    if (normalized.contains('UNITED KINGDOM')) return 'GB';
    if (normalized.contains('FRANCE')) return 'FR';
    if (normalized.contains('JAPAN')) return 'JP';

    return normalized.length == 2
        ? normalized
        : 'GLOBAL';
  }

  double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  void clearCache() {
    _cache.clear();
  }

  void close() {
    _client.close();
  }
}
