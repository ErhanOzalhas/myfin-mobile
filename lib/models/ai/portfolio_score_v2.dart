enum ScoreDataQuality { insufficient, limited, good, strong }

class PortfolioScorePosition {
  const PortfolioScorePosition({
    required this.symbol,
    required this.assetClass,
    required this.sector,
    required this.country,
    required this.currency,
    required this.marketValue,
    required this.costBasis,
    this.annualizedVolatility,
    this.maxDrawdown,
    this.liquidityScore,
    this.usesLivePrice = false,
    this.usesLiveFx = false,
  });

  final String symbol;
  final String assetClass;
  final String sector;
  final String country;
  final String currency;

  /// Market value and cost basis must use the input's common base currency.
  final double marketValue;
  final double costBasis;
  final double? annualizedVolatility;
  final double? maxDrawdown;
  final double? liquidityScore;
  final bool usesLivePrice;
  final bool usesLiveFx;
}

class PortfolioScoreInput {
  const PortfolioScoreInput({
    required this.positions,
    this.baseCurrency = 'TRY',
    this.asOf,
  });

  final List<PortfolioScorePosition> positions;
  final String baseCurrency;
  final DateTime? asOf;
}

class PortfolioScoreBreakdownV2 {
  const PortfolioScoreBreakdownV2({
    required this.concentration,
    required this.diversification,
    required this.marketRisk,
    required this.riskAdjustedPerformance,
    required this.liquidity,
    required this.cashBuffer,
  });

  final double concentration;
  final double diversification;
  final double marketRisk;
  final double riskAdjustedPerformance;
  final double liquidity;
  final double cashBuffer;
}

class PortfolioScoreContribution {
  const PortfolioScoreContribution({
    required this.key,
    required this.label,
    required this.score,
    required this.weight,
  });

  final String key;
  final String label;
  final double score;
  final double weight;

  double get points => score * weight;
}

class PortfolioScoreResultV2 {
  const PortfolioScoreResultV2({
    required this.modelVersion,
    required this.overallScore,
    required this.riskScore,
    required this.confidence,
    required this.dataQuality,
    required this.breakdown,
    required this.contributions,
    required this.strengths,
    required this.warnings,
    required this.asOf,
    required this.baseCurrency,
    required this.largestPositionWeight,
    required this.effectiveAssetCount,
  });

  final String modelVersion;
  final int overallScore;

  /// 0 means low risk, 100 means high risk.
  final int riskScore;
  final int confidence;
  final ScoreDataQuality dataQuality;
  final PortfolioScoreBreakdownV2 breakdown;
  final List<PortfolioScoreContribution> contributions;
  final List<String> strengths;
  final List<String> warnings;
  final DateTime asOf;
  final String baseCurrency;
  final double largestPositionWeight;
  final double effectiveAssetCount;

  bool get hasSufficientData => dataQuality != ScoreDataQuality.insufficient;
}
