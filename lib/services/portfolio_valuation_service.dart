import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/portfolio_item.dart';
import 'market/currency_conversion_service.dart';
import 'market/market_service.dart';
import 'portfolio_profile_service.dart';

class PortfolioItemValuation {
  final PortfolioItem item;
  final double costInBaseCurrency;
  final double currentValueInBaseCurrency;
  final double profitLossInBaseCurrency;
  final double profitPercent;
  final bool hasLivePrice;

  const PortfolioItemValuation({
    required this.item,
    required this.costInBaseCurrency,
    required this.currentValueInBaseCurrency,
    required this.profitLossInBaseCurrency,
    required this.profitPercent,
    required this.hasLivePrice,
  });
}

class PortfolioValuation {
  final String baseCurrency;
  final List<PortfolioItemValuation> items;
  final double totalCost;
  final double totalValue;
  final double totalProfit;
  final double profitPercent;
  final DateTime? updatedAt;
  final bool isStale;

  const PortfolioValuation({
    required this.baseCurrency,
    required this.items,
    required this.totalCost,
    required this.totalValue,
    required this.totalProfit,
    required this.profitPercent,
    this.updatedAt,
    this.isStale = false,
  });

  int get assetCount => items.length;
}

class PortfolioValuationService {
  PortfolioValuationService._();

  static final PortfolioValuationService instance =
      PortfolioValuationService._();

  static const String baseCurrency = 'TRY';
  static const String _offlineStorageKey = 'myfin_offline_valuations_v1';

  final Map<String, _ValuationCacheEntry> _valuationCache = {};
  final Map<String, Future<PortfolioValuation>> _inFlight = {};
  final Map<String, _PersistedValuation> _persistedValuations = {};
  final ValueNotifier<int> revision = ValueNotifier<int>(0);
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_offlineStorageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      for (final entry in decoded.entries) {
        if (entry.value is! Map) continue;
        final snapshot = _PersistedValuation.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
        if (snapshot != null) {
          _persistedValuations[entry.key.toString()] = snapshot;
        }
      }
    } catch (error) {
      debugPrint('OFFLINE PORTFOLIO SNAPSHOT okunamadı: $error');
    }
  }

  String _fingerprint(List<PortfolioItem> items) {
    final sorted = [...items]..sort((a, b) => a.id.compareTo(b.id));
    final portfolioFingerprint = sorted
        .map(
          (item) => [
            item.id,
            item.symbol,
            item.type,
            item.quantity.toStringAsFixed(8),
            item.averagePrice.toStringAsFixed(8),
            item.currency,
          ].join('|'),
        )
        .join('::');
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'signed-out';
    final profileId = PortfolioProfileService.instance.activeProfileId.value;
    return '$userId::$profileId::$portfolioFingerprint';
  }

  PortfolioValuation? peek(List<PortfolioItem> items) {
    final fingerprint = _fingerprint(items);
    final cached = _valuationCache[fingerprint]?.valuation;
    if (cached != null) return cached;
    final restored = _restorePersisted(items, fingerprint);
    if (restored == null) return null;
    _valuationCache[fingerprint] = _ValuationCacheEntry(
      valuation: restored,
      savedAt: restored.updatedAt ?? DateTime.now(),
      hasAnyLivePrice: false,
    );
    return restored;
  }

  Future<PortfolioValuation> calculate(
    List<PortfolioItem> portfolioItems, {
    bool forceRefresh = false,
  }) {
    final fingerprint = _fingerprint(portfolioItems);
    final cached = _valuationCache[fingerprint];

    if (!forceRefresh && cached != null && cached.isFresh) {
      return Future.value(cached.valuation);
    }

    final running = _inFlight[fingerprint];
    if (running != null) return running;

    final calculation =
        _calculateUncached(portfolioItems, forceRefresh: forceRefresh)
            .then((valuation) {
              _valuationCache[fingerprint] = _ValuationCacheEntry(
                valuation: valuation,
                savedAt: DateTime.now(),
                hasAnyLivePrice: valuation.items.any(
                  (item) => item.hasLivePrice,
                ),
              );
              while (_valuationCache.length > 6) {
                _valuationCache.remove(_valuationCache.keys.first);
              }
              revision.value++;
              if (valuation.items.any((item) => item.hasLivePrice)) {
                unawaited(_persist(fingerprint, valuation));
              }
              return valuation;
            })
            .whenComplete(() => _inFlight.remove(fingerprint));

    _inFlight[fingerprint] = calculation;
    return calculation;
  }

  Future<PortfolioValuation> _calculateUncached(
    List<PortfolioItem> portfolioItems, {
    required bool forceRefresh,
  }) async {
    var valuations = await _calculateItems(
      portfolioItems,
      forceRefresh: forceRefresh,
    );

    final hasNoLivePrice =
        portfolioItems.isNotEmpty &&
        valuations.every((valuation) => !valuation.hasLivePrice);

    if (hasNoLivePrice && !forceRefresh) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      valuations = await _calculateItems(portfolioItems, forceRefresh: true);
    }

    final fingerprint = _fingerprint(portfolioItems);
    final persisted = _restorePersisted(portfolioItems, fingerprint);
    final persistedById = <String, PortfolioItemValuation>{
      for (final item in persisted?.items ?? const <PortfolioItemValuation>[])
        item.item.id: item,
    };
    var usedOfflineValue = false;
    valuations = valuations
        .map((valuation) {
          if (valuation.hasLivePrice) return valuation;
          final previous = persistedById[valuation.item.id];
          if (previous == null || previous.currentValueInBaseCurrency <= 0) {
            return valuation;
          }
          usedOfflineValue = true;
          return PortfolioItemValuation(
            item: valuation.item,
            costInBaseCurrency: valuation.costInBaseCurrency > 0
                ? valuation.costInBaseCurrency
                : previous.costInBaseCurrency,
            currentValueInBaseCurrency: previous.currentValueInBaseCurrency,
            profitLossInBaseCurrency:
                previous.currentValueInBaseCurrency -
                (valuation.costInBaseCurrency > 0
                    ? valuation.costInBaseCurrency
                    : previous.costInBaseCurrency),
            profitPercent: previous.profitPercent,
            hasLivePrice: false,
          );
        })
        .toList(growable: false);

    final totalCost = valuations.fold<double>(
      0,
      (sum, valuation) => sum + valuation.costInBaseCurrency,
    );
    final totalValue = valuations.fold<double>(
      0,
      (sum, valuation) => sum + valuation.currentValueInBaseCurrency,
    );
    final totalProfit = totalValue - totalCost;
    final profitPercent = totalCost <= 0
        ? 0.0
        : (totalProfit / totalCost) * 100;

    debugPrint(
      '📊 Tek finans motoru -> '
      'maliyet: $totalCost $baseCurrency, '
      'güncel: $totalValue $baseCurrency, '
      'K/Z: $totalProfit $baseCurrency',
    );

    return PortfolioValuation(
      baseCurrency: baseCurrency,
      items: valuations,
      totalCost: totalCost,
      totalValue: totalValue,
      totalProfit: totalProfit,
      profitPercent: profitPercent,
      updatedAt: valuations.any((item) => item.hasLivePrice)
          ? DateTime.now()
          : persisted?.updatedAt,
      isStale:
          usedOfflineValue || valuations.every((item) => !item.hasLivePrice),
    );
  }

  PortfolioValuation? _restorePersisted(
    List<PortfolioItem> items,
    String fingerprint,
  ) {
    final snapshot =
        _persistedValuations[fingerprint] ??
        _latestCompatibleSnapshot(items, fingerprint);
    if (snapshot == null) return null;
    final itemsById = {for (final item in items) item.id: item};
    final restoredItems = <PortfolioItemValuation>[];
    for (final stored in snapshot.items) {
      final item = itemsById[stored.id];
      if (item == null) continue;
      restoredItems.add(
        PortfolioItemValuation(
          item: item,
          costInBaseCurrency: stored.cost,
          currentValueInBaseCurrency: stored.value,
          profitLossInBaseCurrency: stored.profit,
          profitPercent: stored.percent,
          hasLivePrice: false,
        ),
      );
    }
    if (restoredItems.length != items.length) return null;
    final totalCost = restoredItems.fold<double>(
      0,
      (sum, item) => sum + item.costInBaseCurrency,
    );
    final totalValue = restoredItems.fold<double>(
      0,
      (sum, item) => sum + item.currentValueInBaseCurrency,
    );
    final totalProfit = totalValue - totalCost;
    return PortfolioValuation(
      baseCurrency: baseCurrency,
      items: restoredItems,
      totalCost: totalCost,
      totalValue: totalValue,
      totalProfit: totalProfit,
      profitPercent: totalCost <= 0 ? 0 : (totalProfit / totalCost) * 100,
      updatedAt: snapshot.updatedAt,
      isStale: true,
    );
  }

  _PersistedValuation? _latestCompatibleSnapshot(
    List<PortfolioItem> items,
    String fingerprint,
  ) {
    if (items.isEmpty) return null;

    final separatorIndex = fingerprint.indexOf('::');
    final userPrefix = separatorIndex < 0
        ? fingerprint
        : fingerprint.substring(0, separatorIndex);
    final currentIds = items.map((item) => item.id).toSet();
    _PersistedValuation? latest;

    for (final entry in _persistedValuations.entries) {
      if (!entry.key.startsWith('$userPrefix::')) continue;

      final snapshotIds = entry.value.items.map((item) => item.id).toSet();
      if (snapshotIds.length != currentIds.length ||
          !snapshotIds.containsAll(currentIds)) {
        continue;
      }

      if (latest == null || entry.value.updatedAt.isAfter(latest.updatedAt)) {
        latest = entry.value;
      }
    }

    if (latest != null) {
      debugPrint(
        'OFFLINE PORTFOLIO SNAPSHOT: aynı varlıklar için son başarılı '
        'değer anında gösteriliyor.',
      );
    }
    return latest;
  }

  Future<void> _persist(
    String fingerprint,
    PortfolioValuation valuation,
  ) async {
    try {
      _persistedValuations[fingerprint] = _PersistedValuation.fromValuation(
        valuation,
      );
      while (_persistedValuations.length > 6) {
        _persistedValuations.remove(_persistedValuations.keys.first);
      }
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _offlineStorageKey,
        jsonEncode({
          for (final entry in _persistedValuations.entries)
            entry.key: entry.value.toJson(),
        }),
      );
    } catch (error) {
      debugPrint('OFFLINE PORTFOLIO SNAPSHOT yazılamadı: $error');
    }
  }

  Future<List<PortfolioItemValuation>> _calculateItems(
    List<PortfolioItem> portfolioItems, {
    required bool forceRefresh,
  }) async {
    final valuations = <PortfolioItemValuation>[];

    // Portföy ekranındaki özet, en yavaş fiyat isteğini beklediği için küçük
    // ardışık gruplar kartın görünmesini gereksiz yere geciktiriyordu. Normal
    // bir portföyün fiyatlarını tek dalgada hazırlayıp büyük portföylerde de
    // sağlayıcıyı korumak için makul bir üst sınır kullanıyoruz.
    const batchSize = 20;
    for (var index = 0; index < portfolioItems.length; index += batchSize) {
      final proposedEnd = index + batchSize;
      final end = proposedEnd < portfolioItems.length
          ? proposedEnd
          : portfolioItems.length;
      final batch = portfolioItems.sublist(index, end);
      valuations.addAll(
        await Future.wait(
          batch.map((item) => _calculateItem(item, forceRefresh: forceRefresh)),
        ),
      );
    }
    return valuations;
  }

  Future<PortfolioItemValuation> _calculateItem(
    PortfolioItem item, {
    required bool forceRefresh,
  }) async {
    final costInBase = await _convertToBaseOrZero(
      amount: item.totalCost,
      currency: item.currency,
      forceRefresh: forceRefresh,
    );

    if (costInBase <= 0 && item.totalCost > 0) {
      debugPrint(
        '⚠️ ${item.symbol}: maliyet ${item.currency} -> '
        '$baseCurrency çevrilemedi; özete dahil edilmedi.',
      );

      return PortfolioItemValuation(
        item: item,
        costInBaseCurrency: 0,
        currentValueInBaseCurrency: 0,
        profitLossInBaseCurrency: 0,
        profitPercent: 0,
        hasLivePrice: false,
      );
    }

    try {
      final quote = await MarketService.instance.getQuote(
        _marketSymbolFor(item),
        exchange: _marketExchangeFor(item),
        forceRefresh: forceRefresh,
      );

      final liveValue = item.quantity * quote.price;
      final currentValueInBase = await _convertToBaseOrZero(
        amount: liveValue,
        currency: quote.currency,
        forceRefresh: forceRefresh,
      );

      if (currentValueInBase <= 0 && liveValue > 0) {
        throw StateError(
          '${quote.currency} -> $baseCurrency dönüşümü yapılamadı.',
        );
      }

      final profitLoss = currentValueInBase - costInBase;
      final profitPercent = costInBase <= 0
          ? 0.0
          : (profitLoss / costInBase) * 100;

      debugPrint(
        '📈 ${item.symbol}: '
        '$costInBase -> $currentValueInBase $baseCurrency '
        '(${profitPercent.toStringAsFixed(2)}%)',
      );

      return PortfolioItemValuation(
        item: item,
        costInBaseCurrency: costInBase,
        currentValueInBaseCurrency: currentValueInBase,
        profitLossInBaseCurrency: profitLoss,
        profitPercent: profitPercent,
        hasLivePrice: true,
      );
    } catch (error) {
      debugPrint(
        'ℹ️ ${item.symbol}: canlı fiyat alınamadı, '
        'dönüştürülmüş maliyet kullanılıyor. $error',
      );

      return PortfolioItemValuation(
        item: item,
        costInBaseCurrency: costInBase,
        currentValueInBaseCurrency: costInBase,
        profitLossInBaseCurrency: 0,
        profitPercent: 0,
        hasLivePrice: false,
      );
    }
  }

  Future<double> _convertToBaseOrZero({
    required double amount,
    required String currency,
    required bool forceRefresh,
  }) async {
    if (amount == 0) return 0;

    try {
      return await CurrencyConversionService.instance.convert(
        amount: amount,
        from: currency,
        to: baseCurrency,
        forceRefresh: forceRefresh,
      );
    } catch (error) {
      debugPrint(
        '⚠️ Kur dönüşümü başarısız: '
        '$amount $currency -> $baseCurrency. $error',
      );
      return 0;
    }
  }

  String _marketSymbolFor(PortfolioItem item) {
    final symbol = item.symbol.trim().toUpperCase();
    final type = item.type.trim().toLowerCase();

    if (type == 'döviz' || type == 'doviz') {
      if (symbol.contains('/')) {
        return symbol;
      }

      if (symbol.length == 3) {
        return '$symbol/TRY';
      }
    }

    return symbol;
  }

  String? _marketExchangeFor(PortfolioItem item) {
    final type = item.type.trim().toLowerCase();
    final currency = item.currency.trim().toUpperCase();

    if (type == 'kripto' || type == 'crypto') {
      return 'CRYPTO';
    }

    if ((type == 'hisse' || type == 'bist') && currency == 'TRY') {
      return 'XIST';
    }

    return null;
  }
}

class _ValuationCacheEntry {
  final PortfolioValuation valuation;
  final DateTime savedAt;
  final bool hasAnyLivePrice;

  const _ValuationCacheEntry({
    required this.valuation,
    required this.savedAt,
    required this.hasAnyLivePrice,
  });

  bool get isFresh {
    if (!hasAnyLivePrice) return false;
    return DateTime.now().difference(savedAt) < const Duration(seconds: 30);
  }
}

class _PersistedValuation {
  final DateTime updatedAt;
  final List<_PersistedValuationItem> items;

  const _PersistedValuation({required this.updatedAt, required this.items});

  factory _PersistedValuation.fromValuation(PortfolioValuation valuation) {
    return _PersistedValuation(
      updatedAt: valuation.updatedAt ?? DateTime.now(),
      items: valuation.items
          .map(
            (item) => _PersistedValuationItem(
              id: item.item.id,
              cost: item.costInBaseCurrency,
              value: item.currentValueInBaseCurrency,
              profit: item.profitLossInBaseCurrency,
              percent: item.profitPercent,
            ),
          )
          .toList(growable: false),
    );
  }

  static _PersistedValuation? fromJson(Map<String, dynamic> json) {
    final updatedAt = DateTime.tryParse(json['updatedAt']?.toString() ?? '');
    final rawItems = json['items'];
    if (updatedAt == null || rawItems is! List) return null;
    final items = rawItems
        .whereType<Map>()
        .map(
          (item) =>
              _PersistedValuationItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .whereType<_PersistedValuationItem>()
        .toList(growable: false);
    if (items.isEmpty) return null;
    return _PersistedValuation(updatedAt: updatedAt, items: items);
  }

  Map<String, dynamic> toJson() => {
    'updatedAt': updatedAt.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(growable: false),
  };
}

class _PersistedValuationItem {
  final String id;
  final double cost;
  final double value;
  final double profit;
  final double percent;

  const _PersistedValuationItem({
    required this.id,
    required this.cost,
    required this.value,
    required this.profit,
    required this.percent,
  });

  static _PersistedValuationItem? fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    if (id.isEmpty) return null;
    return _PersistedValuationItem(
      id: id,
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      value: (json['value'] as num?)?.toDouble() ?? 0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0,
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cost': cost,
    'value': value,
    'profit': profit,
    'percent': percent,
  };
}
