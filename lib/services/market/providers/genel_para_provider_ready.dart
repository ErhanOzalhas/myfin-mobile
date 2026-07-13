import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../catalog/asset_universe.dart';
import '../models/asset_category.dart';
import '../models/market_quote.dart';
import 'market_provider.dart';

/// GenelPara tabanlı Türkiye altın ve değerli maden sağlayıcısı.
///
/// Geliştirme ortamında birincil yerel altın sağlayıcısı olarak kullanılabilir.
/// API anahtarı gerektirmez.
///
/// Dokümantasyon:
/// https://api.genelpara.com/
///
/// Portföy değerlemesinde [alis] fiyatı kullanılır. Bunun nedeni kullanıcının
/// elindeki varlığı bozarken piyasadan alabileceği değere daha yakın olmasıdır.
class GenelParaProvider implements MarketProvider {
  GenelParaProvider({
    http.Client? client,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 12),
    this.cacheDuration = const Duration(seconds: 30),
    this.maxRetries = 1,
  })  : _client = client ?? http.Client(),
        _baseUri =
            baseUri ?? Uri.parse('https://api.genelpara.com/json/');

  final http.Client _client;
  final Uri _baseUri;
  final Duration timeout;
  final Duration cacheDuration;
  final int maxRetries;

  final Map<String, _CacheEntry> _cache = {};
  final Map<String, Future<MarketQuote>> _inFlight = {};

  @override
  String get id => 'genel_para';

  static const Map<String, _GenelParaAsset> _assets = {
    'GRAM_ALTIN': _GenelParaAsset(
      providerCode: 'GA',
      name: 'Gram Altın',
      aliases: ['GA', 'GRAM', 'GRAM ALTIN'],
    ),
    'CEYREK_ALTIN': _GenelParaAsset(
      providerCode: 'C',
      name: 'Çeyrek Altın',
      aliases: ['C', 'ÇEYREK', 'CEYREK', 'ÇEYREK ALTIN'],
    ),
    'GRAM_GUMUS': _GenelParaAsset(
      providerCode: 'GAG',
      name: 'Gram Gümüş',
      aliases: ['GAG', 'GRAM GÜMÜŞ', 'GRAM GUMUS'],
    ),
    'ONS_ALTIN': _GenelParaAsset(
      providerCode: 'XAUUSD',
      name: 'Ons Altın',
      aliases: ['XAUUSD', 'ONS', 'ONS ALTIN', 'XAU/USD'],
      currency: 'USD',
    ),
    'HAS_ALTIN': _GenelParaAsset(
      providerCode: 'XHGLD',
      name: 'Has Altın',
      aliases: ['XHGLD', 'HAS', 'HAS ALTIN'],
    ),
    'YARIM_ALTIN': _GenelParaAsset(
      providerCode: 'Y',
      name: 'Yarım Altın',
      aliases: ['Y', 'YARIM', 'YARIM ALTIN'],
    ),
    'TAM_ALTIN': _GenelParaAsset(
      providerCode: 'T',
      name: 'Tam Altın',
      aliases: ['T', 'TAM', 'TAM ALTIN'],
    ),
    'CUMHURIYET_ALTINI': _GenelParaAsset(
      providerCode: 'CMR',
      name: 'Cumhuriyet Altını',
      aliases: [
        'CMR',
        'CUMHURIYET',
        'CUMHURIYET ALTINI',
        'CUMHURİYET ALTINI',
      ],
    ),
    'ATA_ALTINI': _GenelParaAsset(
      providerCode: 'ATA',
      name: 'Ata Altın',
      aliases: ['ATA', 'ATA ALTIN', 'ATA ALTINI'],
    ),
    'ALTIN_14_AYAR': _GenelParaAsset(
      providerCode: '14',
      name: '14 Ayar Altın',
      aliases: ['14', '14 AYAR', '14 AYAR ALTIN'],
    ),
    'ALTIN_18_AYAR': _GenelParaAsset(
      providerCode: '18',
      name: '18 Ayar Altın',
      aliases: ['18', '18 AYAR', '18 AYAR ALTIN'],
    ),
    'BILEZIK_22': _GenelParaAsset(
      providerCode: '22',
      name: '22 Ayar Bilezik',
      aliases: [
        '22',
        '22 AYAR',
        '22 AYAR ALTIN',
        '22 AYAR BILEZIK',
        '22 AYAR BİLEZİK',
      ],
    ),
    'IKIBUCUK_ALTIN': _GenelParaAsset(
      providerCode: 'IKB',
      name: 'İkibuçuk Altın',
      aliases: [
        'IKB',
        'İKİBUÇUK',
        'IKIBUCUK',
        'İKİBUÇUK ALTIN',
        'IKIBUCUK ALTIN',
      ],
    ),
    'BESLI_ALTIN': _GenelParaAsset(
      providerCode: 'BSL',
      name: 'Beşli Altın',
      aliases: [
        'BSL',
        'BEŞLİ',
        'BESLI',
        'BEŞLİ ALTIN',
        'BESLI ALTIN',
      ],
    ),
    'GREMSE_ALTINI': _GenelParaAsset(
      providerCode: 'GR',
      name: 'Gremse Altın',
      aliases: ['GR', 'GREMSE', 'GREMSE ALTIN', 'GREMSE ALTINI'],
    ),
    'RESAT_ALTINI': _GenelParaAsset(
      providerCode: 'RA',
      name: 'Reşat Altın',
      aliases: [
        'RA',
        'REŞAT',
        'RESAT',
        'REŞAT ALTIN',
        'RESAT ALTIN',
      ],
    ),
    'HAMIT_ALTINI': _GenelParaAsset(
      providerCode: 'HA',
      name: 'Hamit Altın',
      aliases: ['HA', 'HAMİT', 'HAMIT', 'HAMİT ALTIN', 'HAMIT ALTIN'],
    ),
    'ALTIN_GUMUS_RASYOSU': _GenelParaAsset(
      providerCode: 'XAUXAG',
      name: 'Altın/Gümüş Rasyosu',
      aliases: [
        'XAUXAG',
        'ALTIN GÜMÜŞ RASYOSU',
        'ALTIN GUMUS RASYOSU',
      ],
      currency: 'RATIO',
    ),
  };

  @override
  bool supportsSymbol(
    String symbol, {
    String? exchange,
  }) {
    return _resolveAsset(symbol) != null;
  }

  @override
  Future<MarketQuote> getQuote(
    String symbol, {
    String? exchange,
  }) {
    final resolved = _resolveAsset(symbol);

    if (resolved == null) {
      throw MarketProviderException(
        providerId: id,
        message: 'GenelPara sembolü desteklemiyor: $symbol',
      );
    }

    final cacheKey = resolved.canonicalSymbol;
    final cached = _cache[cacheKey];

    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) < cacheDuration) {
      return Future.value(cached.quote);
    }

    final existingRequest = _inFlight[cacheKey];
    if (existingRequest != null) {
      return existingRequest;
    }

    final request = _fetchQuote(resolved);
    _inFlight[cacheKey] = request;

    return request.whenComplete(() {
      _inFlight.remove(cacheKey);
    });
  }

  @override
  Future<List<MarketQuote>> getQuotes(
    List<String> symbols, {
    String? exchange,
  }) async {
    final resolvedAssets = <_ResolvedAsset>[];

    for (final symbol in symbols.toSet()) {
      final resolved = _resolveAsset(symbol);
      if (resolved != null) {
        resolvedAssets.add(resolved);
      }
    }

    if (resolvedAssets.isEmpty) {
      return const [];
    }

    final results = <MarketQuote>[];
    final uncached = <_ResolvedAsset>[];

    for (final resolved in resolvedAssets) {
      final cached = _cache[resolved.canonicalSymbol];

      if (cached != null &&
          DateTime.now().difference(cached.cachedAt) < cacheDuration) {
        results.add(cached.quote);
      } else {
        uncached.add(resolved);
      }
    }

    if (uncached.isEmpty) {
      return results;
    }

    try {
      final quotes = await _fetchBatch(uncached);
      results.addAll(quotes);
    } on MarketProviderException {
      for (final resolved in uncached) {
        try {
          results.add(await getQuote(resolved.canonicalSymbol));
        } on MarketProviderException {
          // Kısmi başarı tercih edilir.
        }
      }
    }

    return results;
  }

  Future<MarketQuote> _fetchQuote(
    _ResolvedAsset resolved,
  ) async {
    final quotes = await _fetchBatch([resolved]);

    if (quotes.isEmpty) {
      throw MarketProviderException(
        providerId: id,
        message:
            '${resolved.canonicalSymbol} için GenelPara fiyatı bulunamadı.',
      );
    }

    return quotes.first;
  }

  Future<List<MarketQuote>> _fetchBatch(
    List<_ResolvedAsset> assets,
  ) async {
    final providerCodes = assets
        .map((asset) => asset.definition.providerCode)
        .toSet()
        .join(',');

    final uri = _baseUri.replace(
      queryParameters: {
        'list': 'altin',
        'sembol': providerCodes,
      },
    );

    final payload = await _requestJson(uri);

    final success = payload['success'];
    if (success is bool && !success) {
      throw MarketProviderException(
        providerId: id,
        message:
            (payload['message'] ?? 'GenelPara isteği başarısız.')
                .toString(),
      );
    }

    final rawData = payload['data'];
    if (rawData is! Map) {
      throw MarketProviderException(
        providerId: id,
        message: 'GenelPara yanıtında data alanı bulunamadı.',
      );
    }

    final data = Map<String, dynamic>.from(rawData);
    final quotes = <MarketQuote>[];

    for (final resolved in assets) {
      final code = resolved.definition.providerCode;
      final rawRow = data[code];

      if (rawRow is! Map) {
        debugPrint('GENELPARA: $code için veri bulunamadı.');
        continue;
      }

      final row = Map<String, dynamic>.from(rawRow);
      final quote = _mapQuote(
        resolved: resolved,
        row: row,
      );

      _cache[resolved.canonicalSymbol] = _CacheEntry(
        quote: quote,
        cachedAt: DateTime.now(),
      );

      quotes.add(quote);
    }

    return quotes;
  }

  Future<Map<String, dynamic>> _requestJson(
    Uri uri,
  ) async {
    Object? lastError;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _client.get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'MyFin/1.0',
          },
        ).timeout(timeout);

        if (response.statusCode < 200 ||
            response.statusCode >= 300) {
          throw MarketProviderException(
            providerId: id,
            message:
                'GenelPara HTTP ${response.statusCode}: '
                '${response.body}',
          );
        }

        final Object? decoded = jsonDecode(response.body);

        if (decoded is! Map<String, dynamic>) {
          throw const MarketProviderException(
            providerId: 'genel_para',
            message: 'GenelPara yanıt biçimi beklenenden farklı.',
          );
        }

        return decoded;
      } on TimeoutException catch (error) {
        lastError = error;
      } on FormatException catch (error) {
        throw MarketProviderException(
          providerId: id,
          message: 'GenelPara geçersiz JSON döndürdü.',
          cause: error,
        );
      } on MarketProviderException {
        rethrow;
      } catch (error) {
        lastError = error;
      }

      if (attempt < maxRetries) {
        await Future<void>.delayed(
          Duration(milliseconds: 250 * (attempt + 1)),
        );
      }
    }

    throw MarketProviderException(
      providerId: id,
      message: 'GenelPara bağlantısı kurulamadı.',
      cause: lastError,
    );
  }

  MarketQuote _mapQuote({
    required _ResolvedAsset resolved,
    required Map<String, dynamic> row,
  }) {
    final buy = _toDouble(
      row['alis'] ??
          row['buy'] ??
          row['buying'],
    );
    final sell = _toDouble(
      row['satis'] ??
          row['sell'] ??
          row['selling'],
    );

    final price = buy > 0 ? buy : sell;

    if (price <= 0) {
      throw MarketProviderException(
        providerId: id,
        message:
            '${resolved.canonicalSymbol} için geçerli fiyat bulunamadı.',
      );
    }

    final change = _toDouble(
      row['degisim'] ??
          row['change'],
    );
    final changePercent = _toDouble(
      row['oran'] ??
          row['changeRate'] ??
          row['changePercent'],
    );

    final providerCurrency =
        (row['kur'] ?? resolved.definition.currency)
            .toString()
            .trim()
            .toUpperCase();

    final currency = providerCurrency.isEmpty
        ? resolved.definition.currency
        : providerCurrency;

    return MarketQuote(
      symbol: resolved.canonicalSymbol,
      name: resolved.definition.name,
      category: AssetCategory.commodity,
      exchange: 'TR_GOLD',
      currency: currency,
      price: price,
      change: change,
      changePercent: changePercent,
      updatedAt: DateTime.now(),
      marketStatus: MarketStatus.open,
    );
  }

  _ResolvedAsset? _resolveAsset(String symbol) {
    final normalized = _normalize(symbol);

    for (final entry in _assets.entries) {
      final canonical = entry.key;
      final definition = entry.value;

      if (_normalize(canonical) == normalized ||
          _normalize(definition.providerCode) == normalized ||
          definition.aliases.any(
            (alias) => _normalize(alias) == normalized,
          )) {
        return _ResolvedAsset(
          canonicalSymbol: canonical,
          definition: definition,
        );
      }
    }

    final universeDefinition = AssetUniverse.find(symbol);

    if (universeDefinition != null) {
      final direct = _assets[universeDefinition.symbol];

      if (direct != null) {
        return _ResolvedAsset(
          canonicalSymbol: universeDefinition.symbol,
          definition: direct,
        );
      }
    }

    return null;
  }

  double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    var text = (value ?? '').toString().trim();

    if (text.isEmpty) {
      return 0;
    }

    text = text
        .replaceAll('%', '')
        .replaceAll('+', '')
        .replaceAll('−', '-')
        .replaceAll(' ', '');

    if (text.contains(',') && text.contains('.')) {
      final lastComma = text.lastIndexOf(',');
      final lastDot = text.lastIndexOf('.');

      if (lastComma > lastDot) {
        text = text.replaceAll('.', '').replaceAll(',', '.');
      } else {
        text = text.replaceAll(',', '');
      }
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
        .replaceAll('Ç', 'C')
        .replaceAll(RegExp(r'[\s_\-/.]'), '');
  }

  void clearCache() {
    _cache.clear();
  }

  void close() {
    _client.close();
  }
}

class _GenelParaAsset {
  final String providerCode;
  final String name;
  final String currency;
  final List<String> aliases;

  const _GenelParaAsset({
    required this.providerCode,
    required this.name,
    this.currency = 'TRY',
    this.aliases = const [],
  });
}

class _ResolvedAsset {
  final String canonicalSymbol;
  final _GenelParaAsset definition;

  const _ResolvedAsset({
    required this.canonicalSymbol,
    required this.definition,
  });
}

class _CacheEntry {
  final MarketQuote quote;
  final DateTime cachedAt;

  const _CacheEntry({
    required this.quote,
    required this.cachedAt,
  });
}
