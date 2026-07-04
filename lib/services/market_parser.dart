import '../models/market_quote.dart';

class MarketParser {
  MarketParser._();

  static MarketQuote parse(
    Map<String, dynamic> json,
    String symbol,
  ) {
    final chart = json['chart'] as Map<String, dynamic>;
    final results = chart['result'] as List<dynamic>?;

    if (results == null || results.isEmpty) {
      throw Exception('Piyasa verisi bulunamadı: $symbol');
    }

    final result = results.first as Map<String, dynamic>;
    final meta = result['meta'] as Map<String, dynamic>;

    final price = _toDouble(meta['regularMarketPrice']);
    final previous = _toDouble(meta['previousClose']);

    final change = price - previous;
    final changePercent = previous == 0 ? 0.0 : (change / previous) * 100;

    return MarketQuote(
      symbol: symbol,
      currentPrice: price,
      change: change,
      changePercent: changePercent,
      updatedAt: DateTime.now(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}