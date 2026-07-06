import 'ai_service.dart';

/// Builds a compact, AI-friendly portfolio context for MyFin.
///
/// This service converts raw portfolio values into the [PortfolioContext]
/// model used by [AIService]. It intentionally has no UI dependency and can be
/// fed from local state, Firebase, SQLite, REST responses, or test data.
class PortfolioContextBuilder {
  const PortfolioContextBuilder({
    this.baseCurrency = 'TRY',
    this.maxHoldingsInPrompt = 20,
  });

  final String baseCurrency;
  final int maxHoldingsInPrompt;

  PortfolioContext build(PortfolioContextInput input) {
    final List<PortfolioAssetInput> assets = input.assets
        .where((PortfolioAssetInput asset) => asset.symbol.trim().isNotEmpty)
        .toList();

    final double assetsValue = assets.fold<double>(
      0,
      (double total, PortfolioAssetInput asset) => total + asset.currentValue,
    );

    final double cashBalance = input.cashBalance < 0 ? 0 : input.cashBalance;
    final double totalValue = input.totalValue > 0
        ? input.totalValue
        : assetsValue + cashBalance;

    final List<PortfolioAssetInput> sortedByValue = List<PortfolioAssetInput>.of(
      assets,
    )..sort((PortfolioAssetInput a, PortfolioAssetInput b) {
        return b.currentValue.compareTo(a.currentValue);
      });

    final List<PortfolioHolding> holdings = sortedByValue
        .take(maxHoldingsInPrompt < 1 ? 1 : maxHoldingsInPrompt)
        .map((PortfolioAssetInput asset) {
      final double weight = totalValue <= 0 ? 0 : asset.currentValue / totalValue;
      return PortfolioHolding(
        symbol: asset.symbol.trim().toUpperCase(),
        name: _blankToNull(asset.name),
        quantityText: asset.quantity > 0 ? _formatNumber(asset.quantity) : null,
        valueText: _formatMoney(asset.currentValue, input.currency),
        changeText: _formatChange(asset.unrealizedGainLossPercent),
        weightText: _formatPercent(weight),
      );
    }).toList(growable: false);

    return PortfolioContext(
      totalValueText: totalValue > 0 ? _formatMoney(totalValue, input.currency) : null,
      dailyChangeText: input.dailyChangePercent == null
          ? null
          : _formatChange(input.dailyChangePercent!),
      cashBalanceText: cashBalance > 0
          ? '${_formatMoney(cashBalance, input.currency)} (${_formatPercent(totalValue <= 0 ? 0 : cashBalance / totalValue)})'
          : null,
      riskLevel: _estimateRiskLevel(
        totalValue: totalValue,
        cashBalance: cashBalance,
        assets: assets,
      ),
      holdings: holdings,
    );
  }

  PortfolioContext buildFromMaps({
    required List<Map<String, dynamic>> assets,
    double cashBalance = 0,
    double totalValue = 0,
    double? dailyChangePercent,
    String? currency,
  }) {
    return build(
      PortfolioContextInput(
        assets: assets.map(PortfolioAssetInput.fromJson).toList(growable: false),
        cashBalance: cashBalance,
        totalValue: totalValue,
        dailyChangePercent: dailyChangePercent,
        currency: currency ?? baseCurrency,
      ),
    );
  }

  String _estimateRiskLevel({
    required double totalValue,
    required double cashBalance,
    required List<PortfolioAssetInput> assets,
  }) {
    if (totalValue <= 0 || assets.isEmpty) return 'Unknown';

    final double cashRatio = cashBalance / totalValue;
    final double largestWeight = assets.fold<double>(0, (
      double largest,
      PortfolioAssetInput asset,
    ) {
      final double weight = asset.currentValue / totalValue;
      return weight > largest ? weight : largest;
    });

    final int riskyAssets = assets.where((PortfolioAssetInput asset) {
      final String type = asset.assetType.trim().toLowerCase();
      return type.contains('crypto') ||
          type.contains('coin') ||
          type.contains('option') ||
          type.contains('leveraged') ||
          type.contains('kaldıraç');
    }).length;

    if (largestWeight >= 0.45 || riskyAssets >= 3 || cashRatio < 0.03) {
      return 'High';
    }
    if (largestWeight >= 0.30 || riskyAssets >= 1 || cashRatio < 0.08) {
      return 'Medium';
    }
    return 'Low';
  }

  String _formatMoney(double value, String currency) {
    final String symbol = _currencySymbol(currency);
    final String formatted = _formatNumber(value);
    return '$symbol$formatted';
  }

  String _formatNumber(double value) {
    final bool isNegative = value < 0;
    final double absolute = value.abs();

    if (absolute >= 1000000000) {
      return '${isNegative ? '-' : ''}${(absolute / 1000000000).toStringAsFixed(2)}B';
    }
    if (absolute >= 1000000) {
      return '${isNegative ? '-' : ''}${(absolute / 1000000).toStringAsFixed(2)}M';
    }
    if (absolute >= 10000) {
      return '${isNegative ? '-' : ''}${(absolute / 1000).toStringAsFixed(1)}K';
    }
    if (absolute >= 100) {
      return '${isNegative ? '-' : ''}${absolute.toStringAsFixed(0)}';
    }
    if (absolute >= 1) {
      return '${isNegative ? '-' : ''}${absolute.toStringAsFixed(2)}';
    }
    return '${isNegative ? '-' : ''}${absolute.toStringAsFixed(4)}';
  }

  String _formatPercent(double ratio) {
    return '${(ratio * 100).toStringAsFixed(1)}%';
  }

  String _formatChange(double percentValue) {
    final String sign = percentValue > 0 ? '+' : '';
    return '$sign${percentValue.toStringAsFixed(2)}%';
  }

  String _currencySymbol(String currency) {
    switch (currency.trim().toUpperCase()) {
      case 'TRY':
      case 'TL':
        return '₺';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '${currency.trim().toUpperCase()} ';
    }
  }

  String? _blankToNull(String? value) {
    final String? trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

class PortfolioContextInput {
  const PortfolioContextInput({
    required this.assets,
    this.cashBalance = 0,
    this.totalValue = 0,
    this.dailyChangePercent,
    this.currency = 'TRY',
  });

  final List<PortfolioAssetInput> assets;
  final double cashBalance;
  final double totalValue;
  final double? dailyChangePercent;
  final String currency;

  bool get isEmpty => assets.isEmpty && cashBalance <= 0 && totalValue <= 0;
}

class PortfolioAssetInput {
  const PortfolioAssetInput({
    required this.symbol,
    this.name,
    this.assetType = 'stock',
    this.quantity = 0,
    this.currentPrice = 0,
    this.currentValue = 0,
    this.averageCost = 0,
    this.unrealizedGainLossPercent = 0,
  });

  final String symbol;
  final String? name;
  final String assetType;
  final double quantity;
  final double currentPrice;
  final double currentValue;
  final double averageCost;
  final double unrealizedGainLossPercent;

  factory PortfolioAssetInput.fromJson(Map<String, dynamic> json) {
    return PortfolioAssetInput(
      symbol: _readString(json, <String>['symbol', 'ticker', 'code']),
      name: _readNullableString(json, <String>['name', 'title', 'companyName']),
      assetType: _readString(json, <String>['assetType', 'type', 'category'], fallback: 'stock'),
      quantity: _readDouble(json, <String>['quantity', 'qty', 'shares', 'amount']),
      currentPrice: _readDouble(json, <String>['currentPrice', 'price', 'lastPrice']),
      currentValue: _readDouble(json, <String>['currentValue', 'value', 'marketValue', 'totalValue']),
      averageCost: _readDouble(json, <String>['averageCost', 'avgCost', 'costBasis']),
      unrealizedGainLossPercent: _readDouble(
        json,
        <String>['unrealizedGainLossPercent', 'gainLossPercent', 'changePercent', 'profitPercent'],
      ),
    );
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final String key in keys) {
      final Object? value = json[key];
      if (value == null) continue;
      final String text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  static String? _readNullableString(Map<String, dynamic> json, List<String> keys) {
    final String value = _readString(json, keys);
    return value.isEmpty ? null : value;
  }

  static double _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final String key in keys) {
      final Object? value = json[key];
      if (value == null) continue;
      if (value is num) return value.toDouble();
      final double? parsed = double.tryParse(
        value.toString().replaceAll('%', '').replaceAll(',', '.').trim(),
      );
      if (parsed != null) return parsed;
    }
    return 0;
  }
}

extension PortfolioContextPromptExtension on PortfolioContext {
  String toPrompt() {
    if (isEmpty) return 'Portfolio context is empty.';

    final StringBuffer buffer = StringBuffer('Portfolio Summary');
    if (totalValueText != null && totalValueText!.trim().isNotEmpty) {
      buffer.writeln('\nTotal Value: $totalValueText');
    }
    if (dailyChangeText != null && dailyChangeText!.trim().isNotEmpty) {
      buffer.writeln('Daily Change: $dailyChangeText');
    }
    if (cashBalanceText != null && cashBalanceText!.trim().isNotEmpty) {
      buffer.writeln('Cash: $cashBalanceText');
    }
    if (riskLevel != null && riskLevel!.trim().isNotEmpty) {
      buffer.writeln('Risk Level: $riskLevel');
    }
    if (holdings.isNotEmpty) {
      buffer.writeln('Holdings:');
      for (final PortfolioHolding holding in holdings) {
        buffer.writeln('- ${holding.symbol}: ${holding.displaySummary}');
      }
    }
    return buffer.toString().trim();
  }
}
