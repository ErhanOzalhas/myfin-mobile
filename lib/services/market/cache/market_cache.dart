import '../models/market_quote.dart';

class MarketCache {
  MarketCache({
    this.ttl = const Duration(seconds: 30),
  });

  final Duration ttl;
  final Map<String, _CacheEntry> _entries = {};

  MarketQuote? get(
    String symbol, {
    String? exchange,
  }) {
    final key = _key(symbol, exchange);
    final entry = _entries[key];

    if (entry == null) return null;

    if (DateTime.now().difference(entry.savedAt) > ttl) {
      _entries.remove(key);
      return null;
    }

    return entry.quote;
  }

  void put(
    MarketQuote quote, {
    String? exchange,
  }) {
    _entries[_key(quote.symbol, exchange ?? quote.exchange)] =
        _CacheEntry(
      quote: quote,
      savedAt: DateTime.now(),
    );
  }

  void putAll(Iterable<MarketQuote> quotes) {
    for (final quote in quotes) {
      put(quote);
    }
  }

  void invalidate(
    String symbol, {
    String? exchange,
  }) {
    _entries.remove(_key(symbol, exchange));
  }

  void clear() {
    _entries.clear();
  }

  String _key(
    String symbol,
    String? exchange,
  ) {
    final normalizedSymbol = symbol.trim().toUpperCase();
    final normalizedExchange =
        (exchange ?? '').trim().toUpperCase();

    return '$normalizedExchange::$normalizedSymbol';
  }
}

class _CacheEntry {
  final MarketQuote quote;
  final DateTime savedAt;

  const _CacheEntry({
    required this.quote,
    required this.savedAt,
  });
}
