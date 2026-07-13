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
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    
                    gradient: const LinearGradient(

  begin: Alignment.topLeft,

  end: Alignment.bottomRight,

  colors: [

    Color(0xFF0F172A),

    Color(0xFF008DB9),

  ],

),
                   boxShadow: [
  BoxShadow(
    color: const Color(0xFF008DB9).withOpacity(.24),
    blurRadius: 90,
    offset: const Offset(0, 14),
  ),
], 
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        Positioned(
                          right: -40,
                          top: -35,
                          child: IgnorePointer(
                            child: Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF6FD8FF)
                                    .withValues(alpha: 0.10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6FD8FF)
                                        .withValues(alpha: 0.18),
                                    blurRadius: 90,
                                    spreadRadius: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () {
                            Navigator.push(
                              context,
                              noAnimationRoute(
                                builder: (_) => AiChatPage(
                                  analysis: analysis,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                const _PulsingAiGlowIcon(),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'MyFin AI’ye Sor',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Portföyünü birlikte değerlendirelim',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
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
                IntelligenceMarketMoodCard(
                  mood: _moodForRisk(analysis.risk),
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

/// "MyFin AI'ye Sor" butonundaki yıldız ikonunun etrafında yumuşak,
/// nabız gibi atan (pulsing) sarı bir AI ışıltısı oluşturan widget.
class _PulsingAiGlowIcon extends StatefulWidget {
  const _PulsingAiGlowIcon();

  @override
  State<_PulsingAiGlowIcon> createState() => _PulsingAiGlowIconState();
}

class _PulsingAiGlowIconState extends State<_PulsingAiGlowIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double glowStrength = 0.30 + (_controller.value * 0.35);
        final double scale = 1.0 + (_controller.value * 0.10);

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF5A623).withOpacity(glowStrength),
                blurRadius: 22,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Color(0xFFF5A623),
        size: 24,
      ),
    );
  }
}

