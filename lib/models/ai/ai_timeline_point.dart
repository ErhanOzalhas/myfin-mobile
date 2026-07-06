class AITimelinePoint {
  const AITimelinePoint({
    required this.label,
    required this.score,
    required this.riskLabel,
    required this.note,
  });

  final String label;
  final int score;
  final String riskLabel;
  final String note;
}