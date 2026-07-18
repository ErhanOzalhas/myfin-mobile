import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../catalog/asset_universe.dart';
import '../models/asset_category.dart';
import '../models/market_quote.dart';
import 'market_provider.dart';
import 'provider_symbol_mapping.dart';

class NosyTurkeyGoldProvider implements MarketProvider {
  NosyTurkeyGoldProvider({
    String? apiKey,
    http.Client? client,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 15),
  }) : _apiKeyOverride = apiKey?.trim(),
       _client = client ?? http.Client(),
       _baseUri = baseUri ?? Uri.parse('https://www.nosyapi.com/apiv2/service');

  final String? _apiKeyOverride;
  final http.Client _client;
  final Uri _baseUri;
  final Duration timeout;

  final Map<String, String> _resolvedCodeCache = {};

  String get _apiKey {
    return (_apiKeyOverride ?? dotenv.env['NOSY_API_KEY'] ?? '').trim();
  }

  @override
  String get id => 'nosy_turkey_gold';

  @override
  bool supportsSymbol(String symbol, {String? exchange}) {
    return AssetUniverse.find(symbol)?.isLocalTurkishGold == true;
  }

  @override
  Future<MarketQuote> getQuote(String symbol, {String? exchange}) async {
    if (_apiKey.isEmpty) {
      throw const MarketProviderException(
        providerId: 'nosy_turkey_gold',
        message: 'NOSY_API_KEY bulunamadı.',
      );
    }

    final definition = AssetUniverse.find(symbol);
    final canonical = definition?.symbol ?? symbol.trim().toUpperCase();

    final code = await _resolveProviderCode(canonical);

    if (code == null || code.isEmpty) {
      throw MarketProviderException(
        providerId: id,
        message: '$canonical için NosyAPI code bulunamadı.',
      );
    }

    final uri = _baseUri.replace(
      path: '${_baseUri.path}/economy/live-exchange-rates',
      queryParameters: {'code': code, 'apiKey': _apiKey},
    );

    final payload = await _requestJson(uri);
    final data = payload['data'];

    if (data is! List || data.isEmpty) {
      throw MarketProviderException(
        providerId: id,
        message: '$canonical ($code) için fiyat bulunamadı.',
      );
    }

    Map<String, dynamic>? row;

    for (final item in data) {
      if (item is! Map) continue;

      final mapped = Map<String, dynamic>.from(item);
      final returnedCode = (mapped['currencyCode'] ?? mapped['code'] ?? '')
          .toString()
          .toUpperCase();

      if (returnedCode == code.toUpperCase()) {
        row = mapped;
        break;
      }
    }

    row ??= Map<String, dynamic>.from(data.first as Map);

    final buy = _toDouble(row['buy']);
    final sell = _toDouble(row['sell']);
    final price = buy > 0 ? buy : sell;

    if (price <= 0) {
      throw MarketProviderException(
        providerId: id,
        message: '$canonical için geçerli alış/satış fiyatı yok.',
      );
    }

    final changePercent = _toDouble(
      row['changeRate'] ?? row['changePercent'] ?? row['rate'],
    );
    final previousClose = _toDouble(row['prevClose']);
    final change = previousClose > 0
        ? price - previousClose
        : _toDouble(row['change']);

    return MarketQuote(
      symbol: canonical,
      name: definition?.name ?? (row['description'] ?? canonical).toString(),
      category: AssetCategory.commodity,
      exchange: 'TR_GOLD',
      currency: 'TRY',
      price: price,
      change: change,
      changePercent: changePercent,
      updatedAt: DateTime.now(),
      marketStatus: MarketStatus.open,
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
        results.add(await getQuote(symbol, exchange: exchange));
      } on MarketProviderException {
        // Partial success.
      }
    }

    return results;
  }

  Future<String?> _resolveProviderCode(String canonical) async {
    final cached = _resolvedCodeCache[canonical];
    if (cached != null) return cached;

    final fallback = ProviderSymbolMapping.nosyGoldFallbackCode(canonical);

    try {
      final uri = _baseUri.replace(
        path: '${_baseUri.path}/economy/live-exchange-rates/list',
        queryParameters: {'apiKey': _apiKey},
      );

      final payload = await _requestJson(uri);
      final data = payload['data'];

      if (data is List) {
        final searchTerms = ProviderSymbolMapping.localGoldSearchTerms(
          canonical,
        );

        for (final item in data) {
          if (item is! Map) continue;

          final mapped = Map<String, dynamic>.from(item);
          final code = (mapped['code'] ?? '').toString();
          final fullName = (mapped['FullName'] ?? mapped['fullName'] ?? '')
              .toString();
          final baseCurrency = (mapped['baseCurrency'] ?? '').toString();

          final haystack = _normalize('$code $fullName $baseCurrency');

          if (searchTerms.any((term) => haystack.contains(_normalize(term)))) {
            _resolvedCodeCache[canonical] = code;
            return code;
          }
        }
      }
    } on MarketProviderException {
      // Fall back to the documented static code.
    }

    if (fallback != null) {
      _resolvedCodeCache[canonical] = fallback;
    }

    return fallback;
  }

  Future<Map<String, dynamic>> _requestJson(Uri uri) async {
    final http.Response response;

    try {
      response = await _client
          .get(
            uri,
            headers: {
              'X-NSYP': _apiKey,
              'Authorization': 'Bearer $_apiKey',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);
    } catch (error) {
      throw MarketProviderException(
        providerId: id,
        message: 'NosyAPI bağlantısı kurulamadı.',
        cause: error,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MarketProviderException(
        providerId: id,
        message: 'NosyAPI HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final Object? decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (error) {
      throw MarketProviderException(
        providerId: id,
        message: 'NosyAPI geçersiz JSON döndürdü.',
        cause: error,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw MarketProviderException(
        providerId: id,
        message: 'NosyAPI yanıt biçimi beklenenden farklı.',
      );
    }

    final status = (decoded['status'] ?? '').toString().toLowerCase();

    if (status.isNotEmpty && status != 'success') {
      throw MarketProviderException(
        providerId: id,
        message:
            (decoded['messageTR'] ?? decoded['message'] ?? 'NosyAPI hatası')
                .toString(),
      );
    }

    return decoded;
  }

  double _toDouble(Object? value) {
    if (value is num) return value.toDouble();

    var text = (value ?? '').toString().trim();

    if (text.contains(',') && text.contains('.')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else if (text.contains(',')) {
      text = text.replaceAll(',', '.');
    }

    return double.tryParse(text) ?? 0;
  }

  String _normalize(String value) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('Ş', 'S')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C');
  }

  void close() {
    _client.close();
  }
}
