enum AIInsightType {
  strength,
  warning,
  opportunity,
}

class AIInsight {
  final AIInsightType type;
  final String title;
  final String message;

  const AIInsight({
    required this.type,
    required this.title,
    required this.message,
  });
}