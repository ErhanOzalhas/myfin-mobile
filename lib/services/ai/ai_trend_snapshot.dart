class QuickWin {
  final int impact;
  final String title;
  final String reason;

  const QuickWin({
    required this.impact,
    required this.title,
    required this.reason,
  });
}

class AITrendSnapshot {
  final int currentScore;
  final int? scoreChange;

  final int currentRisk;
  final int? riskChange;

  final int currentDiversification;
  final int? diversificationChange;

  final int currentStability;
  final int? stabilityChange;

  final int currentGrowth;
  final int? growthChange;

  final int targetScore;
  final List<QuickWin> quickWins;

  const AITrendSnapshot({
    required this.currentScore,
    required this.scoreChange,
    required this.currentRisk,
    required this.riskChange,
    required this.currentDiversification,
    required this.diversificationChange,
    required this.currentStability,
    required this.stabilityChange,
    required this.currentGrowth,
    required this.growthChange,
    required this.targetScore,
    required this.quickWins,
  });

  int get remainingToTarget {
    final remaining = targetScore - currentScore;
    return remaining < 0 ? 0 : remaining;
  }
}