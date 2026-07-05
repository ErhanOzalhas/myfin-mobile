import 'portfolio_analysis.dart';

class AIAdvisorService {
  const AIAdvisorService();

  List<String> generate(PortfolioAnalysis analysis) {
  final advice = <String>[];

  if (analysis.diversification < 60) {
    advice.add(
      'Çeşitlendirme puanınız ${analysis.diversification}. '
      'Tek bir sektör veya varlık grubuna fazla ağırlık vermiş olabilirsiniz.',
    );
  } else {
    advice.add(
      'Çeşitlendirme puanınız ${analysis.diversification}. '
      'Portföyünüz genel olarak dengeli görünüyor.',
    );
  }

  if (analysis.risk > 70) {
    advice.add(
      'Risk puanınız ${analysis.risk}. '
      'Volatilitesi yüksek varlıkların oranını azaltmayı değerlendirebilirsiniz.',
    );
  }

  if (analysis.growth < 50) {
    advice.add(
      'Büyüme puanınız ${analysis.growth}. '
      'Uzun vadeli büyüme potansiyeli taşıyan varlıklar incelenebilir.',
    );
  }

  if (analysis.stability < 60) {
    advice.add(
      'İstikrar puanınız ${analysis.stability}. '
      'Daha istikrarlı varlıklarla portföy dengelenebilir.',
    );
  }

  if (analysis.aiScore >= 85) {
    advice.add(
      'AI değerlendirmesine göre portföyünüz güçlü durumda. Mevcut stratejinizi koruyabilirsiniz.',
    );
  }

  return advice;
}
}