import 'dart:async';

import '../cache/market_cache.dart';
import '../models/market_quote.dart';
import '../providers/market_provider.dart';

class MarketRepository {
  static const _requestTimeout = Duration(seconds: 20);

  MarketRepository({required MarketProvider provider, MarketCache? cache})
    : _provider = provider,
      _cache = cache ?? MarketCache();

  MarketProvider _provider;
  final MarketCache _cache;

  MarketProvider get provider => _provider;

  void replaceProvider(MarketProvider provider, {bool clearCache = true}) {
    _provider = provider;

    if (clearCache) {
      _cache.clear();
    }
  }

  Future<MarketQuote> getQuote(
    String symbol, {
    String? exchange,
    bool forceRefresh = false,
  }) async {
    final normalized = symbol.trim().toUpperCase();

    if (normalized.isEmpty) {
      throw ArgumentError.value(symbol, 'symbol', 'Sembol boş olamaz.');
    }

    final cacheExchange = exchange?.trim() ?? '';

    if (!forceRefresh) {
      final cached = _cache.get(normalized, exchange: cacheExchange);

      if (cached != null) {
        return cached;
      }
    }

    if (!_provider.supportsSymbol(normalized, exchange: exchange)) {
      throw MarketProviderException(
        providerId: _provider.id,
        message: 'Sağlayıcı sembolü desteklemiyor: $normalized',
      );
    }

    final quote = await _provider
        .getQuote(normalized, exchange: exchange)
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException(
            '$normalized fiyat isteği zaman aşımına uğradı.',
            _requestTimeout,
          ),
        );

    _cache.put(quote, exchange: cacheExchange);

    return quote;
  }

  Future<List<MarketQuote>> getQuotes(
    List<String> symbols, {
    String? exchange,
    bool forceRefresh = false,
  }) async {
    final normalized = symbols
        .map((symbol) => symbol.trim().toUpperCase())
        .where((symbol) => symbol.isNotEmpty)
        .toSet()
        .toList();

    final cacheExchange = exchange?.trim() ?? '';
    final bySymbol = <String, MarketQuote>{};
    final missing = <String>[];

    for (final symbol in normalized) {
      final cached = forceRefresh
          ? null
          : _cache.get(symbol, exchange: cacheExchange);
      if (cached == null) {
        missing.add(symbol);
      } else {
        bySymbol[symbol] = cached;
      }
    }

    if (missing.isNotEmpty) {
      final fetched = await _provider
          .getQuotes(missing, exchange: exchange)
          .timeout(
            _requestTimeout,
            onTimeout: () => throw TimeoutException(
              'Toplu fiyat isteği zaman aşımına uğradı.',
              _requestTimeout,
            ),
          );
      for (final quote in fetched) {
        final symbol = quote.symbol.trim().toUpperCase();
        bySymbol[symbol] = quote;
        _cache.put(quote, exchange: cacheExchange);
      }
    }

    return normalized
        .map((symbol) => bySymbol[symbol])
        .whereType<MarketQuote>()
        .toList(growable: false);
  }

  void clearCache() {
    _cache.clear();
  }
}
