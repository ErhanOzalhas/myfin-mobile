import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/market_quote.dart';
import 'market_parser.dart';
import 'market_symbol_mapper.dart';

class MarketDataService {
  MarketDataService._();

  static final instance = MarketDataService._();

  Future<MarketQuote> getQuote({
    required String symbol,
    required String type,
  }) async {
    final yahooSymbol =
        MarketSymbolMapper.map(symbol, type);

    final url =
        'https://query1.finance.yahoo.com/v8/finance/chart/$yahooSymbol';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception(
        'Yahoo Finance bağlantısı başarısız.',
      );
    }

    final json = jsonDecode(response.body);

    return MarketParser.parse(
      json,
      yahooSymbol,
    );
  }
}