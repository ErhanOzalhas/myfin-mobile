import 'ai_history_entry.dart';
import 'ai_trend_result.dart';

class AITrendService {
  const AITrendService();

  AITrendResult build(List<AIHistoryEntry> history) {
    if (history.length < 2) {
      return const AITrendResult(
        aiScoreChange: 0,
        riskChange: 0,
        diversificationChange: 0,
      );
    }

    final latest = history.first;
    final previous = history[1];

    return AITrendResult(
      aiScoreChange: latest.aiScore - previous.aiScore,
      riskChange: latest.risk - previous.risk,
      diversificationChange:
          latest.diversification - previous.diversification,
    );
  }
}