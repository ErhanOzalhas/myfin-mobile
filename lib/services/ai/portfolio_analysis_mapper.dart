import 'package:myfin_mobile/models/ai_portfolio_score.dart';
import 'package:myfin_mobile/services/ai_analysis_service.dart';
import 'package:myfin_mobile/services/ai/portfolio_analysis.dart';

PortfolioAnalysis mapToPortfolioAnalysis(AIAnalysisResult result) {
  final score = result.score;

  final riskValue = switch (score.risk) {
    RiskLevel.low => 25,
    RiskLevel.medium => 60,
    RiskLevel.high => 90,
  };

  return PortfolioAnalysis(
    aiScore: score.overallScore,
    risk: riskValue,
    growth: score.momentum,
    stability: score.stability,
    diversification: score.diversification,
    riskLevel: score.riskLabel,
    investmentStyle: score.momentum >= score.stability
        ? 'Büyüme Odaklı'
        : 'Dengeli',
    focus: result.resultSummary,
    strengths: result.strengths,
    warnings: result.warnings,
    recommendations: result.recommendations,
  );
}