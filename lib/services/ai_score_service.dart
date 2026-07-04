import '../models/ai_portfolio_score.dart';
import '../models/portfolio_item.dart';
import 'ai_score_engine.dart';

class AIScoreService {
  const AIScoreService();

  AIPortfolioScore calculate(List<PortfolioItem> items) {
    final breakdown = const AIScoreEngine().calculate(items);

    if (items.isEmpty) {
      return const AIPortfolioScore(
        overallScore: 0,
        diversification: 0,
        momentum: 0,
        stability: 0,
        risk: RiskLevel.high,
        summary: 'Portföy bulunamadı. AI analizi için önce varlık ekleyin.',
      );
    }

    final risk = switch (breakdown.overallScore) {
      >= 80 => RiskLevel.low,
      >= 60 => RiskLevel.medium,
      _ => RiskLevel.high,
    };

    final summary = _buildSummary(breakdown.overallScore);

    return AIPortfolioScore(
      overallScore: breakdown.overallScore,
      diversification: breakdown.diversification,
      momentum: breakdown.growth,
      stability: breakdown.stability,
      risk: risk,
      summary: summary,
    );
  }

  String _buildSummary(int score) {
    if (score >= 80) {
      return 'Portföyünüz dengeli görünüyor. Mevcut dağılım korunabilir.';
    }

    if (score >= 60) {
      return 'Portföyünüz genel olarak dengeli. Çeşitlendirme artırılabilir.';
    }

    return 'Portföyünüz yüksek risk içeriyor. Daha dengeli dağılım önerilir.';
  }
}