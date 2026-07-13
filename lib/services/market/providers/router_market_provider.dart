import '../catalog/asset_universe.dart';
import '../models/market_quote.dart';
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
    TwelveDataMarketProvider? globalProvider,
    YahooFinanceMarketProvider? yahooProvider,
    GenelParaProvider? genelParaProvider,
    NosyTurkeyGoldProvider? turkeyGoldProvider,
    TcmbMarketProvider? tcmbProvider,
  })  : _coinGeckoProvider =
            coinGeckoProvider ?? CoinGeckoMarketProvider(),
        _globalProvider =
            globalProvider ?? TwelveDataMarketProvider(),
        _yahooProvider =
            yahooProvider ?? YahooFinanceMarketProvider(),
        _genelParaProvider =
            genelParaProvider ?? GenelParaProvider(),
        _turkeyGoldProvider =
            turkeyGoldProvider ?? NosyTurkeyGoldProvider(),
        _tcmbProvider = tcmbProvider ?? TcmbMarketProvider();

  final CoinGeckoMarketProvider _coinGeckoProvider;
  final TwelveDataMarketProvider _globalProvider;
  final YahooFinanceMarketProvider _yahooProvider;

  /// Geliştirme sırasında yerel altın için birincil sağlayıcı.
  final GenelParaProvider _genelParaProvider;

  /// GenelPara başarısız olduğunda devreye giren yedek sağlayıcı.
  final NosyTurkeyGoldProvider _turkeyGoldProvider;

  final TcmbMarketProvider _tcmbProvider;

  @override
  String get id => 'market_router';

  @override
  bool supportsSymbol(
    String symbol, {
    String? exchange,
  }) {
    final resolved = MarketSymbolResolver.resolve(
      symbol,
      exchange: exchange,
    );

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
  Future<MarketQuote> getQuote(
    String symbol, {
    String? exchange,
  }) async {
    final resolved = MarketSymbolResolver.resolve(
      symbol,
      exchange: exchange,
    );

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

    if (_coinGeckoMarket(
      resolved.providerSymbol,
      resolved.exchange,
    )) {
      return _coinGeckoProvider.getQuote(
        resolved.providerSymbol,
        exchange: resolved.exchange,
      );
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
            'Twelve Data: ${twelveError?.message ?? "-"} | '
            'Yahoo: ${yahooError.message}',
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
        _genelParaProvider.supportsSymbol(
      providerSymbol,
      exchange: exchange,
    )
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

    final nosySymbol = _turkeyGoldProvider.supportsSymbol(
      providerSymbol,
      exchange: exchange,
    )
        ? providerSymbol
        : requestedSymbol;

    if (_turkeyGoldProvider.supportsSymbol(
      nosySymbol,
      exchange: exchange,
    )) {
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
        _turkeyGoldProvider.supportsSymbol(
          providerSymbol,
          exchange: exchange,
        ) ||
        _turkeyGoldProvider.supportsSymbol(
          requestedSymbol,
          exchange: exchange,
        );
  }

  bool _coinGeckoMarket(
    String symbol,
    String? exchange,
  ) {
    return exchange?.toUpperCase() == 'CRYPTO' ||
        _coinGeckoProvider.supportsSymbol(
          symbol,
          exchange: exchange,
        );
  }

  @override
  Future<List<MarketQuote>> getQuotes(
    List<String> symbols, {
    String? exchange,
  }) async {
    final results = <MarketQuote>[];

    for (final symbol in symbols.toSet()) {
      try {
        results.add(
          await getQuote(
            symbol,
            exchange: exchange,
          ),
        );
      } on MarketProviderException {
        // Portföy ekranlarında kısmi başarı tercih edilir.
      }
    }

    return results;
  }

  bool isRegisteredLocalGold(String symbol) {
    return AssetUniverse.isLocalGold(symbol) ||
        _genelParaProvider.supportsSymbol(symbol) ||
        _turkeyGoldProvider.supportsSymbol(symbol);
  }

  void close() {
    _coinGeckoProvider.close();
    _globalProvider.close();
    _yahooProvider.close();
    _genelParaProvider.close();
    _turkeyGoldProvider.close();
    _tcmbProvider.close();
  }
}
