class PortfolioIntelligence {
  const PortfolioIntelligence({
    required this.totalValue,
    required this.totalCost,
    required this.profitLoss,
    required this.profitLossPercent,
    required this.assetCount,
    required this.typeCount,
    required this.dominantAssetSymbol,
    required this.dominantAssetWeight,
    required this.dominantType,
    required this.dominantTypeWeight,
  });

  final double totalValue;
  final double totalCost;
  final double profitLoss;
  final double profitLossPercent;

  final int assetCount;
  final int typeCount;

  final String dominantAssetSymbol;
  final double dominantAssetWeight;

  final String dominantType;
  final double dominantTypeWeight;

  bool get isProfit => profitLoss >= 0;

  bool get hasDominantAsset => dominantAssetWeight >= .50;

  bool get hasDominantType => dominantTypeWeight >= .65;
}