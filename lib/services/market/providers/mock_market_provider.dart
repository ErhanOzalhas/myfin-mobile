import '../models/asset_category.dart';
import '../models/market_quote.dart';
import 'market_provider.dart';

class MockMarketProvider implements MarketProvider {
  MockMarketProvider({
    Map<String, MarketQuote>? seedQuotes,
  }) : _quotes = {
          ..._defaultQuotes(),
          ...?seedQuotes?.map(
            (key, value) => MapEntry(key.toUpperCase(), value),
          ),
        };

  final Map<String, MarketQuote> _quotes;

  @override
  String get id => 'mock';

  @override
  bool supportsSymbol(
    String symbol, {
    String? exchange,
  }) {
    return _quotes.containsKey(symbol.trim().toUpperCase());
  }

  @override
  Future<MarketQuote> getQuote(
    String symbol, {
    String? exchange,
  }) async {
    final normalized = symbol.trim().toUpperCase();
    final quote = _quotes[normalized];

    if (quote == null) {
      throw MarketProviderException(
        providerId: id,
        message: 'Mock quote bulunamadı: $normalized',
      );
    }

    return quote.copyWith(updatedAt: DateTime.now());
  }

  @override
  Future<List<MarketQuote>> getQuotes(
    List<String> symbols, {
    String? exchange,
  }) async {
    final results = <MarketQuote>[];

    for (final symbol in symbols) {
      results.add(
        await getQuote(
          symbol,
          exchange: exchange,
        ),
      );
    }

    return results;
  }

  static Map<String, MarketQuote> _defaultQuotes() {
    final now = DateTime.now();

    return {
      'ASELS': MarketQuote(
        symbol: 'ASELS',
        name: 'Aselsan',
        category: AssetCategory.bist,
        exchange: 'BIST',
        currency: 'TRY',
        price: 184.20,
        change: 2.40,
        changePercent: 1.32,
        updatedAt: now,
        marketStatus: MarketStatus.open,
      ),
      'AAPL': MarketQuote(
        symbol: 'AAPL',
        name: 'Apple Inc.',
        category: AssetCategory.usStock,
        exchange: 'NASDAQ',
        currency: 'USD',
        price: 245.80,
        change: 1.72,
        changePercent: 0.70,
        updatedAt: now,
        marketStatus: MarketStatus.open,
      ),
      'BTC': MarketQuote(
        symbol: 'BTC',
        name: 'Bitcoin',
        category: AssetCategory.crypto,
        exchange: 'CRYPTO',
        currency: 'USD',
        price: 118250,
        change: 1320,
        changePercent: 1.13,
        updatedAt: now,
        marketStatus: MarketStatus.alwaysOpen,
      ),
      'USDTRY': MarketQuote(
        symbol: 'USDTRY',
        name: 'ABD Doları / Türk Lirası',
        category: AssetCategory.currency,
        exchange: 'FX',
        currency: 'TRY',
        price: 42.50,
        change: 0.10,
        changePercent: 0.24,
        updatedAt: now,
        marketStatus: MarketStatus.open,
      ),
      'GRAM_ALTIN': MarketQuote(
        symbol: 'GRAM_ALTIN',
        name: 'Gram Altın',
        category: AssetCategory.commodity,
        exchange: 'TR',
        currency: 'TRY',
        price: 4380,
        change: 18,
        changePercent: 0.41,
        updatedAt: now,
        marketStatus: MarketStatus.open,
      ),
    };
  }
}
