import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/asset_category.dart';
import '../models/market_quote.dart';
import 'market_provider.dart';
import 'provider_symbol_mapping.dart';

class TwelveDataMarketProvider implements MarketProvider {
  TwelveDataMarketProvider({
    String? apiKey,
    http.Client? client,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 12),
  })  : _apiKeyOverride = apiKey?.trim(),
        _client = client ?? http.Client(),
        _baseUri = baseUri ?? Uri.parse('https://api.twelvedata.com') {
    if (_apiKey.isEmpty) {
      throw ArgumentError(
        'TWELVE_DATA_API_KEY bulunamadı. '
        '.env dosyasına eklediğinden emin ol.',
      );
    }
  }

  final String? _apiKeyOverride;

  String get _apiKey {
    return (_apiKeyOverride ??
            dotenv.env['TWELVE_DATA_API_KEY'] ??
            '')
        .trim();
  }
  final http.Client _client;
  final Uri _baseUri;
  final Duration timeout;

  @override
  String get id => 'twelve_data';

  @override
  bool supportsSymbol(
    String symbol, {
    String? exchange,
  }) {
    return symbol.trim().isNotEmpty;
  }

  @override
  Future<MarketQuote> getQuote(
    String symbol, {
    String? exchange,
  }) async {
    final candidates =
        ProviderSymbolMapping.twelveDataCandidates(
      symbol: symbol,
      exchange: exchange,
    );

    if (candidates.isEmpty) {
      throw ArgumentError.value(
        symbol,
        'symbol',
        'Sembol boş olamaz.',
      );
    }

    final errors = <String>[];

    for (final candidate in candidates) {
      try {
        final quote = await _requestQuote(
          symbol: candidate.symbol,
          exchange: candidate.exchange,
        );

        return quote;
      } on MarketProviderException catch (error) {
        errors.add(
          '${candidate.debugLabel}: ${error.message}',
        );
      }
    }

    throw MarketProviderException(
      providerId: id,
      message:
          '${symbol.trim().toUpperCase()} için fiyat alınamadı. '
          'Denenen eşlemeler: ${errors.join(' | ')}',
    );
  }

  Future<MarketQuote> _requestQuote({
    required String symbol,
    String? exchange,
  }) async {
    final normalizedSymbol = _normalizeSymbol(symbol);

    final queryParameters = <String, String>{
      'symbol': normalizedSymbol,
      'apikey': _apiKey,
    };

    final normalizedExchange = exchange?.trim();
    if (normalizedExchange != null &&
        normalizedExchange.isNotEmpty) {
      queryParameters['exchange'] = normalizedExchange;
    }

    final uri = _baseUri.replace(
      path: '${_baseUri.path}/quote',
      queryParameters: queryParameters,
    );

    final http.Response response;

    try {
      response = await _client.get(uri).timeout(timeout);
    } catch (error) {
      throw MarketProviderException(
        providerId: id,
        message: 'Twelve Data bağlantısı kurulamadı.',
        cause: error,
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw MarketProviderException(
        providerId: id,
        message:
            'HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final payload = _decodePayload(response.body);

    _throwIfApiError(
      payload,
      symbol: normalizedSymbol,
    );

    return _mapQuote(
      payload,
      requestedSymbol: normalizedSymbol,
      requestedExchange: normalizedExchange,
    );
  }

  @override
  Future<List<MarketQuote>> getQuotes(
    List<String> symbols, {
    String? exchange,
  }) async {
    final normalizedSymbols = symbols
        .map(_normalizeSymbol)
        .where((symbol) => symbol.isNotEmpty)
        .toSet()
        .toList();

    if (normalizedSymbols.isEmpty) {
      return const [];
    }

    final results = <MarketQuote>[];
    final failures = <String>[];

    // Sequential requests are intentional for the first production-safe
    // version. This avoids sudden quota bursts on free/development plans.
    for (final symbol in normalizedSymbols) {
      try {
        results.add(
          await getQuote(
            symbol,
            exchange: exchange,
          ),
        );
      } on MarketProviderException {
        failures.add(symbol);
      }
    }

    if (results.isEmpty && failures.isNotEmpty) {
      throw MarketProviderException(
        providerId: id,
        message:
            'Hiçbir sembol için fiyat alınamadı: ${failures.join(', ')}',
      );
    }

    return results;
  }

  void close() {
    _client.close();
  }

  MarketQuote _mapQuote(
    Map<String, dynamic> payload, {
    required String requestedSymbol,
    required String? requestedExchange,
  }) {
    final symbol = _string(payload['symbol']).isEmpty
        ? requestedSymbol
        : _string(payload['symbol']).toUpperCase();

    final exchange = _firstNonEmpty([
      _string(payload['exchange']),
      _string(payload['mic_code']),
      requestedExchange ?? '',
      'GLOBAL',
    ]);

    final currency = _firstNonEmpty([
      _string(payload['currency']).toUpperCase(),
      _inferCurrency(symbol),
      'USD',
    ]);

    final price = _firstPositive([
      _toDouble(payload['close']),
      _toDouble(payload['price']),
      _toDouble(payload['last']),
    ]);

    if (price <= 0) {
      throw MarketProviderException(
        providerId: id,
        message: '$symbol için geçerli fiyat bulunamadı.',
      );
    }

    final change = _toDouble(payload['change']);
    final changePercent = _toDouble(
      payload['percent_change'],
    );

    return MarketQuote(
      symbol: symbol,
      name: _firstNonEmpty([
        _string(payload['name']),
        _string(payload['instrument_name']),
        symbol,
      ]),
      category: _inferCategory(
        symbol: symbol,
        type: _string(payload['type']),
        exchange: exchange,
      ),
      exchange: exchange,
      currency: currency,
      price: price,
      change: change,
      changePercent: changePercent,
      updatedAt: _parseUpdatedAt(payload),
      marketStatus: _parseMarketStatus(payload),
    );
  }

  Map<String, dynamic> _decodePayload(String body) {
    final Object? decoded;

    try {
      decoded = jsonDecode(body);
    } catch (error) {
      throw MarketProviderException(
        providerId: id,
        message: 'Twelve Data geçersiz JSON döndürdü.',
        cause: error,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw MarketProviderException(
        providerId: id,
        message: 'Twelve Data yanıt biçimi beklenenden farklı.',
      );
    }

    return decoded;
  }

  void _throwIfApiError(
    Map<String, dynamic> payload, {
    required String symbol,
  }) {
    final status = _string(payload['status']).toLowerCase();
    final code = _string(payload['code']);
    final message = _string(payload['message']);

    if (status == 'error' || message.isNotEmpty && code.isNotEmpty) {
      throw MarketProviderException(
        providerId: id,
        message: message.isEmpty
            ? '$symbol için Twelve Data hatası oluştu.'
            : message,
      );
    }
  }

  DateTime _parseUpdatedAt(Map<String, dynamic> payload) {
    final timestamp = _toInt(payload['timestamp']);
    if (timestamp > 0) {
      return DateTime.fromMillisecondsSinceEpoch(
        timestamp * 1000,
        isUtc: true,
      ).toLocal();
    }

    final datetime = _firstNonEmpty([
      _string(payload['datetime']),
      _string(payload['last_update_at']),
    ]);

    return DateTime.tryParse(datetime) ?? DateTime.now();
  }

  MarketStatus _parseMarketStatus(Map<String, dynamic> payload) {
    final raw = _firstNonEmpty([
      _string(payload['is_market_open']),
      _string(payload['market_status']),
      _string(payload['status']),
    ]).toLowerCase();

    if (raw == 'true' || raw == 'open') {
      return MarketStatus.open;
    }

    if (raw == 'false' || raw == 'closed') {
      return MarketStatus.closed;
    }

    if (raw.contains('pre')) {
      return MarketStatus.preMarket;
    }

    if (raw.contains('after')) {
      return MarketStatus.afterHours;
    }

    return MarketStatus.unknown;
  }

  AssetCategory _inferCategory({
    required String symbol,
    required String type,
    required String exchange,
  }) {
    final normalizedType = type.toLowerCase();
    final normalizedExchange = exchange.toUpperCase();

    if (_looksLikeForex(symbol, normalizedType)) {
      return AssetCategory.currency;
    }

    if (_looksLikeCommodity(symbol, normalizedType)) {
      return AssetCategory.commodity;
    }

    if (normalizedType.contains('etf')) {
      return AssetCategory.etf;
    }

    if (normalizedType.contains('index')) {
      return AssetCategory.marketIndex;
    }

    if (normalizedType.contains('fund')) {
      return AssetCategory.fund;
    }

    if (normalizedExchange.contains('BIST') ||
        normalizedExchange.contains('XIST')) {
      return AssetCategory.bist;
    }

    if (_isUsExchange(normalizedExchange)) {
      return AssetCategory.usStock;
    }

    if (_isEuropeanExchange(normalizedExchange)) {
      return AssetCategory.euStock;
    }

    if (_isAsianExchange(normalizedExchange)) {
      return AssetCategory.asiaStock;
    }

    return AssetCategory.unknown;
  }

  bool _looksLikeForex(String symbol, String type) {
    final normalized = symbol
        .replaceAll('/', '')
        .replaceAll('-', '')
        .toUpperCase();

    return type.contains('forex') ||
        type.contains('currency') ||
        RegExp(r'^[A-Z]{6}$').hasMatch(normalized);
  }

  bool _looksLikeCommodity(String symbol, String type) {
    final normalized = symbol.toUpperCase();

    const commoditySymbols = {
      'XAU/USD',
      'XAG/USD',
      'XPT/USD',
      'XPD/USD',
      'WTI/USD',
      'BRENT/USD',
      'NG/USD',
    };

    return type.contains('commodity') ||
        commoditySymbols.contains(normalized);
  }

  bool _isUsExchange(String exchange) {
    const exchanges = {
      'NASDAQ',
      'NYSE',
      'NYSE ARCA',
      'AMEX',
      'OTC',
      'XNAS',
      'XNYS',
      'ARCX',
    };

    return exchanges.any(exchange.contains);
  }

  bool _isEuropeanExchange(String exchange) {
    const markers = {
      'LSE',
      'XETRA',
      'FRANKFURT',
      'EURONEXT',
      'PARIS',
      'AMSTERDAM',
      'MILAN',
      'MADRID',
      'SWISS',
      'SIX',
      'XPAR',
      'XAMS',
      'XLON',
      'XETR',
      'XMIL',
      'XMAD',
      'XSWX',
    };

    return markers.any(exchange.contains);
  }

  bool _isAsianExchange(String exchange) {
    const markers = {
      'TOKYO',
      'TSE',
      'HONG KONG',
      'HKEX',
      'SINGAPORE',
      'SGX',
      'SHANGHAI',
      'SHENZHEN',
      'KOREA',
      'NSE',
      'BSE',
      'XTKS',
      'XHKG',
      'XSES',
      'XSHG',
      'XSHE',
      'XKRX',
      'XNSE',
      'XBOM',
    };

    return markers.any(exchange.contains);
  }

  String _inferCurrency(String symbol) {
    final normalized = symbol.toUpperCase();

    if (normalized.contains('/')) {
      final parts = normalized.split('/');
      if (parts.length == 2 && parts[1].length == 3) {
        return parts[1];
      }
    }

    return '';
  }

  String _normalizeSymbol(String symbol) {
    return symbol.trim().toUpperCase();
  }

  String _string(Object? value) {
    return value?.toString().trim() ?? '';
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }

  double _firstPositive(List<double> values) {
    for (final value in values) {
      if (value > 0) {
        return value;
      }
    }

    return 0;
  }

  double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
