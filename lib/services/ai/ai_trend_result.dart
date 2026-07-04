class AITrendResult {
  final int? aiScoreChange;
  final int? riskChange;
  final int? diversificationChange;

  const AITrendResult({
    required this.aiScoreChange,
    required this.riskChange,
    required this.diversificationChange,
  });

  bool get hasPreviousData {
    return aiScoreChange != null ||
        riskChange != null ||
        diversificationChange != null;
  }
}
