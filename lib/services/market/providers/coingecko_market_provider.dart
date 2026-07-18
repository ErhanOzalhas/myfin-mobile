import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/asset_category.dart';
import '../models/market_quote.dart';
import '../search/coingecko_coin_index.dart';
import 'market_provider.dart';

class CoinGeckoMarketProvider implements MarketProvider {
  CoinGeckoMarketProvider({
    http.Client? client,
    Uri? baseUri,
    this.vsCurrency = 'usd',
    this.timeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client(),
       _baseUri = baseUri ?? Uri.parse('https://api.coingecko.com/api/v3');

  final http.Client _client;
  final Uri _baseUri;
  final String vsCurrency;
  final Duration timeout;

  static const Map<String, String> _popularCoinIds = {
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'SOL': 'solana',
    'BNB': 'binancecoin',
    'XRP': 'ripple',
    'ADA': 'cardano',
    'DOGE': 'dogecoin',
    'AVAX': 'avalanche-2',
    'DOT': 'polkadot',
    'LINK': 'chainlink',
    'MATIC': 'matic-network',
    'LTC': 'litecoin',
    'TRX': 'tron',
    'UNI': 'uniswap',
    'ATOM': 'cosmos',
  };

  @override
  String get id => 'coingecko';

  @override
  bool supportsSymbol(String symbol, {String? exchange}) {
    final normalizedExchange = exchange?.trim().toUpperCase();

    return normalizedExchange == 'CRYPTO' ||
        _popularCoinIds.containsKey(_normalizeSymbol(symbol));
  }

  @override
  Future<MarketQuote> getQuote(String symbol, {String? exchange}) async {
    final normalized = _normalizeSymbol(symbol);

    final coinId =
        _popularCoinIds[normalized] ??
        await CoinGeckoCoinIndex.instance.resolveId(normalized);

    if (coinId == null) {
      throw MarketProviderException(
        providerId: id,
        message: 'CoinGecko coin ID bulunamadı: $symbol',
      );
    }

    return _getQuoteById(coinId: coinId, displaySymbol: normalized);
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
        .toList(growable: false);
    if (normalizedSymbols.isEmpty) return const [];

    final idBySymbol = <String, String>{};
    await Future.wait(
      normalizedSymbols.map((symbol) async {
        final coinId =
            _popularCoinIds[symbol] ??
            await CoinGeckoCoinIndex.instance.resolveId(symbol);
        if (coinId != null) idBySymbol[symbol] = coinId;
      }),
    );
    if (idBySymbol.isEmpty) return const [];

    final decoded = await _requestPrices(idBySymbol.values.toSet());
    final quotes = <MarketQuote>[];
    for (final entry in idBySymbol.entries) {
      final rawCoin = decoded[entry.value];
      if (rawCoin is! Map<String, dynamic>) continue;
      final quote = _quoteFromRaw(rawCoin: rawCoin, displaySymbol: entry.key);
      if (quote != null) quotes.add(quote);
    }
    return quotes;
  }

  Future<MarketQuote> _getQuoteById({
    required String coinId,
    required String displaySymbol,
  }) async {
    final decoded = await _requestPrices([coinId]);
    final rawCoin = decoded[coinId];

    if (rawCoin is! Map<String, dynamic>) {
      throw MarketProviderException(
        providerId: id,
        message: '$displaySymbol için fiyat bulunamadı.',
      );
    }

    final quote = _quoteFromRaw(rawCoin: rawCoin, displaySymbol: displaySymbol);
    if (quote == null) {
      throw MarketProviderException(
        providerId: id,
        message: '$displaySymbol için geçerli fiyat yok.',
      );
    }
    return quote;
  }

  Future<Map<String, dynamic>> _requestPrices(Iterable<String> coinIds) async {
    final uri = _baseUri.replace(
      path: '${_baseUri.path}/simple/price',
      queryParameters: {
        'ids': coinIds.join(','),
        'vs_currencies': vsCurrency.toLowerCase(),
        'include_24hr_change': 'true',
        'include_last_updated_at': 'true',
      },
    );

    final headers = <String, String>{'Accept': 'application/json'};

    final demoKey = (dotenv.env['COINGECKO_API_KEY'] ?? '').trim();
    if (demoKey.isNotEmpty) {
      headers['x-cg-demo-api-key'] = demoKey;
    }

    late http.Response response;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        response = await _client.get(uri, headers: headers).timeout(timeout);
        if (response.statusCode != 429 && response.statusCode < 500) break;
      } catch (error) {
        if (attempt == 2) {
          throw MarketProviderException(
            providerId: id,
            message: 'CoinGecko bağlantısı kurulamadı.',
            cause: error,
          );
        }
      }
      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 350 * (attempt + 1)));
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MarketProviderException(
        providerId: id,
        message:
            'CoinGecko HTTP ${response.statusCode}: '
            '${response.body}',
      );
    }

    final Object? decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (error) {
      throw MarketProviderException(
        providerId: id,
        message: 'CoinGecko geçersiz JSON döndürdü.',
        cause: error,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw MarketProviderException(
        providerId: id,
        message: 'CoinGecko yanıt biçimi beklenenden farklı.',
      );
    }

    return decoded;
  }

  MarketQuote? _quoteFromRaw({
    required Map<String, dynamic> rawCoin,
    required String displaySymbol,
  }) {
    final currencyKey = vsCurrency.toLowerCase();
    final price = _toDouble(rawCoin[currencyKey]);

    if (price <= 0) return null;

    final changePercent = _toDouble(rawCoin['${currencyKey}_24h_change']);
    final lastUpdatedSeconds = _toInt(rawCoin['last_updated_at']);

    return MarketQuote(
      symbol: displaySymbol,
      name: displaySymbol,
      category: AssetCategory.crypto,
      exchange: 'CRYPTO',
      currency: currencyKey.toUpperCase(),
      price: price,
      change: price * (changePercent / 100),
      changePercent: changePercent,
      updatedAt: lastUpdatedSeconds > 0
          ? DateTime.fromMillisecondsSinceEpoch(
              lastUpdatedSeconds * 1000,
              isUtc: true,
            ).toLocal()
          : DateTime.now(),
      marketStatus: MarketStatus.alwaysOpen,
    );
  }

  void close() {
    _client.close();
  }

  String _normalizeSymbol(String symbol) {
    return symbol.trim().toUpperCase();
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
