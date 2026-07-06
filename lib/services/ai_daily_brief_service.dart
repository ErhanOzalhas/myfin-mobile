import '../models/ai/ai_daily_brief.dart';
import '../models/portfolio_item.dart';
import 'ai_analysis_service.dart';
import 'ai_advisor_service.dart';

class AIDailyBriefService {
  const AIDailyBriefService();

  AIDailyBrief build(List<PortfolioItem> items) {
    final analysis = const AIAnalysisService().analyze(items);
    final advisor = const AIAdvisorService().advise(items);
    final score = analysis.score;

    if (items.isEmpty) {
      return AIDailyBrief(
        title: 'Günlük AI Özeti',
        summary: 'Portföy verisi bekleniyor. İlk varlığınızı eklediğinizde AI günlük özet oluşturmaya başlayacak.',
        priority: 'İlk varlığınızı ekleyin.',
        score: 0,
        scoreChange: 0,
        confidence: 0,
        generatedAt: DateTime.now(),
      );
    }

    final scoreChange = _estimatedScoreChange(score.overallScore);

    return AIDailyBrief(
      title: 'Günlük AI Özeti',
      summary: _summaryFor(
        score: score.overallScore,
        resultSummary: analysis.resultSummary,
      ),
      priority: advisor.priority,
      score: score.overallScore,
      scoreChange: scoreChange,
      confidence: analysis.confidence,
      generatedAt: DateTime.now(),
    );
  }

  int _estimatedScoreChange(int score) {
    if (score >= 80) return 2;
    if (score >= 60) return 1;
    if (score >= 40) return 0;
    return -1;
  }

  String _summaryFor({
    required int score,
    required String resultSummary,
  }) {
    if (score >= 80) {
      return 'Portföyünüz bugün güçlü bölgede. $resultSummary';
    }

    if (score >= 60) {
      return 'Portföyünüz genel olarak dengeli. $resultSummary';
    }

    return 'Portföyünüz bugün dikkat gerektiriyor. $resultSummary';
  }
}