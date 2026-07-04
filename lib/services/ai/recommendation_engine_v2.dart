import 'portfolio_analysis.dart';

enum RecommendationPriority {
  critical,
  medium,
  opportunity,
}

class AIRecommendationInsight {
  final RecommendationPriority priority;
  final int impactScore;
  final String title;
  final String message;
  final String reasoning;
  final String action;

  const AIRecommendationInsight({
    required this.priority,
    required this.impactScore,
    required this.title,
    required this.message,
    required this.reasoning,
    required this.action,
  });
}

class RecommendationEngineV2 {
  const RecommendationEngineV2();

  List<AIRecommendationInsight> generate(PortfolioAnalysis analysis) {
    final insights = <AIRecommendationInsight>[];

    if (analysis.risk >= 75) {
      insights.add(
        const AIRecommendationInsight(
          priority: RecommendationPriority.critical,
          impactScore: -12,
          title: 'Risk seviyesi yüksek',
          message: 'Portföyünüz mevcut yapısıyla yüksek risk taşıyor.',
          reasoning:
              'Risk skoru 75 üzerindeyse portföy dalgalanmalara karşı daha hassas kabul edilir.',
          action:
              'Farklı sektör veya varlık sınıflarından ekleme yaparak riski dağıtmayı değerlendirin.',
        ),
      );
    }

    if (analysis.diversification < 50) {
      insights.add(
        const AIRecommendationInsight(
          priority: RecommendationPriority.critical,
          impactScore: -10,
          title: 'Çeşitlendirme düşük',
          message: 'Portföy birkaç varlık üzerinde yoğunlaşmış görünüyor.',
          reasoning:
              'Düşük çeşitlendirme, tek bir varlıktaki düşüşün portföyü daha fazla etkilemesine neden olabilir.',
          action:
              'Portföye farklı sektörlerden veya farklı varlık tiplerinden yeni pozisyonlar ekleyin.',
        ),
      );
    }

    if (analysis.stability < 60) {
      insights.add(
        const AIRecommendationInsight(
          priority: RecommendationPriority.medium,
          impactScore: -6,
          title: 'İstikrar güçlendirilebilir',
          message: 'Portföy istikrarı orta seviyenin altında görünüyor.',
          reasoning:
              'İstikrar skoru düşük olduğunda portföyün kısa vadeli oynaklığı artabilir.',
          action:
              'Daha dengeli veya savunmacı varlıklar eklemeyi değerlendirin.',
        ),
      );
    }

    if (analysis.growth >= 80) {
      insights.add(
        const AIRecommendationInsight(
          priority: RecommendationPriority.opportunity,
          impactScore: 8,
          title: 'Büyüme potansiyeli güçlü',
          message: 'Portföyünüz büyüme odaklı bir yapı gösteriyor.',
          reasoning:
              'Yüksek büyüme skoru, portföyün uzun vadeli getiri potansiyelinin güçlü olduğunu gösterir.',
          action:
              'Büyüme potansiyelini korurken risk dengesini izlemeye devam edin.',
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        const AIRecommendationInsight(
          priority: RecommendationPriority.opportunity,
          impactScore: 4,
          title: 'Portföy dengeli görünüyor',
          message: 'Şu an için kritik bir AI uyarısı bulunmuyor.',
          reasoning:
              'Risk, çeşitlendirme ve istikrar metrikleri kabul edilebilir aralıkta.',
          action:
              'Portföyünüzü düzenli takip etmeye devam edin.',
        ),
      );
    }

    insights.sort((a, b) {
      int priorityRank(RecommendationPriority p) {
        switch (p) {
          case RecommendationPriority.critical:
            return 0;
          case RecommendationPriority.medium:
            return 1;
          case RecommendationPriority.opportunity:
            return 2;
        }
      }

      final priorityCompare =
          priorityRank(a.priority).compareTo(priorityRank(b.priority));

      if (priorityCompare != 0) return priorityCompare;

      return b.impactScore.abs().compareTo(a.impactScore.abs());
    });

    return insights;
  }
}