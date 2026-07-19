import '../catalog/asset_universe.dart';
import '../models/market_quote.dart';
import 'api_ninjas_commodity_provider.dart';
import 'binance_market_provider.dart';
import 'coinbase_market_provider.dart';
import 'coingecko_market_provider.dart';
import 'genel_para_provider.dart';
import 'market_provider.dart';
import 'market_symbol_resolver.dart';
import 'nosy_turkey_gold_provider.dart';
import 'tcmb_market_provider.dart';
import 'twelve_data_market_provider.dart';
import 'yahoo_finance_market_provider.dart';

class RouterMarketProvider implements MarketProvider {
  RouterMarketProvider({
    CoinGeckoMarketProvider? coinGeckoProvider,
    BinanceMarketProvider? binanceProvider,
    CoinbaseMarketProvider? coinbaseProvider,
    TwelveDataMarketProvider? globalProvider,
    YahooFinanceMarketProvider? yahooProvider,
    GenelParaProvider? genelParaProvider,
    NosyTurkeyGoldProvider? turkeyGoldProvider,
    TcmbMarketProvider? tcmbProvider,
    ApiNinjasCommodityProvider? commodityProvider,
    this.enableNosyFallback = false,
  }) : _coinGeckoProvider = coinGeckoProvider ?? CoinGeckoMarketProvider(),
       _globalProvider = globalProvider ?? TwelveDataMarketProvider(),
       _binanceProvider = binanceProvider ?? BinanceMarketProvider(),
       _coinbaseProvider = coinbaseProvider ?? CoinbaseMarketProvider(),
       _yahooProvider = yahooProvider ?? YahooFinanceMarketProvider(),
       _genelParaProvider = genelParaProvider ?? GenelParaProvider(),
       _turkeyGoldProvider = turkeyGoldProvider ?? NosyTurkeyGoldProvider(),
       _tcmbProvider = tcmbProvider ?? TcmbMarketProvider(),
       _commodityProvider = commodityProvider ?? ApiNinjasCommodityProvider();

  final CoinGeckoMarketProvider _coinGeckoProvider;
  final BinanceMarketProvider _binanceProvider;
  final CoinbaseMarketProvider _coinbaseProvider;
  final TwelveDataMarketProvider _globalProvider;
  final YahooFinanceMarketProvider _yahooProvider;

  /// Geliştirme sırasında yerel altın için birincil sağlayıcı.
  final GenelParaProvider _genelParaProvider;

  /// GenelPara başarısız olduğunda devreye giren yedek sağlayıcı.
  final NosyTurkeyGoldProvider _turkeyGoldProvider;

  /// NOSY istekleri kredi tükettiği için varsayılan olarak devre dışıdır.
  /// Yalnızca GenelPara'nın karşılamadığı bir ürün gerektiğinde açılmalıdır.
  final bool enableNosyFallback;

  final TcmbMarketProvider _tcmbProvider;
  final ApiNinjasCommodityProvider _commodityProvider;

  @override
  String get id => 'market_router';

  @override
  bool supportsSymbol(String symbol, {String? exchange}) {
    final resolved = MarketSymbolResolver.resolve(symbol, exchange: exchange);

    if (resolved.requestedSymbol.isEmpty) {
      return false;
    }

    if (_isLocalGold(
      requestedSymbol: resolved.requestedSymbol,
      providerSymbol: resolved.providerSymbol,
      exchange: resolved.exchange,
      resolverMarkedLocal: resolved.isLocalTurkishGold,
    )) {
      return true;
    }

    if (_commodityProvider.supportsSymbol(
      resolved.providerSymbol,
      exchange: resolved.exchange,
    )) {
      return true;
    }

    return _coinGeckoProvider.supportsSymbol(
          resolved.providerSymbol,
          exchange: resolved.exchange,
        ) ||
        _globalProvider.supportsSymbol(
          resolved.providerSymbol,
          exchange: resolved.exchange,
        ) ||
        _yahooProvider.supportsSymbol(
          resolved.providerSymbol,
          exchange: resolved.exchange,
        ) ||
        _tcmbProvider.supportsSymbol(
          resolved.providerSymbol,
          exchange: resolved.exchange,
        );
  }

  @override
  Future<MarketQuote> getQuote(String symbol, {String? exchange}) async {
    final resolved = MarketSymbolResolver.resolve(symbol, exchange: exchange);

    if (_isLocalGold(
      requestedSymbol: resolved.requestedSymbol,
      providerSymbol: resolved.providerSymbol,
      exchange: resolved.exchange,
      resolverMarkedLocal: resolved.isLocalTurkishGold,
    )) {
      return _getLocalGoldQuote(
        requestedSymbol: resolved.requestedSymbol,
        providerSymbol: resolved.providerSymbol,
        exchange: resolved.exchange,
      );
    }

    if (_coinGeckoMarket(resolved.providerSymbol, resolved.exchange)) {
      return _getCryptoQuote(
        resolved.providerSymbol,
        exchange: resolved.exchange,
      );
    }

    if (_commodityProvider.supportsSymbol(
      resolved.providerSymbol,
      exchange: resolved.exchange,
    )) {
      try {
        return await _commodityProvider.getQuote(
          resolved.providerSymbol,
          exchange: resolved.exchange,
        );
      } on MarketProviderException {
        // Yapılandırma tamamlanana kadar mevcut global sağlayıcılara düş.
      }
    }

    final isTryPair = _tcmbProvider.supportsSymbol(
      resolved.providerSymbol,
      exchange: resolved.exchange,
    );

    MarketProviderException? twelveError;

    try {
      return await _globalProvider.getQuote(
        resolved.providerSymbol,
        exchange: resolved.exchange,
      );
    } on MarketProviderException catch (error) {
      twelveError = error;
    }

    if (isTryPair) {
      return _tcmbProvider.getQuote(
        resolved.providerSymbol,
        exchange: resolved.exchange,
      );
    }

    try {
      return await _yahooProvider.getQuote(
        resolved.providerSymbol,
        exchange: resolved.exchange,
      );
    } on MarketProviderException catch (yahooError) {
      throw MarketProviderException(
        providerId: id,
        message:
            '${resolved.requestedSymbol} için fiyat alınamadı. '
            'Twelve Data: ${twelveError.message} | '
            'Yahoo: ${yahooError.message}',
      );
    }
  }

  Future<MarketQuote> _getCryptoQuote(String symbol, {String? exchange}) async {
    MarketProviderException? coinGeckoError;
    MarketProviderException? binanceError;
    try {
      return await _coinGeckoProvider.getQuote(symbol, exchange: exchange);
    } on MarketProviderException catch (error) {
      coinGeckoError = error;
    }
    try {
      return await _binanceProvider.getQuote(symbol, exchange: exchange);
    } on MarketProviderException catch (error) {
      binanceError = error;
    }
    try {
      return await _coinbaseProvider.getQuote(symbol, exchange: exchange);
    } on MarketProviderException catch (coinbaseError) {
      throw MarketProviderException(
        providerId: id,
        message:
            '$symbol için kripto fiyatı alınamadı. '
            'CoinGecko: ${coinGeckoError.message} | '
            'Binance: ${binanceError.message} | '
            'Coinbase: ${coinbaseError.message}',
      );
    }
  }

  Future<MarketQuote> _getLocalGoldQuote({
    required String requestedSymbol,
    required String providerSymbol,
    String? exchange,
  }) async {
    MarketProviderException? genelParaError;

    final genelParaSymbol =
        _genelParaProvider.supportsSymbol(providerSymbol, exchange: exchange)
        ? providerSymbol
        : requestedSymbol;

    if (_genelParaProvider.supportsSymbol(
      genelParaSymbol,
      exchange: exchange,
    )) {
      try {
        return await _genelParaProvider.getQuote(
          genelParaSymbol,
          exchange: exchange,
        );
      } on MarketProviderException catch (error) {
        genelParaError = error;
      }
    }

    final nosySymbol = enableNosyFallback
        ? (_turkeyGoldProvider.supportsSymbol(
                providerSymbol,
                exchange: exchange,
              )
              ? providerSymbol
              : requestedSymbol)
        : null;

    if (nosySymbol != null &&
        _turkeyGoldProvider.supportsSymbol(nosySymbol, exchange: exchange)) {
      try {
        return await _turkeyGoldProvider.getQuote(
          nosySymbol,
          exchange: exchange,
        );
      } on MarketProviderException catch (nosyError) {
        throw MarketProviderException(
          providerId: id,
          message:
              '$requestedSymbol için yerel altın fiyatı alınamadı. '
              'GenelPara: ${genelParaError?.message ?? "desteklenmiyor"} | '
              'Nosy: ${nosyError.message}',
        );
      }
    }

    throw MarketProviderException(
      providerId: id,
      message:
          '$requestedSymbol için yerel altın sağlayıcısı bulunamadı. '
          'GenelPara: ${genelParaError?.message ?? "desteklenmiyor"}',
    );
  }

  bool _isLocalGold({
    required String requestedSymbol,
    required String providerSymbol,
    required String? exchange,
    required bool resolverMarkedLocal,
  }) {
    if (resolverMarkedLocal) {
      return true;
    }

    return _genelParaProvider.supportsSymbol(
          providerSymbol,
          exchange: exchange,
        ) ||
        _genelParaProvider.supportsSymbol(
          requestedSymbol,
          exchange: exchange,
        ) ||
        (enableNosyFallback &&
            (_turkeyGoldProvider.supportsSymbol(
                  providerSymbol,
                  exchange: exchange,
                ) ||
                _turkeyGoldProvider.supportsSymbol(
                  requestedSymbol,
                  exchange: exchange,
                )));
  }

  bool _coinGeckoMarket(String symbol, String? exchange) {
    return exchange?.toUpperCase() == 'CRYPTO' ||
        _coinGeckoProvider.supportsSymbol(symbol, exchange: exchange);
  }

  @override
  Future<List<MarketQuote>> getQuotes(
    List<String> symbols, {
    String? exchange,
  }) async {
    final normalizedExchange = exchange?.trim().toUpperCase();
    if (normalizedExchange == 'CRYPTO') {
      return _getCryptoQuotes(symbols);
    }

    final results = <MarketQuote>[];

    for (final symbol in symbols.toSet()) {
      try {
        results.add(await getQuote(symbol, exchange: exchange));
      } on MarketProviderException {
        // Portföy ekranlarında kısmi başarı tercih edilir.
      }
    }

    return results;
  }

  Future<List<MarketQuote>> _getCryptoQuotes(List<String> symbols) async {
    final normalized = symbols
        .map((symbol) => symbol.trim().toUpperCase())
        .where((symbol) => symbol.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final bySymbol = <String, MarketQuote>{};

    try {
      for (final quote in await _coinGeckoProvider.getQuotes(
        normalized,
        exchange: 'CRYPTO',
      )) {
        bySymbol[quote.symbol.toUpperCase()] = quote;
      }
    } on MarketProviderException {
      // Eksik semboller aşağıdaki ücretsiz yedeklerden tamamlanır.
    }

    var missing = normalized.where((symbol) => !bySymbol.containsKey(symbol));
    for (final quote in await _binanceProvider.getQuotes(
      missing.toList(growable: false),
      exchange: 'CRYPTO',
    )) {
      bySymbol[quote.symbol.toUpperCase()] = quote;
    }

    missing = normalized.where((symbol) => !bySymbol.containsKey(symbol));
    for (final quote in await _coinbaseProvider.getQuotes(
      missing.toList(growable: false),
      exchange: 'CRYPTO',
    )) {
      bySymbol[quote.symbol.toUpperCase()] = quote;
    }

    return normalized
        .map((symbol) => bySymbol[symbol])
        .whereType<MarketQuote>()
        .toList(growable: false);
  }

  bool isRegisteredLocalGold(String symbol) {
    return AssetUniverse.isLocalGold(symbol) ||
        _genelParaProvider.supportsSymbol(symbol) ||
        (enableNosyFallback && _turkeyGoldProvider.supportsSymbol(symbol));
  }

  void close() {
    _coinGeckoProvider.close();
    _binanceProvider.close();
    _coinbaseProvider.close();
    _globalProvider.close();
    _yahooProvider.close();
    _genelParaProvider.close();
    _turkeyGoldProvider.close();
    _tcmbProvider.close();
  }
}
