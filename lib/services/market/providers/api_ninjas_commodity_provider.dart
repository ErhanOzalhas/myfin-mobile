import 'package:cloud_functions/cloud_functions.dart';

import '../models/asset_category.dart';
import '../models/market_quote.dart';
import 'market_provider.dart';

class ApiNinjasCommodityProvider implements MarketProvider {
  ApiNinjasCommodityProvider({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  static const Set<String> _symbols = {'GRAM_GUMUS', 'BRENT/USD', 'WHEAT/USD'};

  @override
  String get id => 'api_ninjas_commodity';

  @override
  bool supportsSymbol(String symbol, {String? exchange}) {
    return _symbols.contains(_normalize(symbol));
  }

  @override
  Future<MarketQuote> getQuote(String symbol, {String? exchange}) async {
    final normalized = _normalize(symbol);
    if (!supportsSymbol(normalized, exchange: exchange)) {
      throw MarketProviderException(
        providerId: id,
        message: '$symbol desteklenen bir API Ninjas emtiası değil.',
      );
    }

    try {
      final callable = _functions.httpsCallable('myFinCommodityQuote');
      final result = await callable.call<Map<String, dynamic>>({
        'symbol': normalized,
      });
      final data = Map<String, dynamic>.from(result.data);
      return MarketQuote(
        symbol: (data['symbol'] ?? normalized).toString(),
        name: (data['name'] ?? normalized).toString(),
        category: AssetCategory.commodity,
        exchange: (data['exchange'] ?? 'COMMODITY').toString(),
        currency: (data['currency'] ?? 'USD').toString(),
        price: _number(data['price']),
        change: _number(data['change']),
        changePercent: _number(data['changePercent']),
        updatedAt:
            DateTime.tryParse((data['updatedAt'] ?? '').toString()) ??
            DateTime.now(),
        marketStatus: MarketStatus.unknown,
      );
    } on FirebaseFunctionsException catch (error) {
      throw MarketProviderException(
        providerId: id,
        message: error.message ?? '$symbol emtia fiyatı alınamadı.',
        cause: error,
      );
    } catch (error) {
      throw MarketProviderException(
        providerId: id,
        message: '$symbol emtia fiyatı alınamadı.',
        cause: error,
      );
    }
  }

  @override
  Future<List<MarketQuote>> getQuotes(
    List<String> symbols, {
    String? exchange,
  }) async {
    final quotes = <MarketQuote>[];
    for (final symbol in symbols.toSet()) {
      if (!supportsSymbol(symbol, exchange: exchange)) continue;
      try {
        quotes.add(await getQuote(symbol, exchange: exchange));
      } on MarketProviderException {
        // Portföy toplamında kısmi başarı tercih edilir.
      }
    }
    return quotes;
  }

  static String _normalize(String symbol) {
    final value = symbol.trim().toUpperCase();
    return switch (value.replaceAll(' ', '').replaceAll('_', '')) {
      'GRAMGUMUS' || 'GRAMGÜMÜŞ' => 'GRAM_GUMUS',
      'BRENT' || 'BRENTUSD' => 'BRENT/USD',
      'WHEAT' || 'WHEATUSD' || 'BUGDAY' || 'BUĞDAY' => 'WHEAT/USD',
      _ => value,
    };
  }

  static double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
