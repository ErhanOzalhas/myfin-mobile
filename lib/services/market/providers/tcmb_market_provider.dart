import 'package:http/http.dart' as http;

import '../models/asset_category.dart';
import '../models/market_quote.dart';
import 'market_provider.dart';

class TcmbMarketProvider implements MarketProvider {
  TcmbMarketProvider({
    http.Client? client,
    Uri? ratesUri,
    this.timeout = const Duration(seconds: 12),
  })  : _client = client ?? http.Client(),
        _ratesUri = ratesUri ??
            Uri.parse('https://www.tcmb.gov.tr/kurlar/today.xml');

  final http.Client _client;
  final Uri _ratesUri;
  final Duration timeout;

  static const Set<String> _supportedCurrencies = {
    'USD',
    'EUR',
    'GBP',
    'CHF',
    'JPY',
    'AUD',
    'CAD',
    'DKK',
    'SEK',
    'NOK',
    'SAR',
    'KWD',
    'BGN',
    'RON',
    'RUB',
    'CNY',
    'PKR',
    'QAR',
  };

  @override
  String get id => 'tcmb';

  @override
  bool supportsSymbol(
    String symbol, {
    String? exchange,
  }) {
    final pair = _parsePair(symbol);
    return pair != null &&
        pair.target == 'TRY' &&
        _supportedCurrencies.contains(pair.base);
  }

  @override
  Future<MarketQuote> getQuote(
    String symbol, {
    String? exchange,
  }) async {
    final pair = _parsePair(symbol);

    if (pair == null || !supportsSymbol(symbol, exchange: exchange)) {
      throw MarketProviderException(
        providerId: id,
        message: 'TCMB sembolü desteklemiyor: $symbol',
      );
    }

    final http.Response response;

    try {
      response = await _client.get(_ratesUri).timeout(timeout);
    } catch (error) {
      throw MarketProviderException(
        providerId: id,
        message: 'TCMB bağlantısı kurulamadı.',
        cause: error,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MarketProviderException(
        providerId: id,
        message: 'TCMB HTTP ${response.statusCode}.',
      );
    }

    final xml = response.body;
    final currencyBlock = _findCurrencyBlock(xml, pair.base);

    if (currencyBlock == null) {
      throw MarketProviderException(
        providerId: id,
        message: '${pair.base} için TCMB kuru bulunamadı.',
      );
    }

    final unit = _parseDouble(_readTag(currencyBlock, 'Unit'));
    final forexBuying =
        _parseDouble(_readTag(currencyBlock, 'ForexBuying'));
    final forexSelling =
        _parseDouble(_readTag(currencyBlock, 'ForexSelling'));
    final name = _readTag(currencyBlock, 'Isim').trim();

    // Portföy değerlemesinde yabancı parayı TRY'ye bozma değerine
    // daha yakın olan döviz alış kuru kullanılır.
    final rawPrice = forexBuying > 0 ? forexBuying : forexSelling;
    final divisor = unit > 0 ? unit : 1;
    final price = rawPrice / divisor;

    if (price <= 0) {
      throw MarketProviderException(
        providerId: id,
        message: '${pair.base}/TRY için geçerli TCMB kuru yok.',
      );
    }

    return MarketQuote(
      symbol: '${pair.base}/TRY',
      name: name.isEmpty ? '${pair.base} / Türk Lirası' : name,
      category: AssetCategory.currency,
      exchange: 'TCMB',
      currency: 'TRY',
      price: price,
      change: 0,
      changePercent: 0,
      updatedAt: DateTime.now(),
      marketStatus: MarketStatus.closed,
    );
  }

  @override
  Future<List<MarketQuote>> getQuotes(
    List<String> symbols, {
    String? exchange,
  }) async {
    final results = <MarketQuote>[];

    for (final symbol in symbols) {
      if (!supportsSymbol(symbol, exchange: exchange)) {
        continue;
      }

      try {
        results.add(
          await getQuote(symbol, exchange: exchange),
        );
      } on MarketProviderException {
        // Partial success is preferred.
      }
    }

    return results;
  }

  void close() {
    _client.close();
  }

  _CurrencyPair? _parsePair(String symbol) {
    final normalized = symbol
        .trim()
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll('/', '');

    if (normalized.length != 6) {
      return null;
    }

    return _CurrencyPair(
      base: normalized.substring(0, 3),
      target: normalized.substring(3, 6),
    );
  }

  String? _findCurrencyBlock(String xml, String code) {
    final pattern = RegExp(
      '<Currency[^>]*CurrencyCode="$code"[^>]*>([\\s\\S]*?)</Currency>',
      caseSensitive: false,
    );

    return pattern.firstMatch(xml)?.group(1);
  }

  String _readTag(String block, String tag) {
    final pattern = RegExp(
      '<$tag>([\\s\\S]*?)</$tag>',
      caseSensitive: false,
    );

    return pattern.firstMatch(block)?.group(1)?.trim() ?? '';
  }

  double _parseDouble(String value) {
    return double.tryParse(
          value.trim().replaceAll(',', '.'),
        ) ??
        0;
  }
}

class _CurrencyPair {
  final String base;
  final String target;

  const _CurrencyPair({
    required this.base,
    required this.target,
  });
}
