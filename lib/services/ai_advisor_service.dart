import '../models/ai_portfolio_score.dart';
import '../models/portfolio_item.dart';
import 'ai_analysis_service.dart';

class AIAdvisorResult {
  const AIAdvisorResult({
    required this.headline,
    required this.dailyComment,
    required this.priority,
    required this.expectedScoreImpact,
    required this.expectedRiskLabel,
    required this.suggestion,
  });

  final String headline;
  final String dailyComment;
  final String priority;
  final int expectedScoreImpact;
  final String expectedRiskLabel;
  final String suggestion;
}

class AIAdvisorService {
  const AIAdvisorService();

  AIAdvisorResult advise(List<PortfolioItem> items) {
    final analysis = const AIAnalysisService().analyze(items);
    final score = analysis.score;

    if (items.isEmpty) {
      return const AIAdvisorResult(
        headline: 'Portföyünüzü oluşturmaya başlayın',
        dailyComment:
            'AI danışmanı analiz yapabilmek için portföyünüzde en az bir varlık bekliyor.',
        priority: 'İlk varlığınızı ekleyin.',
        expectedScoreImpact: 0,
        expectedRiskLabel: 'Belirsiz',
        suggestion: 'Hisse, fon, altın veya döviz gibi ilk varlığınızı ekleyerek başlayabilirsiniz.',
      );
    }

    final dominant = _dominantAsset(items);
    final assetCount = items.map((e) => e.symbol.toUpperCase().trim()).toSet().length;
    final typeCount = items.map((e) => e.type.toLowerCase().trim()).toSet().length;

    if (dominant != null && dominant.weight >= .60) {
      final impact = _impactFor(score, 12);

      return AIAdvisorResult(
        headline: 'Yoğunlaşma riski öne çıkıyor',
        dailyComment:
            'Portföyünüzün %${(dominant.weight * 100).round()} oranı ${dominant.symbol} üzerinde yoğunlaşmış. Bu durum AI skorunu aşağı çekiyor.',
        priority: '${dominant.symbol} ağırlığını azaltın veya yeni varlık türü ekleyin.',
        expectedScoreImpact: impact,
        expectedRiskLabel: _riskAfterImprovement(score, impact),
        suggestion:
            'Yeni alımlarda aynı varlık yerine fon, altın veya farklı sektörlerden hisse eklemek risk dengesini iyileştirebilir.',
      );
    }

    if (assetCount < 3) {
      final impact = _impactFor(score, 10);

      return AIAdvisorResult(
        headline: 'Çeşitlendirme artırılabilir',
        dailyComment:
            'Portföyünüz sınırlı sayıda varlıktan oluşuyor. Daha fazla varlık eklemek dalgalanmayı azaltabilir.',
        priority: 'En az 3-5 farklı varlıkla dağılımı güçlendirin.',
        expectedScoreImpact: impact,
        expectedRiskLabel: _riskAfterImprovement(score, impact),
        suggestion:
            'Farklı sektörlerden hisse, fon veya altın eklemek portföyün dayanıklılığını artırabilir.',
      );
    }

    if (typeCount < 2) {
      final impact = _impactFor(score, 8);

      return AIAdvisorResult(
        headline: 'Varlık türü dengesi zayıf',
        dailyComment:
            'Portföyünüz tek varlık türüne bağlı görünüyor. Bu durum piyasa koşullarına karşı hassasiyeti artırabilir.',
        priority: 'Farklı varlık türleriyle denge kurun.',
        expectedScoreImpact: impact,
        expectedRiskLabel: _riskAfterImprovement(score, impact),
        suggestion:
            'Hisse dışında fon, altın veya döviz gibi tamamlayıcı varlıklar eklenebilir.',
      );
    }

    if (score.overallScore < 60) {
      final impact = _impactFor(score, 9);

      return AIAdvisorResult(
        headline: 'AI skoru iyileştirilebilir',
        dailyComment:
            'Portföyünüz orta-yüksek risk bölgesinde. Skoru yükseltmek için dağılım ve risk dengesi güçlendirilmeli.',
        priority: 'Pozisyon ağırlıklarını yeniden dengeleyin.',
        expectedScoreImpact: impact,
        expectedRiskLabel: _riskAfterImprovement(score, impact),
        suggestion:
            'En büyük pozisyonları azaltıp farklı varlıklara yaymak AI skorunu artırabilir.',
      );
    }

    return AIAdvisorResult(
      headline: 'Portföy dengeli görünüyor',
      dailyComment:
          'AI danışmanı portföyünüzü genel olarak dengeli buluyor. Mevcut yapı korunabilir.',
      priority: 'Mevcut dağılımı izlemeye devam edin.',
      expectedScoreImpact: 3,
      expectedRiskLabel: _riskAfterImprovement(score, 3),
      suggestion:
          'Yeni alımlarda mevcut dağılımı bozmadan küçük ve dengeli eklemeler yapılabilir.',
    );
  }

  _DominantAdvisorAsset? _dominantAsset(List<PortfolioItem> items) {
    final total = items.fold<double>(0, (sum, item) => sum + item.totalCost);
    if (total <= 0) return null;

    PortfolioItem? dominant;
    double dominantValue = 0;

    for (final item in items) {
      if (item.totalCost > dominantValue) {
        dominant = item;
        dominantValue = item.totalCost;
      }
    }

    if (dominant == null) return null;

    return _DominantAdvisorAsset(
      symbol: dominant.symbol.toUpperCase(),
      weight: dominantValue / total,
    );
  }

  int _impactFor(AIPortfolioScore score, int maxImpact) {
    if (score.overallScore >= 85) return 2;
    if (score.overallScore >= 70) return (maxImpact * .45).round();
    if (score.overallScore >= 50) return (maxImpact * .75).round();
    return maxImpact;
  }

  String _riskAfterImprovement(AIPortfolioScore score, int impact) {
    final projected = (score.overallScore + impact).clamp(0, 100);

    if (projected >= 80) return 'Düşük';
    if (projected >= 60) return 'Orta';
    return 'Yüksek';
  }
}

class _DominantAdvisorAsset {
  const _DominantAdvisorAsset({
    required this.symbol,
    required this.weight,
  });

  final String symbol;
  final double weight;
}