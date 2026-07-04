enum RiskLevel {
  low,
  medium,
  high,
}

class AIPortfolioScore {
  const AIPortfolioScore({
    required this.overallScore,
    required this.diversification,
    required this.momentum,
    required this.stability,
    required this.risk,
    required this.summary,
  });

  final int overallScore;
  final int diversification;
  final int momentum;
  final int stability;
  final RiskLevel risk;
  final String summary;

  String get riskLabel {
    switch (risk) {
      case RiskLevel.low:
        return 'Düşük';
      case RiskLevel.medium:
        return 'Orta';
      case RiskLevel.high:
        return 'Yüksek';
    }
  }

  String get scoreLabel {
    if (overallScore >= 75) return 'Güçlü';
    if (overallScore >= 50) return 'Dengeli';
    return 'Riskli';
  }
}