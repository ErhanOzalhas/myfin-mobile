import 'portfolio_analysis.dart';
import 'prediction_model.dart';

class PredictionEngine {
  const PredictionEngine();

  PredictionResult predictDiversificationBoost(PortfolioAnalysis analysis) {
    final predictedDiversification =
        (analysis.diversification + 22).clamp(0, 100);
    final predictedRisk = (analysis.risk - 14).clamp(0, 100);
    final predictedStability = (analysis.stability + 10).clamp(0, 100);
    final predictedGrowth = (analysis.growth - 2).clamp(0, 100);

    final predictedScore = _calculateScore(
      risk: predictedRisk,
      growth: predictedGrowth,
      stability: predictedStability,
      diversification: predictedDiversification,
    );

    return PredictionResult(
      currentScore: analysis.aiScore,
      predictedScore: predictedScore,
      currentRisk: analysis.risk,
      predictedRisk: predictedRisk,
      currentGrowth: analysis.growth,
      predictedGrowth: predictedGrowth,
      currentDiversification: analysis.diversification,
      predictedDiversification: predictedDiversification,
      currentStability: analysis.stability,
      predictedStability: predictedStability,
      confidence: 84,
      summary:
          'Farklı sektör veya varlık sınıfı eklemek portföy riskini azaltabilir ve AI skorunu iyileştirebilir.',
    );
  }

  int _calculateScore({
    required int risk,
    required int growth,
    required int stability,
    required int diversification,
  }) {
    return ((diversification * 0.35) +
            ((100 - risk) * 0.30) +
            (stability * 0.20) +
            (growth * 0.15))
        .round()
        .clamp(0, 100);
  }
}