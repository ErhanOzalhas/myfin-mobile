import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/asset_category.dart';
import '../models/market_quote.dart';
import 'market_provider.dart';

/// CoinGecko yanıt veremediğinde kullanılan anahtarsız kripto fiyat kaynağı.
class BinanceMarketProvider implements MarketProvider {
  BinanceMarketProvider({
    http.Client? client,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client(),
       _baseUri = baseUri ?? Uri.parse('https://data-api.binance.vision');

  final http.Client _client;
  final Uri _baseUri;
  final Duration timeout;

  @override
  String get id => 'binance_public';

  @override
  bool supportsSymbol(String symbol, {String? exchange}) {
    return symbol.trim().isNotEmpty &&
        (exchange?.trim().toUpperCase() == 'CRYPTO' || exchange == null);
  }

  @override
  Future<MarketQuote> getQuote(String symbol, {String? exchange}) async {
    final normalized = symbol.trim().toUpperCase();
    final uri = _baseUri.replace(
      path: '/api/v3/ticker/24hr',
      queryParameters: {'symbol': '${normalized}USDT'},
    );

    late http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);
    } catch (error) {
      throw MarketProviderException(
        providerId: id,
        message: 'Binance bağlantısı kurulamadı.',
        cause: error,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MarketProviderException(
        providerId: id,
        message: '$normalized için Binance fiyatı bulunamadı.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw MarketProviderException(
        providerId: id,
        message: 'Binance yanıt biçimi geçersiz.',
      );
    }
    final price = _toDouble(decoded['lastPrice']);
    final change = _toDouble(decoded['priceChange']);
    final changePercent = _toDouble(decoded['priceChangePercent']);
    if (price <= 0) {
      throw MarketProviderException(
        providerId: id,
        message: '$normalized için geçerli Binance fiyatı yok.',
      );
    }

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
