import '../models/ai_portfolio_score.dart';
import '../models/portfolio_item.dart';
import 'ai/portfolio_score_service_v2.dart';

class AIScoreService {
  const AIScoreService();

  AIPortfolioScore calculate(List<PortfolioItem> items) {
    final result = const PortfolioScoreServiceV2().calculate(items);

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

    final risk = switch (result.riskScore) {
      <= 35 => RiskLevel.low,
      <= 65 => RiskLevel.medium,
      _ => RiskLevel.high,
    };

    final summary = _buildSummary(result.overallScore, result.confidence);

    return AIPortfolioScore(
      overallScore: result.overallScore,
      diversification: result.breakdown.diversification.round(),
      momentum: result.breakdown.riskAdjustedPerformance.round(),
      stability: result.breakdown.marketRisk.round(),
      risk: risk,
      summary: summary,
    );
  }

  String _buildSummary(int score, int confidence) {
    if (confidence < 45) {
      return 'Skor veri kapsamı sınırlı olduğu için ön değerlendirme niteliğindedir.';
    }
    if (score >= 80) {
      return 'Portföyünüz dengeli görünüyor. Mevcut dağılım korunabilir.';
    }

    if (score >= 60) {
      return 'Portföyünüz genel olarak dengeli. Çeşitlendirme artırılabilir.';
    }

    return 'Portföyünüz yüksek risk içeriyor. Daha dengeli dağılım önerilir.';
  }
}
