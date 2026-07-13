import 'package:flutter/foundation.dart';

import '../models/portfolio_item.dart';
import 'market/currency_conversion_service.dart';
import 'market/market_service.dart';

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

  const PortfolioValuation({
    required this.baseCurrency,
    required this.items,
    required this.totalCost,
    required this.totalValue,
    required this.totalProfit,
    required this.profitPercent,
  });

  int get assetCount => items.length;
}

class PortfolioValuationService {
  PortfolioValuationService._();

  static final PortfolioValuationService instance =
      PortfolioValuationService._();

  static const String baseCurrency = 'TRY';

  Future<PortfolioValuation> calculate(
    List<PortfolioItem> portfolioItems, {
    bool forceRefresh = false,
  }) async {
    final valuations = <PortfolioItemValuation>[];

    for (final item in portfolioItems) {
      valuations.add(
        await _calculateItem(
          item,
          forceRefresh: forceRefresh,
        ),
      );
    }

    final totalCost = valuations.fold<double>(
      0,
      (sum, valuation) => sum + valuation.costInBaseCurrency,
    );
    final totalValue = valuations.fold<double>(
      0,
      (sum, valuation) => sum + valuation.currentValueInBaseCurrency,
    );
    final totalProfit = totalValue - totalCost;
    final profitPercent =
        totalCost <= 0 ? 0.0 : (totalProfit / totalCost) * 100;

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
    );
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
      final profitPercent =
          costInBase <= 0 ? 0.0 : (profitLoss / costInBase) * 100;

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
}
