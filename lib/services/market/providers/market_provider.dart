import '../models/market_quote.dart';

abstract interface class MarketProvider {
  String get id;

  Future<MarketQuote> getQuote(
    String symbol, {
    String? exchange,
  });

  Future<List<MarketQuote>> getQuotes(
    List<String> symbols, {
    String? exchange,
  });

  bool supportsSymbol(
    String symbol, {
    String? exchange,
  });
}

class MarketProviderException implements Exception {
  final String providerId;
  final String message;
  final Object? cause;

  const MarketProviderException({
    required this.providerId,
    required this.message,
    this.cause,
  });

  @override
  String toString() {
    return 'MarketProviderException('
        'provider: $providerId, message: $message, cause: $cause)';
  }
}
