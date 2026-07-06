import '../models/ai/ai_timeline_point.dart';
import '../models/ai/portfolio_intelligence.dart';
import '../models/ai/smart_insight.dart';
import '../models/portfolio_item.dart';
import 'ai_analysis_service.dart';
import 'portfolio_intelligence_service.dart';

class SmartInsightsService {
  const SmartInsightsService();

  List<SmartInsight> build({
    required List<PortfolioItem> items,
    required List<AITimelinePoint> timeline,
  }) {
    final analysis = const AIAnalysisService().analyze(items);
    final portfolio = const PortfolioIntelligenceService().build(items);

    if (items.isEmpty) {
      return const [
        SmartInsight(
          type: SmartInsightType.opportunity,
          priority: SmartInsightPriority.high,
          title: 'İlk adım',
          message: 'Portföyünüze ilk varlığı eklediğinizde AI içgörüleri oluşmaya başlayacak.',
        ),
      ];
    }

    final insights = <SmartInsight>[];

    _addPortfolioRiskInsight(insights, portfolio);
    _addDiversificationInsight(insights, analysis.score.diversification);
    _addTimelineInsight(insights, timeline);
    _addGrowthInsight(insights, analysis.score.momentum);
    _addConfidenceInsight(insights, analysis.confidence);

    insights.sort((a, b) => _priorityRank(b.priority).compareTo(_priorityRank(a.priority)));

    return insights.take(4).toList(growable: false);
  }

  void _addPortfolioRiskInsight(
    List<SmartInsight> insights,
    PortfolioIntelligence portfolio,
  ) {
    if (portfolio.hasDominantAsset && portfolio.dominantAssetSymbol.isNotEmpty) {
      insights.add(
        SmartInsight(
          type: SmartInsightType.warning,
          priority: SmartInsightPriority.high,
          title: 'Yoğunlaşma riski',
          message:
              '${portfolio.dominantAssetSymbol} portföyünüzün %${(portfolio.dominantAssetWeight * 100).round()} oranını oluşturuyor.',
        ),
      );
      return;
    }

    insights.add(
      const SmartInsight(
        type: SmartInsightType.strength,
        priority: SmartInsightPriority.medium,
        title: 'Dağılım dengesi',
        message: 'En büyük pozisyon portföyünüzde yönetilebilir seviyede görünüyor.',
      ),
    );
  }

  void _addDiversificationInsight(
    List<SmartInsight> insights,
    int diversification,
  ) {
    if (diversification >= 75) {
      insights.add(
        const SmartInsight(
          type: SmartInsightType.strength,
          priority: SmartInsightPriority.medium,
          title: 'Çeşitlendirme güçlü',
          message: 'Portföyünüz farklı varlıklarla desteklenmiş görünüyor.',
        ),
      );
    } else {
      insights.add(
        const SmartInsight(
          type: SmartInsightType.opportunity,
          priority: SmartInsightPriority.high,
          title: 'Çeşitlendirme fırsatı',
          message: 'Farklı sektör, fon veya altın eklemek AI skorunu iyileştirebilir.',
        ),
      );
    }
  }

  void _addTimelineInsight(
    List<SmartInsight> insights,
    List<AITimelinePoint> timeline,
  ) {
    if (timeline.length < 2) return;

    final first = timeline.first.score;
    final last = timeline.last.score;
    final change = last - first;

    if (change > 0) {
      insights.add(
        SmartInsight(
          type: SmartInsightType.trend,
          priority: SmartInsightPriority.medium,
          title: 'Pozitif trend',
          message: 'AI skorunuz dönem içinde +$change puan gelişim göstermiş.',
        ),
      );
    } else if (change < 0) {
      insights.add(
        SmartInsight(
          type: SmartInsightType.warning,
          priority: SmartInsightPriority.medium,
          title: 'Skor gerilemesi',
          message: 'AI skorunuz dönem içinde ${change.abs()} puan gerilemiş görünüyor.',
        ),
      );
    }
  }

  void _addGrowthInsight(
    List<SmartInsight> insights,
    int momentum,
  ) {
    if (momentum >= 75) {
      insights.add(
        const SmartInsight(
          type: SmartInsightType.trend,
          priority: SmartInsightPriority.low,
          title: 'Büyüme potansiyeli',
          message: 'Portföy büyüme tarafında güçlü sinyal üretiyor.',
        ),
      );
    }
  }

  void _addConfidenceInsight(
    List<SmartInsight> insights,
    int confidence,
  ) {
    if (confidence >= 80) {
      insights.add(
        const SmartInsight(
          type: SmartInsightType.strength,
          priority: SmartInsightPriority.low,
          title: 'Veri kalitesi iyi',
          message: 'AI değerlendirmesi yeterli portföy verisiyle destekleniyor.',
        ),
      );
    }
  }

  int _priorityRank(SmartInsightPriority priority) {
    switch (priority) {
      case SmartInsightPriority.high:
        return 3;
      case SmartInsightPriority.medium:
        return 2;
      case SmartInsightPriority.low:
        return 1;
    }
  }
}