import 'package:flutter/foundation.dart';

import 'market_service.dart';

class CurrencyConversionService {
  CurrencyConversionService._();

  static final CurrencyConversionService instance =
      CurrencyConversionService._();

  final Map<String, double> _rateCache = <String, double>{};

  Future<double> convert({
    required double amount,
    required String from,
    String to = 'TRY',
    bool forceRefresh = false,
  }) async {
    final source = _normalizeCurrency(from);
    final target = _normalizeCurrency(to);

    if (amount == 0 || source == target) {
      return amount;
    }

    final rate = await getRate(
      from: source,
      to: target,
      forceRefresh: forceRefresh,
    );

    return amount * rate;
  }

  Future<double> getRate({
    required String from,
    required String to,
    bool forceRefresh = false,
  }) async {
    final source = _normalizeCurrency(from);
    final target = _normalizeCurrency(to);
    final cacheKey = '$source/$target';

    if (source == target) {
      return 1;
    }

    if (!forceRefresh) {
      final cachedRate = _rateCache[cacheKey];
      if (cachedRate != null && cachedRate > 0) {
        return cachedRate;
      }
    }

    final directSymbols = <String>[
      '$source/$target',
      '$source$target',
    ];

    for (final symbol in directSymbols) {
      try {
        final quote = await MarketService.instance.getQuote(
          symbol,
          forceRefresh: forceRefresh,
        );

        if (quote.price > 0) {
          _rateCache[cacheKey] = quote.price;
          debugPrint(
            '💱 $source/$target -> ${quote.price} '
            '(${quote.symbol}, ${quote.exchange})',
          );
          return quote.price;
        }
      } catch (error) {
        debugPrint('⚠️ Kur denemesi başarısız: $symbol -> $error');
      }
    }

    final inverseSymbols = <String>[
      '$target/$source',
      '$target$source',
    ];

    for (final symbol in inverseSymbols) {
      try {
        final quote = await MarketService.instance.getQuote(
          symbol,
          forceRefresh: forceRefresh,
        );

        if (quote.price > 0) {
          final inverseRate = 1 / quote.price;
          _rateCache[cacheKey] = inverseRate;
          debugPrint(
            '💱 $source/$target -> $inverseRate '
            '(ters kur: ${quote.symbol})',
          );
          return inverseRate;
        }
      } catch (error) {
        debugPrint('⚠️ Ters kur denemesi başarısız: $symbol -> $error');
      }
    }

    throw CurrencyConversionException(
      from: source,
      to: target,
    );
  }

  void clearCache() {
    _rateCache.clear();
  }

  String _normalizeCurrency(String value) {
    final normalized = value.trim().toUpperCase();

    return switch (normalized) {
      'TL' || '₺' => 'TRY',
      r'$' => 'USD',
      '€' => 'EUR',
      '£' => 'GBP',
      _ => normalized.isEmpty ? 'TRY' : normalized,
    };
  }
}

class CurrencyConversionException implements Exception {
  final String from;
  final String to;

  const CurrencyConversionException({
    required this.from,
    required this.to,
  });

  @override
  String toString() {
    return 'CurrencyConversionException: $from/$to kuru alınamadı.';
  }
}
