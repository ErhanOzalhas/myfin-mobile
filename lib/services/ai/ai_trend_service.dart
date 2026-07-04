import 'ai_history_entry.dart';
import 'ai_trend_result.dart';

class AITrendService {
  const AITrendService();

  AITrendResult build(List<AIHistoryEntry> history) {
    if (history.length < 2 || history[1].aiScore == 0) {
  return const AITrendResult(
    aiScoreChange: null,
    riskChange: null,
    diversificationChange: null,
  );
}

    final latest = history.last;
final previous = history[history.length - 2];

    return AITrendResult(
      aiScoreChange: latest.aiScore - previous.aiScore,
      riskChange: latest.risk - previous.risk,
      diversificationChange:
          latest.diversification - previous.diversification,
    );
  }
}