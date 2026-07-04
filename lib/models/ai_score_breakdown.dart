class AIScoreBreakdown {
  const AIScoreBreakdown({
    required this.diversification,
    required this.risk,
    required this.profitability,
    required this.allocation,
    required this.cashRatio,
    required this.stability,
    required this.growth,
  });

  final int diversification;
  final int risk;
  final int profitability;
  final int allocation;
  final int cashRatio;
  final int stability;
  final int growth;

  int get overallScore {
    final score =
        diversification * .20 +
        risk * .20 +
        profitability * .15 +
        allocation * .15 +
        cashRatio * .10 +
        stability * .10 +
        growth * .10;

    return score.round().clamp(0, 100);
  }
}