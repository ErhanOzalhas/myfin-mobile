import '../models/portfolio_item.dart';
import 'ai_score_service.dart';
import 'ai/portfolio_analyzer.dart';

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
    final analysis = PortfolioAnalyzer.analyze(items);

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

    int impact = 4;
    String title = 'Dengeyi koruma senaryosu';
    String description =
        'Mevcut dağılım korunursa AI skorunda sınırlı bir iyileşme beklenir.';

    if (analysis.focus.contains('ağırlığı') && analysis.risk > 65) {
      impact = 14;
      title = 'Yoğunlaşmayı azaltma senaryosu';
      description =
          'En büyük pozisyonun ağırlığı azaltılıp yeni varlık eklenirse AI skoru belirgin şekilde iyileşebilir.';
    } else if (analysis.diversification < 45) {
      impact = 11;
      title = 'Çeşitlendirme senaryosu';
      description =
          'Portföye 3-5 farklı varlık eklemek risk dengesini güçlendirebilir.';
    } else if (analysis.focus == 'Tek varlık sınıfı') {
      impact = 9;
      title = 'Varlık türü dengeleme senaryosu';
      description =
          'Hisse dışında fon, altın veya döviz gibi tamamlayıcı varlıklar eklenirse portföy daha dengeli hale gelebilir.';
    } else if (analysis.aiScore < 60) {
      impact = 8;
      title = 'Risk azaltma senaryosu';
      description =
          'Pozisyon ağırlıkları yeniden dengelenirse AI skoru iyileşebilir.';
    }

    final projectedScore = (analysis.aiScore + impact).clamp(0, 100);

    return AISimulationResult(
      title: title,
      description: description,
      currentScore: analysis.aiScore,
      projectedScore: projectedScore,
      scoreImpact: projectedScore - analysis.aiScore,
      currentRisk: analysis.riskLevel,
      projectedRisk: _riskLabelForScore(projectedScore),
    );
  }

  String _riskLabelForScore(int score) {
    if (score >= 80) return 'Düşük';
    if (score >= 60) return 'Orta';
    return 'Yüksek';
  }
}