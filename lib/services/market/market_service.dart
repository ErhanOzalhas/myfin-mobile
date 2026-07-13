import 'cache/market_cache.dart';
import 'models/market_quote.dart';
import 'providers/market_provider.dart';
import 'providers/router_market_provider.dart';
import 'repository/market_repository.dart';

class MarketService {
  MarketService._();

  static final MarketService instance = MarketService._();

  late MarketRepository _repository = MarketRepository(
    provider: RouterMarketProvider(),
    cache: MarketCache(
      ttl: const Duration(seconds: 30),
    ),
  );

  MarketRepository get repository => _repository;

  void configure({
    required MarketProvider provider,
    Duration cacheTtl = const Duration(seconds: 30),
  }) {
    _repository = MarketRepository(
      provider: provider,
      cache: MarketCache(ttl: cacheTtl),
    );
  }

  Future<MarketQuote> getQuote(
    String symbol, {
    String? exchange,
    bool forceRefresh = false,
  }) {
    return _repository.getQuote(
      symbol,
      exchange: exchange,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<MarketQuote>> getQuotes(
    List<String> symbols, {
    String? exchange,
    bool forceRefresh = false,
  }) {
    return _repository.getQuotes(
      symbols,
      exchange: exchange,
      forceRefresh: forceRefresh,
    );
  }

  void clearCache() {
    _repository.clearCache();
  }
}
