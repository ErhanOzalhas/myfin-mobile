import '../cache/market_cache.dart';
import '../models/market_quote.dart';
import '../providers/market_provider.dart';

class MarketRepository {
  MarketRepository({
    required MarketProvider provider,
    MarketCache? cache,
  })  : _provider = provider,
        _cache = cache ?? MarketCache();

  MarketProvider _provider;
  final MarketCache _cache;

  MarketProvider get provider => _provider;

  void replaceProvider(
    MarketProvider provider, {
    bool clearCache = true,
  }) {
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
      throw ArgumentError.value(
        symbol,
        'symbol',
        'Sembol boş olamaz.',
      );
    }

    final cacheExchange = exchange?.trim() ?? '';

    if (!forceRefresh) {
      final cached = _cache.get(
        normalized,
        exchange: cacheExchange,
      );

      if (cached != null) {
        return cached;
      }
    }

    if (!_provider.supportsSymbol(
      normalized,
      exchange: exchange,
    )) {
      throw MarketProviderException(
        providerId: _provider.id,
        message: 'Sağlayıcı sembolü desteklemiyor: $normalized',
      );
    }

    final quote = await _provider.getQuote(
      normalized,
      exchange: exchange,
    );

    _cache.put(
      quote,
      exchange: cacheExchange,
    );

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

    final results = <MarketQuote>[];

    for (final symbol in normalized) {
      results.add(
        await getQuote(
          symbol,
          exchange: exchange,
          forceRefresh: forceRefresh,
        ),
      );
    }

    return results;
  }

  void clearCache() {
    _cache.clear();
  }
}
