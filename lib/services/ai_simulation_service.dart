import '../models/portfolio_item.dart';
import 'ai_score_service.dart';

class AISimulationResult {
  const AISimulationResult({
    required this.title,
    required this.description,
    required this.currentScore,
    required this.projectedScore,
    required this.scoreImpact,
    required this.currentRisk,
    required this.projectedRisk,
  });

  final String title;
  final String description;
  final int currentScore;
  final int projectedScore;
  final int scoreImpact;
  final String currentRisk;
  final String projectedRisk;
}

class AISimulationService {
  const AISimulationService();

  AISimulationResult simulate(List<PortfolioItem> items) {
    final score = const AIScoreService().calculate(items);

    if (items.isEmpty) {
      return const AISimulationResult(
        title: 'Simülasyon için portföy bekleniyor',
        description: 'AI simülasyonu için önce portföyünüze varlık ekleyin.',
        currentScore: 0,
        projectedScore: 0,
        scoreImpact: 0,
        currentRisk: 'Belirsiz',
        projectedRisk: 'Belirsiz',
      );
    }

    final assetCount =
        items.map((item) => item.symbol.toUpperCase().trim()).toSet().length;

    final typeCount =
        items.map((item) => item.type.toLowerCase().trim()).toSet().length;

    final dominantWeight = _dominantWeight(items);

    int impact = 4;
    String title = 'Dengeyi koruma senaryosu';
    String description =
        'Mevcut dağılım korunursa AI skorunda sınırlı bir iyileşme beklenir.';

    if (dominantWeight >= .70) {
      impact = 14;
      title = 'Yoğunlaşmayı azaltma senaryosu';
      description =
          'En büyük pozisyonun ağırlığı azaltılıp yeni varlık eklenirse AI skoru belirgin şekilde iyileşebilir.';
    } else if (assetCount < 3) {
      impact = 11;
      title = 'Çeşitlendirme senaryosu';
      description =
          'Portföye 3-5 farklı varlık eklemek risk dengesini güçlendirebilir.';
    } else if (typeCount < 2) {
      impact = 9;
      title = 'Varlık türü dengeleme senaryosu';
      description =
          'Hisse dışında fon, altın veya döviz gibi tamamlayıcı varlıklar eklenirse portföy daha dengeli hale gelebilir.';
    } else if (score.overallScore < 60) {
      impact = 8;
      title = 'Risk azaltma senaryosu';
      description =
          'Pozisyon ağırlıkları yeniden dengelenirse AI skoru iyileşebilir.';
    }

    final projectedScore = (score.overallScore + impact).clamp(0, 100);

    return AISimulationResult(
      title: title,
      description: description,
      currentScore: score.overallScore,
      projectedScore: projectedScore,
      scoreImpact: projectedScore - score.overallScore,
      currentRisk: score.riskLabel,
      projectedRisk: _riskLabel(projectedScore),
    );
  }

  double _dominantWeight(List<PortfolioItem> items) {
    final total = items.fold<double>(0, (sum, item) => sum + item.totalCost);
    if (total <= 0) return 0;

    double biggest = 0;

    for (final item in items) {
      if (item.totalCost > biggest) {
        biggest = item.totalCost;
      }
    }

    return biggest / total;
  }

  String _riskLabel(int score) {
    if (score >= 80) return 'Düşük';
    if (score >= 60) return 'Orta';
    return 'Yüksek';
  }
}