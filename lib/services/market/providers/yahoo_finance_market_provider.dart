import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/asset_category.dart';
import '../models/market_quote.dart';
import 'market_provider.dart';
import 'provider_symbol_mapping.dart';

class YahooFinanceMarketProvider implements MarketProvider {
  YahooFinanceMarketProvider({
    http.Client? client,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client(),
       _baseUri = baseUri ?? Uri.parse('https://query2.finance.yahoo.com');

  final http.Client _client;
  final Uri _baseUri;
  final Duration timeout;

  @override
  String get id => 'yahoo_finance';

  @override
  bool supportsSymbol(String symbol, {String? exchange}) {
    final value = symbol.trim();
    if (value.isEmpty) return false;
    if (value.contains('/') &&
        !_commodityFuturesSymbols.containsKey(value.toUpperCase())) {
      return false;
    }
    return true;
  }

  @override
  Future<MarketQuote> getQuote(String symbol, {String? exchange}) async {
    final yahooSymbol = _toYahooSymbol(symbol, exchange: exchange);

    final uri = _baseUri.replace(
      path: '/v8/finance/chart/$yahooSymbol',
      queryParameters: const {
        'interval': '1d',
        'range': '5d',
        'includePrePost': 'false',
      },
    );

    final http.Response response;

    try {
      response = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'Mozilla/5.0 MyFin/1.0',
            },
          )
          .timeout(timeout);
    } catch (error) {
      throw MarketProviderException(
        providerId: id,
        message: 'Yahoo Finance bağlantısı kurulamadı.',
        cause: error,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MarketProviderException(
        providerId: id,
        message:
            'Yahoo Finance HTTP ${response.statusCode}: '
            '${response.body}',
      );
    }

    final Object? decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (error) {
      throw MarketProviderException(
        providerId: id,
        message: 'Yahoo Finance geçersiz JSON döndürdü.',
        cause: error,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw MarketProviderException(
        providerId: id,
        message: 'Yahoo Finance yanıt biçimi beklenenden farklı.',
      );
    }

    final chart = decoded['chart'];
    if (chart is! Map<String, dynamic>) {
      throw MarketProviderException(
        providerId: id,
        message: '$symbol için Yahoo Finance chart verisi yok.',
      );
    }

    final error = chart['error'];
    if (error != null) {
      throw MarketProviderException(
        providerId: id,
        message: '$symbol için Yahoo Finance hatası: $error',
      );
    }

    final result = chart['result'];
    if (result is! List || result.isEmpty) {
      throw MarketProviderException(
        providerId: id,
        message: '$symbol için Yahoo Finance sonucu bulunamadı.',
      );
    }

    final first = result.first;
    if (first is! Map) {
      throw MarketProviderException(
        providerId: id,
        message: '$symbol için Yahoo Finance sonucu geçersiz.',
      );
    }

    final data = Map<String, dynamic>.from(first);
    final meta = data['meta'];

    if (meta is! Map) {
      throw MarketProviderException(
        providerId: id,
        message: '$symbol için Yahoo Finance meta verisi yok.',
      );
    }

    final metaMap = Map<String, dynamic>.from(meta);

    final rawCurrentPrice = _firstPositive([
      _toDouble(metaMap['regularMarketPrice']),
      _toDouble(metaMap['previousClose']),
      _lastClose(data),
    ]);

    if (rawCurrentPrice <= 0) {
      throw MarketProviderException(
        providerId: id,
        message: '$symbol için Yahoo Finance fiyatı bulunamadı.',
      );
    }

    final rawPreviousClose = _firstPositive([
      _toDouble(metaMap['chartPreviousClose']),
      _toDouble(metaMap['previousClose']),
    ]);

    final normalizedSymbol = symbol.trim().toUpperCase();
    // Yahoo quotes wheat futures in US cents per bushel (USX). The asset is
    // exposed as WHEAT/USD, so normalize cents to dollars before returning it.
    final quoteScale = normalizedSymbol == 'WHEAT/USD' ? 0.01 : 1.0;
    final currentPrice = rawCurrentPrice * quoteScale;
    final previousClose = rawPreviousClose * quoteScale;

    final change = previousClose > 0 ? currentPrice - previousClose : 0.0;
    final changePercent = previousClose > 0
        ? (change / previousClose) * 100
        : 0.0;

    final rawCurrency = (metaMap['currency'] ?? _inferCurrency(exchange))
        .toString()
        .toUpperCase();
    final currency = normalizedSymbol == 'WHEAT/USD' ? 'USD' : rawCurrency;

    final exchangeName =
        (metaMap['exchangeName'] ??
                metaMap['fullExchangeName'] ??
                ProviderSymbolMapping.normalizeExchange(exchange) ??
                'GLOBAL')
            .toString();

    final timestamp = _toInt(metaMap['regularMarketTime']);

    return MarketQuote(
      symbol: normalizedSymbol,
      name:
          (metaMap['longName'] ??
                  metaMap['shortName'] ??
                  symbol.trim().toUpperCase())
              .toString(),
      category: _inferCategory(exchangeName),
      exchange: exchangeName,
      currency: currency,
      price: currentPrice,
      change: change,
      changePercent: changePercent,
      updatedAt: timestamp > 0
          ? DateTime.fromMillisecondsSinceEpoch(
              timestamp * 1000,
              isUtc: true,
            ).toLocal()
          : DateTime.now(),
      marketStatus: _parseMarketStatus(metaMap['marketState']),
    );
  }

  MarketStatus _parseMarketStatus(Object? value) {
    return switch (value?.toString().trim().toUpperCase()) {
      'REGULAR' || 'OPEN' => MarketStatus.open,
      'PRE' || 'PREPRE' => MarketStatus.preMarket,
      'POST' || 'POSTPOST' => MarketStatus.afterHours,
      'CLOSED' => MarketStatus.closed,
      _ => MarketStatus.unknown,
    };
  }

  @override
  Future<List<MarketQuote>> getQuotes(
    List<String> symbols, {
    String? exchange,
  }) async {
    final quotes = <MarketQuote>[];

    for (final symbol in symbols.toSet()) {
      try {
        quotes.add(await getQuote(symbol, exchange: exchange));
      } on MarketProviderException {
        // Partial success.
      }
    }

    return quotes;
  }

  String _toYahooSymbol(String symbol, {String? exchange}) {
    final normalizedSymbol = symbol.trim().toUpperCase();
    final normalizedExchange = ProviderSymbolMapping.normalizeExchange(
      exchange,
    );

    // Yahoo spot metal pairs do not have chart endpoints. Their liquid front
    // month futures are used only as the fallback after the spot provider has
    // failed, so the UI can still show a timely market reference value.
    final commodityFuture = _commodityFuturesSymbols[normalizedSymbol];
    if (commodityFuture != null) return commodityFuture;

    if (normalizedSymbol.contains('.')) {
      return normalizedSymbol;
    }

    final suffix = switch (normalizedExchange) {
      'XIST' => '.IS',
      'XLON' => '.L',
      'XETR' => '.DE',
      'XPAR' => '.PA',
      'XAMS' => '.AS',
      'XMIL' => '.MI',
      'XMAD' => '.MC',
      'XSWX' => '.SW',
      'XTKS' => '.T',
      'XHKG' => '.HK',
      'XTSE' => '.TO',
      'XASX' => '.AX',
      _ => '',
    };

    return '$normalizedSymbol$suffix';
  }

  static const Map<String, String> _commodityFuturesSymbols = {
    'XAG/USD': 'SI=F',
    'XPT/USD': 'PL=F',
    'XPD/USD': 'PA=F',
    // API Ninjas free access rotates weekly. Keep liquid front-month
    // contracts as fallbacks so these portfolio assets remain usable.
    'BRENT/USD': 'BZ=F',
    'WHEAT/USD': 'ZW=F',
  };

  double _lastClose(Map<String, dynamic> data) {
    final indicators = data['indicators'];
    if (indicators is! Map) return 0;

    final quote = indicators['quote'];
    if (quote is! List || quote.isEmpty) return 0;

    final first = quote.first;
    if (first is! Map) return 0;

    final closes = first['close'];
    if (closes is! List) return 0;

    for (final value in closes.reversed) {
      final parsed = _toDouble(value);
      if (parsed > 0) return parsed;
    }

    return 0;
  }

  AssetCategory _inferCategory(String exchange) {
    final value = exchange.toUpperCase();

    if (value.contains('IST') || value.contains('BIST')) {
      return AssetCategory.bist;
    }
    if (value.contains('NASDAQ') ||
        value.contains('NYSE') ||
        value.contains('NMS') ||
        value.contains('NYQ')) {
      return AssetCategory.usStock;
    }
    if (value.contains('LSE') ||
        value.contains('XETRA') ||
        value.contains('PARIS') ||
        value.contains('MILAN')) {
      return AssetCategory.euStock;
    }

    return AssetCategory.unknown;
  }

  String _inferCurrency(String? exchange) {
    return switch (ProviderSymbolMapping.normalizeExchange(exchange)) {
      'XIST' => 'TRY',
      'XLON' => 'GBP',
      'XETR' || 'XPAR' || 'XAMS' || 'XMIL' || 'XMAD' => 'EUR',
      'XTKS' => 'JPY',
      'XHKG' => 'HKD',
      'XTSE' => 'CAD',
      'XASX' => 'AUD',
      _ => 'USD',
    };
  }

  double _firstPositive(List<double> values) {
    for (final value in values) {
      if (value > 0) return value;
    }
    return 0;
  }

  double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void close() {
    _client.close();
  }
}
