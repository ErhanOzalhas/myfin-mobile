class PortfolioAnalysis {
  final int aiScore;
  final int risk;
  final int growth;
  final int stability;
  final int diversification;

  final String riskLevel;
  final String investmentStyle;
  final String focus;
  final String summary;

  final List<String> strengths;
  final List<String> warnings;
  final List<String> recommendations;

  const PortfolioAnalysis({
    required this.aiScore,
    required this.risk,
    required this.growth,
    required this.stability,
    required this.diversification,
    required this.riskLevel,
    required this.investmentStyle,
    required this.focus,
    required this.summary,
    required this.strengths,
    required this.warnings,
    required this.recommendations,
  });
}