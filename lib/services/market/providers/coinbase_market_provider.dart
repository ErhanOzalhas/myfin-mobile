import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/asset_category.dart';
import '../models/market_quote.dart';
import 'market_provider.dart';

/// Binance'te bulunmayan kriptolar için ikinci anahtarsız yedek kaynak.
class CoinbaseMarketProvider implements MarketProvider {
  CoinbaseMarketProvider({
    http.Client? client,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client(),
       _baseUri = baseUri ?? Uri.parse('https://api.exchange.coinbase.com');

  final http.Client _client;
  final Uri _baseUri;
  final Duration timeout;

  @override
  String get id => 'coinbase_public';

  @override
  bool supportsSymbol(String symbol, {String? exchange}) {
    return symbol.trim().isNotEmpty &&
        (exchange?.trim().toUpperCase() == 'CRYPTO' || exchange == null);
  }

  @override
  Future<MarketQuote> getQuote(String symbol, {String? exchange}) async {
    final normalized = symbol.trim().toUpperCase();
    final product = '$normalized-USD';
    final uri = _baseUri.replace(path: '/products/$product/stats');

    late http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'MyFin/1.0',
            },
          )
          .timeout(timeout);
    } catch (error) {
      throw MarketProviderException(
        providerId: id,
        message: 'Coinbase bağlantısı kurulamadı.',
        cause: error,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MarketProviderException(
        providerId: id,
        message: '$normalized için Coinbase fiyatı bulunamadı.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw MarketProviderException(
        providerId: id,
        message: 'Coinbase yanıt biçimi geçersiz.',
      );
    }
    final price = _toDouble(decoded['last']);
    final open = _toDouble(decoded['open']);
    if (price <= 0) {
      throw MarketProviderException(
        providerId: id,
        message: '$normalized için geçerli Coinbase fiyatı yok.',
      );
    }
    final change = open > 0 ? price - open : 0.0;
    final changePercent = open > 0 ? change / open * 100 : 0.0;

    return MarketQuote(
      symbol: normalized,
      name: normalized,
      category: AssetCategory.crypto,
      exchange: 'CRYPTO',
      currency: 'USD',
      price: price,
      change: change,
      changePercent: changePercent,
      updatedAt: DateTime.now(),
      marketStatus: MarketStatus.alwaysOpen,
    );
  }

  @override
  Future<List<MarketQuote>> getQuotes(
    List<String> symbols, {
    String? exchange,
  }) async {
    final results = await Future.wait(
      symbols.toSet().map((symbol) async {
        try {
          return await getQuote(symbol, exchange: exchange);
        } on MarketProviderException {
          return null;
        }
      }),
    );
    return results.whereType<MarketQuote>().toList(growable: false);
  }

  void close() => _client.close();

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
