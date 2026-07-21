import 'dart:math' as math;

import '../../models/ai/portfolio_score_v2.dart';

class PortfolioScoreEngineV2 {
  const PortfolioScoreEngineV2();

  static const modelVersion = 'myfin-score-v2.0.0';

  PortfolioScoreResultV2 calculate(PortfolioScoreInput input) {
    final positions = input.positions
        .where(
          (position) =>
              position.marketValue.isFinite && position.marketValue > 0,
        )
        .toList(growable: false);
    final asOf = input.asOf ?? DateTime.now();

    if (positions.isEmpty) {
      return PortfolioScoreResultV2(
        modelVersion: modelVersion,
        overallScore: 0,
        riskScore: 0,
        confidence: 0,
        dataQuality: ScoreDataQuality.insufficient,
        breakdown: const PortfolioScoreBreakdownV2(
          concentration: 0,
          diversification: 0,
          marketRisk: 0,
          riskAdjustedPerformance: 0,
          liquidity: 0,
          cashBuffer: 0,
        ),
        contributions: const [],
        strengths: const [],
        warnings: const [
          'Skor için pozitif piyasa değerine sahip pozisyon bulunamadı.',
        ],
        asOf: asOf,
        baseCurrency: input.baseCurrency,
        largestPositionWeight: 0,
        effectiveAssetCount: 0,
      );
    }

    final totalValue = positions.fold<double>(
      0,
      (sum, item) => sum + item.marketValue,
    );
    final weights = <String, double>{};
    final classWeights = <String, double>{};
    final sectorWeights = <String, double>{};
    final countryWeights = <String, double>{};
    final currencyWeights = <String, double>{};

    for (final position in positions) {
      final weight = position.marketValue / totalValue;
      _add(weights, position.symbol, weight);
      _add(classWeights, position.assetClass, weight);
      _add(sectorWeights, position.sector, weight);
      _add(countryWeights, position.country, weight);
      _add(currencyWeights, position.currency, weight);
    }

    final largestWeight = _largest(weights);
    final assetHhi = _hhi(weights);
    final effectiveAssetCount = assetHhi == 0 ? 0.0 : 1 / assetHhi;
    final concentration = _concentrationScore(
      largestWeight: largestWeight,
      hhi: assetHhi,
      count: weights.length,
    );
    final diversification = _diversificationScore(
      assetWeights: weights,
      classWeights: classWeights,
      sectorWeights: sectorWeights,
      countryWeights: countryWeights,
      currencyWeights: currencyWeights,
    );
    final marketRisk = _marketRiskScore(positions, totalValue, largestWeight);
    final performance = _performanceScore(positions, totalValue);
    final liquidity = _liquidityScore(positions, totalValue);
    final cashBuffer = _cashBufferScore(classWeights);

    const componentWeights = <String, double>{
      'concentration': .25,
      'diversification': .20,
      'marketRisk': .25,
      'performance': .15,
      'liquidity': .10,
      'cashBuffer': .05,
    };
    final contributions = <PortfolioScoreContribution>[
      PortfolioScoreContribution(
        key: 'concentration',
        label: 'Konsantrasyon',
        score: concentration,
        weight: componentWeights['concentration']!,
      ),
      PortfolioScoreContribution(
        key: 'diversification',
        label: 'Çeşitlendirme',
        score: diversification,
        weight: componentWeights['diversification']!,
      ),
      PortfolioScoreContribution(
        key: 'marketRisk',
        label: 'Piyasa riski',
        score: marketRisk,
        weight: componentWeights['marketRisk']!,
      ),
      PortfolioScoreContribution(
        key: 'performance',
        label: 'Risk ayarlı performans',
        score: performance,
        weight: componentWeights['performance']!,
      ),
      PortfolioScoreContribution(
        key: 'liquidity',
        label: 'Likidite',
        score: liquidity,
        weight: componentWeights['liquidity']!,
      ),
      PortfolioScoreContribution(
        key: 'cashBuffer',
        label: 'Nakit tamponu',
        score: cashBuffer,
        weight: componentWeights['cashBuffer']!,
      ),
    ];
    final overall = contributions.fold<double>(
      0,
      (sum, item) => sum + item.points,
    );
    final confidence = _confidence(positions);
    final dataQuality = switch (confidence) {
      >= 85 => ScoreDataQuality.strong,
      >= 70 => ScoreDataQuality.good,
      >= 45 => ScoreDataQuality.limited,
      _ => ScoreDataQuality.insufficient,
    };
    final riskScore = (100 - marketRisk).round().clamp(0, 100);

    return PortfolioScoreResultV2(
      modelVersion: modelVersion,
      overallScore: overall.round().clamp(0, 100),
      riskScore: riskScore,
      confidence: confidence,
      dataQuality: dataQuality,
      breakdown: PortfolioScoreBreakdownV2(
        concentration: concentration,
        diversification: diversification,
        marketRisk: marketRisk,
        riskAdjustedPerformance: performance,
        liquidity: liquidity,
        cashBuffer: cashBuffer,
      ),
      contributions: List.unmodifiable(contributions),
      strengths: List.unmodifiable(
        _strengths(largestWeight, diversification, marketRisk, liquidity),
      ),
      warnings: List.unmodifiable(
        _warnings(positions, largestWeight, confidence),
      ),
      asOf: asOf,
      baseCurrency: input.baseCurrency,
      largestPositionWeight: largestWeight,
      effectiveAssetCount: effectiveAssetCount,
    );
  }

  double _concentrationScore({
    required double largestWeight,
    required double hhi,
    required int count,
  }) {
    if (count <= 1) return 10;
    final maxPositionScore = _linearInverse(largestWeight, good: .20, bad: .80);
    final hhiScore = _linearInverse(hhi, good: .12, bad: .65);
    return _clamp((maxPositionScore * .55) + (hhiScore * .45));
  }

  double _diversificationScore({
    required Map<String, double> assetWeights,
    required Map<String, double> classWeights,
    required Map<String, double> sectorWeights,
    required Map<String, double> countryWeights,
    required Map<String, double> currencyWeights,
  }) {
    final assets = _normalizedEntropy(assetWeights);
    final classes = _normalizedEntropy(classWeights);
    final sectors = _normalizedEntropy(sectorWeights);
    final countries = _normalizedEntropy(countryWeights);
    final currencies = _normalizedEntropy(currencyWeights);
    return _clamp(
      (assets * .35) +
          (classes * .25) +
          (sectors * .20) +
          (countries * .10) +
          (currencies * .10),
    );
  }

  double _marketRiskScore(
    List<PortfolioScorePosition> positions,
    double total,
    double largestWeight,
  ) {
    var weightedRisk = 0.0;
    for (final position in positions) {
      final weight = position.marketValue / total;
      final volatility = position.annualizedVolatility;
      final drawdown = position.maxDrawdown;
      final dataDrivenRisk = volatility == null && drawdown == null
          ? null
          : (((volatility ?? 0) * 120) + ((drawdown?.abs() ?? 0) * 80))
                .clamp(0, 100)
                .toDouble();
      weightedRisk +=
          (dataDrivenRisk ?? _assetRiskPrior(position.assetClass)) * weight;
    }
    final concentrationPenalty = largestWeight > .35
        ? (largestWeight - .35) * 45
        : 0;
    return _clamp(100 - weightedRisk - concentrationPenalty);
  }

  double _performanceScore(
    List<PortfolioScorePosition> positions,
    double total,
  ) {
    var coveredWeight = 0.0;
    var weightedReturn = 0.0;
    for (final position in positions) {
      if (position.costBasis <= 0) continue;
      final weight = position.marketValue / total;
      coveredWeight += weight;
      weightedReturn +=
          ((position.marketValue - position.costBasis) / position.costBasis)
              .clamp(-1, 2) *
          weight;
    }
    if (coveredWeight < .25 || !positions.any((item) => item.usesLivePrice)) {
      return 50;
    }
    final portfolioReturn = weightedReturn / coveredWeight;
    return _clamp(50 + (portfolioReturn * 100));
  }

  double _liquidityScore(List<PortfolioScorePosition> positions, double total) {
    var score = 0.0;
    for (final position in positions) {
      score +=
          (position.liquidityScore ?? _liquidityPrior(position.assetClass)) *
          (position.marketValue / total);
    }
    return _clamp(score);
  }

  double _cashBufferScore(Map<String, double> classWeights) {
    final cash = classWeights.entries
        .where((entry) => entry.key == 'cash' || entry.key == 'currency')
        .fold<double>(0, (sum, entry) => sum + entry.value);
    if (cash >= .08 && cash <= .20) return 100;
    if (cash < .08) return _clamp(35 + (cash / .08 * 65));
    return _clamp(100 - ((cash - .20) * 140));
  }

  int _confidence(List<PortfolioScorePosition> positions) {
    final total = positions.fold<double>(
      0,
      (sum, item) => sum + item.marketValue,
    );
    double livePrice = 0;
    double liveFx = 0;
    double history = 0;
    double metadata = 0;
    for (final item in positions) {
      final weight = item.marketValue / total;
      if (item.usesLivePrice) livePrice += weight;
      if (item.currency == 'TRY' || item.usesLiveFx) liveFx += weight;
      if (item.annualizedVolatility != null || item.maxDrawdown != null) {
        history += weight;
      }
      if (item.sector != 'unknown' && item.country != 'unknown') {
        metadata += weight;
      }
    }
    return (25 + livePrice * 25 + liveFx * 15 + history * 25 + metadata * 10)
        .round()
        .clamp(0, 100);
  }

  List<String> _strengths(
    double largestWeight,
    double diversification,
    double marketRisk,
    double liquidity,
  ) => [
    if (largestWeight <= .35) 'En büyük pozisyon makul bir ağırlıkta.',
    if (diversification >= 70)
      'Portföy varlık ve risk kaynaklarına dengeli yayılıyor.',
    if (marketRisk >= 70) 'Tahmini piyasa riski kontrollü bölgede.',
    if (liquidity >= 75) 'Portföyün tahmini likiditesi güçlü.',
  ];

  List<String> _warnings(
    List<PortfolioScorePosition> positions,
    double largestWeight,
    int confidence,
  ) => [
    if (largestWeight >= .60)
      'Tek pozisyon ağırlığı portföy riskini belirgin artırıyor.',
    if (!positions.any((item) => item.usesLivePrice))
      'Güncel fiyat bulunmadığı için maliyet değerleri kullanıldı.',
    if (positions.any((item) => item.currency != 'TRY' && !item.usesLiveFx))
      'Bazı döviz pozisyonları canlı kurla normalize edilemedi.',
    if (!positions.any(
      (item) => item.annualizedVolatility != null || item.maxDrawdown != null,
    ))
      'Fiyat geçmişi olmadığı için piyasa riski varlık sınıfı varsayımlarıyla hesaplandı.',
    if (confidence < 70)
      'Veri kapsamı sınırlı; skor yön gösterir ancak yüksek kesinlik taşımaz.',
  ];

  double _assetRiskPrior(String value) => switch (value) {
    'cash' => 5,
    'currency' => 28,
    'gold' => 32,
    'fund' || 'etf' => 38,
    'bond' => 22,
    'stock' => 58,
    'crypto' => 85,
    _ => 55,
  };

  double _liquidityPrior(String value) => switch (value) {
    'cash' || 'currency' => 98,
    'stock' || 'etf' || 'gold' => 82,
    'crypto' => 75,
    'fund' => 68,
    'bond' => 65,
    _ => 50,
  };

  void _add(Map<String, double> target, String rawKey, double value) {
    final key = rawKey.trim().toLowerCase().isEmpty
        ? 'unknown'
        : rawKey.trim().toLowerCase();
    target[key] = (target[key] ?? 0) + value;
  }

  double _largest(Map<String, double> values) =>
      values.isEmpty ? 0 : values.values.reduce((a, b) => a > b ? a : b);
  double _hhi(Map<String, double> values) =>
      values.values.fold(0, (sum, value) => sum + value * value);

  double _normalizedEntropy(Map<String, double> weights) {
    if (weights.length <= 1) return 0;
    var entropy = 0.0;
    for (final weight in weights.values) {
      if (weight > 0) entropy -= weight * math.log(weight);
    }
    return _clamp(entropy / math.log(weights.length) * 100);
  }

  double _linearInverse(
    double value, {
    required double good,
    required double bad,
  }) => _clamp((bad - value) / (bad - good) * 100);
  double _clamp(num value) => value.clamp(0, 100).toDouble();
}
