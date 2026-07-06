class AIDailyBrief {
  const AIDailyBrief({
    required this.title,
    required this.summary,
    required this.priority,
    required this.score,
    required this.scoreChange,
    required this.confidence,
    required this.generatedAt,
  });

  final String title;
  final String summary;
  final String priority;
  final int score;
  final int scoreChange;
  final int confidence;
  final DateTime generatedAt;

  bool get isImproving => scoreChange >= 0;
}