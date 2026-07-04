import '../models/market_quote.dart';
import '../services/market_data_service.dart';

class MarketRepository {
  MarketRepository._();

  static final MarketRepository instance = MarketRepository._();

  final MarketDataService _service = MarketDataService.instance;

  Future<MarketQuote> getQuote({
    required String symbol,
    required String type,
  }) {
    return _service.getQuote(
      symbol: symbol,
      type: type,
    );
  }
}