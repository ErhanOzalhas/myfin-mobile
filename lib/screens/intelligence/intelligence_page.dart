import 'package:flutter/material.dart';

import '../../models/portfolio_item.dart';
import '../../repositories/portfolio_repository.dart';
import '../../services/ai/ai_advisor_service.dart';
import '../../services/ai/ai_history_service.dart';
import '../../services/ai/ai_trend_service.dart';
import '../../services/ai/portfolio_analyzer.dart';
import '../../services/ai/recommendation_engine_v2.dart';
import '../../services/ai/timeline_engine.dart';
import '../../widgets/intelligence/intelligence_ai_decision_card.dart';
import '../../widgets/intelligence/intelligence_recommendation_card.dart';
import '../../widgets/intelligence/intelligence_score_card.dart';
import '../../widgets/intelligence/intelligence_timeline_card.dart';
import '../../widgets/intelligence_market_mood_card.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';
import 'ai_chat_page.dart';
import '../../utils/no_animation_route.dart';

class IntelligencePage extends StatelessWidget {
  final bool showBottomNav;

  const IntelligencePage({
    super.key,
    this.showBottomNav = true,
  });

  String _statusForScore(int score) {
    if (score >= 80) return 'Güçlü';
    if (score >= 60) return 'Dengeli';
    if (score > 0) return 'Dikkat Gerekli';
    return 'Veri Yok';
  }

  String _moodForRisk(int risk) {
    if (risk <= 35) return 'Olumlu';
    if (risk <= 65) return 'Nötr';
    return 'Temkinli';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyFin Intelligence'),
        centerTitle: false,
      ),
      body: StreamBuilder<List<PortfolioItem>>(
        stream: PortfolioRepository.instance.watchPortfolio(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? <PortfolioItem>[];
          final analysis = PortfolioAnalyzer.analyze(items);

          final historyService = AIHistoryService();
          if (items.isNotEmpty) {
            historyService.saveIfChanged(analysis);
          }

          final history = historyService.history;
          final trend = const AITrendService().build(history);
          final timelineEvents = const TimelineEngine().build(
            analysis: analysis,
            trend: trend,
            history: history,
          );

          final recommendationInsights =
              const RecommendationEngineV2().generate(analysis);
          final recommendations =
              recommendationInsights.map((item) => item.action).toList();
          final advisorRecommendations =
              const AIAdvisorService().generate(analysis);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IntelligenceScoreCard(
                  score: analysis.aiScore,
                  status: _statusForScore(analysis.aiScore),
                ),
                const SizedBox(height: 16),
                IntelligenceMarketMoodCard(
                  mood: _moodForRisk(analysis.risk),
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
                        noAnimationRoute(
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
                IntelligenceTimelineCard(events: timelineEvents),
              ],
            ),
          );
        },
      ),
     bottomNavigationBar: showBottomNav
    ? const MyFinBottomNav(selectedIndex: 3)
    : null,
    );
  }
}
