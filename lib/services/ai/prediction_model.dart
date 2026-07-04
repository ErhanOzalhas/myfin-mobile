class PredictionResult {
  final int currentScore;
  final int predictedScore;

  final int currentRisk;
  final int predictedRisk;

  final int currentGrowth;
  final int predictedGrowth;

  final int currentDiversification;
  final int predictedDiversification;

  final int currentStability;
  final int predictedStability;

  /// AI'ın bu tahmine olan güveni (0-100)
  final int confidence;

  /// Kullanıcıya gösterilecek kısa özet
  final String summary;

  const PredictionResult({
    required this.currentScore,
    required this.predictedScore,
    required this.currentRisk,
    required this.predictedRisk,
    required this.currentGrowth,
    required this.predictedGrowth,
    required this.currentDiversification,
    required this.predictedDiversification,
    required this.currentStability,
    required this.predictedStability,
    required this.confidence,
    required this.summary,
  });

  int get scoreDelta => predictedScore - currentScore;

  int get riskDelta => predictedRisk - currentRisk;

  int get growthDelta => predictedGrowth - currentGrowth;

  int get diversificationDelta =>
      predictedDiversification - currentDiversification;

  int get stabilityDelta =>
      predictedStability - currentStability;
}