import 'package:flutter/material.dart';
import '../../services/ai/ai_history_service.dart';
import '../../models/portfolio_item.dart';
import '../../repositories/portfolio_repository.dart';
import '../../services/ai/portfolio_analyzer.dart';
import '../../widgets/intelligence/intelligence_recommendation_card.dart';
import '../../widgets/intelligence/intelligence_score_card.dart';
import '../../widgets/intelligence_market_mood_card.dart';
import '../../services/ai/recommendation_engine_v2.dart';
import '../../services/ai/ai_trend_service.dart';
import '../../services/ai/timeline_engine.dart';
import '../../widgets/intelligence/intelligence_timeline_card.dart';
import '../../services/ai/ai_advisor_service.dart';
import '../../widgets/intelligence/intelligence_ai_decision_card.dart';
import 'package:myfin_mobile/screens/intelligence/ai_chat_page.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';
class IntelligencePage extends StatelessWidget {
  const IntelligencePage({super.key});

  String _statusForScore(int score) {
    if (score >= 80) return 'Güçlü';
    if (score >= 60) return 'Dengeli';
    if (score > 0) return 'Dikkat Gerekli';
    return 'Veri Yok';
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  appBar: AppBar(
    title: const Text('MyFin Intelligence'),
  ),

  body: StreamBuilder<List<PortfolioItem>>(
    stream: PortfolioRepository.instance.watchPortfolio(),
    builder: (context, snapshot) {
      final items = snapshot.data ?? [];
      final analysis = PortfolioAnalyzer.analyze(items);

      final historyService = AIHistoryService();

      if (items.isNotEmpty) {
        historyService.saveIfChanged(analysis);
      }

      final history = historyService.history;

      debugPrint('History length: ${history.length}');
      for (final h in history) {
        debugPrint('AI Score: ${h.aiScore}');
      }

      final latest = historyService.latest;
      final previous = historyService.previous;

      final trend = const AITrendService().build(history);

      final timelineEvents = const TimelineEngine().build(
        analysis: analysis,
        trend: trend,
        history: history,
      );

      final recommendationInsights =
          const RecommendationEngineV2().generate(analysis);

      final recommendations =
          recommendationInsights.map((e) => e.action).toList();

      final advisorRecommendations =
          const AIAdvisorService().generate(analysis);

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntelligenceScoreCard(
              score: analysis.aiScore,
              status: _statusForScore(analysis.aiScore),
            ),

            const SizedBox(height: 16),

            IntelligenceMarketMoodCard(
              mood: analysis.risk <= 35
                  ? 'Olumlu'
                  : analysis.risk <= 65
                      ? 'Nötr'
                      : 'Temkinli',
            ),

            const SizedBox(height: 16),

            IntelligenceRecommendationCard(
              recommendations: [
                ...advisorRecommendations,
                ...recommendations,
              ],
            ),

            const SizedBox(height: 16),

            IntelligenceAIDecisionCard(
              strengths: analysis.strengths,
              warnings: analysis.warnings,
              riskLevel: analysis.riskLevel,
              investmentStyle: analysis.investmentStyle,
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AiChatPage(
                        analysis: analysis,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_rounded),
                label: const Text('MyFin ile Konuş'),
              ),
            ),

            const SizedBox(height: 16),

            IntelligenceTimelineCard(
              events: timelineEvents,
            ),
          ],
        ),
      );
    },
  ),

  bottomNavigationBar: const MyFinBottomNav(
    selectedIndex: 3,
  ),
);  
}

}