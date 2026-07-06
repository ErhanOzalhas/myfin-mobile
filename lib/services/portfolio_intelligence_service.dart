import '../models/ai/portfolio_intelligence.dart';
import '../models/portfolio_item.dart';

class PortfolioIntelligenceService {
  const PortfolioIntelligenceService();

  PortfolioIntelligence build(List<PortfolioItem> items) {
    if (items.isEmpty) {
      return const PortfolioIntelligence(
        totalValue: 0,
        totalCost: 0,
        profitLoss: 0,
        profitLossPercent: 0,
        assetCount: 0,
        typeCount: 0,
        dominantAssetSymbol: '',
        dominantAssetWeight: 0,
        dominantType: '',
        dominantTypeWeight: 0,
      );
    }

    final totalCost = items.fold<double>(
      0,
      (sum, item) => sum + item.totalCost,
    );

    final totalValue = totalCost;

    final profitLoss = totalValue - totalCost;
    final profitLossPercent =
        totalCost <= 0 ? 0.0 : (profitLoss / totalCost) * 100;

    final assetCount =
        items.map((item) => item.symbol.toUpperCase().trim()).toSet().length;

    final typeCount =
        items.map((item) => item.type.toLowerCase().trim()).toSet().length;

    final dominantAsset = _dominantAsset(items, totalValue);
    final dominantType = _dominantType(items, totalValue);

    return PortfolioIntelligence(
      totalValue: totalValue,
      totalCost: totalCost,
      profitLoss: profitLoss,
      profitLossPercent: profitLossPercent,
      assetCount: assetCount,
      typeCount: typeCount,
      dominantAssetSymbol: dominantAsset.symbol,
      dominantAssetWeight: dominantAsset.weight,
      dominantType: dominantType.type,
      dominantTypeWeight: dominantType.weight,
    );
  }

  _DominantAsset _dominantAsset(
    List<PortfolioItem> items,
    double totalValue,
  ) {
    if (items.isEmpty || totalValue <= 0) {
      return const _DominantAsset(symbol: '', weight: 0);
    }

    PortfolioItem? dominant;
    double dominantValue = 0;

    for (final item in items) {
      if (item.totalCost > dominantValue) {
        dominant = item;
        dominantValue = item.totalCost;
      }
    }

    if (dominant == null) {
      return const _DominantAsset(symbol: '', weight: 0);
    }

    return _DominantAsset(
      symbol: dominant.symbol.toUpperCase().trim(),
      weight: dominantValue / totalValue,
    );
  }

  _DominantType _dominantType(
    List<PortfolioItem> items,
    double totalValue,
  ) {
    if (items.isEmpty || totalValue <= 0) {
      return const _DominantType(type: '', weight: 0);
    }

    final byType = <String, double>{};

    for (final item in items) {
      final type = item.type.toLowerCase().trim();
      byType[type] = (byType[type] ?? 0) + item.totalCost;
    }

    if (byType.isEmpty) {
      return const _DominantType(type: '', weight: 0);
    }

    final sorted = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.first;

    return _DominantType(
      type: top.key,
      weight: top.value / totalValue,
    );
  }
}

class _DominantAsset {
  const _DominantAsset({
    required this.symbol,
    required this.weight,
  });

  final String symbol;
  final double weight;
}

class _DominantType {
  const _DominantType({
    required this.type,
    required this.weight,
  });

  final String type;
  final double weight;
}