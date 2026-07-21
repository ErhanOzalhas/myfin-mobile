import '../../models/market_mood.dart';

class MarketMoodEngine {
  const MarketMoodEngine();

  static const modelVersion = 'myfin-market-mood-v1.0.0';

  MarketMoodResult calculate(
    List<MarketMoodObservation> observations, {
    required double expectedWeight,
    DateTime? now,
  }) {
    final structurallyValid = observations
        .where(
          (item) =>
              item.changePercent.isFinite && item.weight > 0 && item.scale > 0,
        )
        .toList(growable: false);
    final rejected = structurallyValid
        .where((item) => item.changePercent.abs() > item.maxAbsDailyChange)
        .toList(growable: false);
    final valid = structurallyValid
        .where((item) => item.changePercent.abs() <= item.maxAbsDailyChange)
        .toList(growable: false);
    final totalWeight = valid.fold<double>(0, (sum, item) => sum + item.weight);
    final coverage = expectedWeight <= 0
        ? 0.0
        : (totalWeight / expectedWeight).clamp(0, 1).toDouble();

    if (valid.isEmpty || coverage < .30) {
      return MarketMoodResult(
        score: 50,
        confidence: (coverage * 50).round(),
        coverage: coverage,
        breadth: 0,
        regime: MarketMoodRegime.insufficient,
        drivers: const [],
        updatedAt: null,
        observationCount: valid.length,
        rejectedIndicators: List.unmodifiable(
          rejected.map((item) => item.label),
        ),
      );
    }

    var weightedSignal = 0.0;
    final impacts = <MarketMoodDriver>[];
    for (final item in valid) {
      final normalized = (item.changePercent / item.scale).clamp(-1, 1);
      final impact = normalized * item.orientation * item.weight;
      weightedSignal += impact;
      impacts.add(
        MarketMoodDriver(
          label: item.label,
          changePercent: item.changePercent,
          impact: impact,
        ),
      );
    }

    final score = (50 + (weightedSignal / totalWeight * 50)).round().clamp(
      0,
      100,
    );
    final riskAssets = valid.where((item) => item.orientation > 0).toList();
    final positiveRiskAssets = riskAssets
        .where((item) => item.changePercent > 0)
        .length;
    final breadth = riskAssets.isEmpty
        ? 0.0
        : positiveRiskAssets / riskAssets.length;
    final referenceNow = now ?? DateTime.now();
    final freshWeight = valid
        .where(
          (item) =>
              referenceNow.difference(item.updatedAt).abs() <=
              const Duration(hours: 24),
        )
        .fold<double>(0, (sum, item) => sum + item.weight);
    final freshness = totalWeight <= 0 ? 0.0 : freshWeight / totalWeight;
    final breadthQuality = (riskAssets.length / 6).clamp(0, 1).toDouble();
    final confidence = (coverage * 65 + freshness * 25 + breadthQuality * 10)
        .round()
        .clamp(0, 100);

    impacts.sort((a, b) => b.impact.abs().compareTo(a.impact.abs()));

    return MarketMoodResult(
      score: score,
      confidence: confidence,
      coverage: coverage,
      breadth: breadth,
      regime: _regime(score, confidence),
      drivers: List.unmodifiable(impacts.take(3)),
      updatedAt: valid
          .map((item) => item.updatedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b),
      observationCount: valid.length,
      rejectedIndicators: List.unmodifiable(rejected.map((item) => item.label)),
    );
  }

  MarketMoodRegime _regime(int score, int confidence) {
    if (confidence < 35) return MarketMoodRegime.insufficient;
    if (score >= 70) return MarketMoodRegime.strongRiskOn;
    if (score >= 58) return MarketMoodRegime.riskOn;
    if (score >= 43) return MarketMoodRegime.neutral;
    if (score >= 30) return MarketMoodRegime.cautious;
    return MarketMoodRegime.riskOff;
  }
}
