import '../../models/portfolio_analysis.dart';

class AIAdvisorService {
  const AIAdvisorService();

  List<String> generate(PortfolioAnalysis analysis) {
    final advice = <String>[];

    if (analysis.diversification < 60) {
      advice.add(
        'Portföyünüz yeterince çeşitlendirilmemiş. Farklı sektörlerden varlık eklemeyi değerlendirin.',
      );
    }

    if (analysis.risk > 70) {
      advice.add(
        'Risk seviyeniz yüksek. Daha dengeli varlık dağılımı AI Score’unuzu artırabilir.',
      );
    }

    if (analysis.growth < 50) {
      advice.add(
        'Büyüme potansiyeli düşük görünüyor. Uzun vadeli büyüme odaklı varlıklar incelenebilir.',
      );
    }

    if (advice.isEmpty) {
      advice.add(
        'Portföyünüz dengeli görünüyor. Mevcut stratejinizi koruyabilirsiniz.',
      );
    }

    return advice;
  }
}