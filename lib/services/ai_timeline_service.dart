import '../models/ai/ai_timeline_point.dart';
import '../models/portfolio_item.dart';
import 'ai_score_service.dart';

class AITimelineService {
  const AITimelineService();

  List<AITimelinePoint> build(List<PortfolioItem> items) {
    final score = const AIScoreService().calculate(items);

    if (items.isEmpty) {
      return const [
        AITimelinePoint(
          label: 'Bugün',
          score: 0,
          riskLabel: 'Belirsiz',
          note: 'Portföy verisi bekleniyor.',
        ),
      ];
    }

    final current = score.overallScore;

    final previous7 = (current - _estimatedImprovement(items, 7)).clamp(0, 100);
    final previous30 =
        (current - _estimatedImprovement(items, 30)).clamp(0, 100);

    return [
      AITimelinePoint(
        label: '1 Ay Önce',
        score: previous30,
        riskLabel: _riskLabel(previous30),
        note: _noteFor(previous30),
      ),
      AITimelinePoint(
        label: '1 Hafta Önce',
        score: previous7,
        riskLabel: _riskLabel(previous7),
        note: _noteFor(previous7),
      ),
      AITimelinePoint(
        label: 'Bugün',
        score: current,
        riskLabel: score.riskLabel,
        note: _noteFor(current),
      ),
    ];
  }

  int _estimatedImprovement(List<PortfolioItem> items, int days) {
    final assetCount =
        items.map((item) => item.symbol.toUpperCase().trim()).toSet().length;

    final typeCount =
        items.map((item) => item.type.toLowerCase().trim()).toSet().length;

    int improvement = 0;

    if (assetCount >= 2) improvement += 4;
    if (assetCount >= 4) improvement += 6;
    if (typeCount >= 2) improvement += 5;

    if (days >= 30) {
      return (improvement * 1.6).round().clamp(4, 22);
    }

    return improvement.clamp(2, 14);
  }

  String _riskLabel(int score) {
    if (score >= 80) return 'Düşük';
    if (score >= 60) return 'Orta';
    return 'Yüksek';
  }

  String _noteFor(int score) {
    if (score >= 80) return 'Portföy dengesi güçlü.';
    if (score >= 60) return 'Denge gelişiyor.';
    if (score >= 40) return 'Riskler izlenmeli.';
    return 'Çeşitlendirme öncelikli.';
  }
}