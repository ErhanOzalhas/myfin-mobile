import 'ai_history_entry.dart';
import 'ai_trend_result.dart';
import 'ai_trend_snapshot.dart';
import 'portfolio_analysis.dart';

class AITrendEngine {
  const AITrendEngine();

  AITrendResult compare({
    required AIHistoryEntry? previous,
    required AIHistoryEntry? latest,
  }) {
    if (previous == null || latest == null) {
      return const AITrendResult(
        aiScoreChange: null,
        riskChange: null,
        diversificationChange: null,
      );
    }

    return AITrendResult(
      aiScoreChange: latest.aiScore - previous.aiScore,
      riskChange: latest.risk - previous.risk,
      diversificationChange:
          latest.diversification - previous.diversification,
    );
  }

  AITrendSnapshot buildSnapshot({
    required PortfolioAnalysis current,
    required AIHistoryEntry? previous,
    required AIHistoryEntry? latest,
  }) {
    final reference = latest ?? _entryFromAnalysis(current);

    return AITrendSnapshot(
      currentScore: current.aiScore,
      scoreChange: previous == null ? null : reference.aiScore - previous.aiScore,
      currentRisk: current.risk,
      riskChange: previous == null ? null : reference.risk - previous.risk,
      currentDiversification: current.diversification,
      diversificationChange: previous == null
          ? null
          : reference.diversification - previous.diversification,
      currentStability: current.stability,
      stabilityChange:
          previous == null ? null : reference.stability - previous.stability,
      currentGrowth: current.growth,
      growthChange: previous == null ? null : reference.growth - previous.growth,
      targetScore: _targetScoreFor(current),
      quickWins: _buildQuickWins(current),
    );
  }

  String aiScoreSummary(AITrendResult trend) {
    final change = trend.aiScoreChange;
    if (change == null) return 'AI skoru için henüz geçmiş veri yok.';
    if (change > 0) return 'AI skoru son analize göre +$change puan arttı.';
    if (change < 0) {
      return 'AI skoru son analize göre ${change.abs()} puan geriledi.';
    }
    return 'AI skoru son analize göre sabit kaldı.';
  }

  String riskSummary(AITrendResult trend) {
    final change = trend.riskChange;
    if (change == null) return 'Risk trendi için henüz geçmiş veri yok.';
    if (change > 0) return 'Risk son analize göre +$change puan yükseldi.';
    if (change < 0) return 'Risk son analize göre ${change.abs()} puan azaldı.';
    return 'Risk seviyesi son analize göre sabit kaldı.';
  }

  String diversificationSummary(AITrendResult trend) {
    final change = trend.diversificationChange;
    if (change == null) {
      return 'Çeşitlendirme trendi için henüz geçmiş veri yok.';
    }
    if (change > 0) {
      return 'Çeşitlendirme son analize göre +$change puan iyileşti.';
    }
    if (change < 0) {
      return 'Çeşitlendirme son analize göre ${change.abs()} puan geriledi.';
    }
    return 'Çeşitlendirme seviyesi son analize göre sabit kaldı.';
  }

  String directionLabel(int? change, {bool lowerIsBetter = false}) {
    if (change == null) return 'Yeni';
    if (change == 0) return 'Sabit';

    final isPositive = lowerIsBetter ? change < 0 : change > 0;
    return isPositive ? 'İyileşti' : 'Dikkat';
  }

  AIHistoryEntry _entryFromAnalysis(PortfolioAnalysis analysis) {
    return AIHistoryEntry(
      date: DateTime.now(),
      aiScore: analysis.aiScore,
      risk: analysis.risk,
      growth: analysis.growth,
      stability: analysis.stability,
      diversification: analysis.diversification,
    );
  }

  int _targetScoreFor(PortfolioAnalysis analysis) {
    if (analysis.aiScore >= 90) return 95;
    if (analysis.aiScore >= 80) return 90;
    if (analysis.aiScore >= 65) return 80;
    return 70;
  }

  List<QuickWin> _buildQuickWins(PortfolioAnalysis analysis) {
    final wins = <QuickWin>[];

    if (analysis.diversification < 50) {
      wins.add(
        const QuickWin(
          impact: 4,
          title: 'Çeşitlendirme ekle',
          reason: 'Farklı sektörlerden yeni varlıklar risk yoğunluğunu azaltabilir.',
        ),
      );
    }

    if (analysis.risk >= 75) {
      wins.add(
        const QuickWin(
          impact: 3,
          title: 'Riski dağıt',
          reason: 'Tek varlık veya tek sektör ağırlığını azaltmak skoru iyileştirebilir.',
        ),
      );
    }

    if (analysis.stability < 70) {
      wins.add(
        const QuickWin(
          impact: 2,
          title: 'Savunmacı varlık ekle',
          reason: 'Altın, fon veya ETF gibi varlıklar portföy istikrarını artırabilir.',
        ),
      );
    }

    if (analysis.growth < 70) {
      wins.add(
        const QuickWin(
          impact: 2,
          title: 'Büyüme potansiyelini artır',
          reason: 'Büyüme odaklı varlıklar uzun vadeli getiri potansiyelini destekleyebilir.',
        ),
      );
    }

    if (wins.isEmpty) {
      wins.add(
        const QuickWin(
          impact: 1,
          title: 'Düzenli takip et',
          reason: 'Portföy dengeli görünüyor; düzenli izleme mevcut kaliteyi korumaya yardımcı olur.',
        ),
      );
    }

    wins.sort((a, b) => b.impact.compareTo(a.impact));
    return wins.take(3).toList();
  }
}
