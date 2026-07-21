import 'package:flutter/material.dart';
import 'package:myfin_mobile/widgets/navigation/myfin_back_button.dart';

import '../../models/portfolio_item.dart';
import '../../repositories/portfolio_repository.dart';
import '../../services/ai/ai_advisor_service.dart';
import '../../services/ai/ai_history_service.dart';
import '../../services/ai/ai_trend_service.dart';
import '../../services/ai/portfolio_analyzer.dart';
import '../../services/ai/portfolio_score_service_v2.dart';
import '../../services/portfolio_valuation_service.dart';
import '../../models/market_mood.dart';
import '../../models/cash_movement.dart';
import '../../repositories/cash_repository.dart';
import '../../services/intelligence/market_mood_service.dart';
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

  const IntelligencePage({super.key, this.showBottomNav = true});

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
        leading: const MyFinBackButton(),
        title: const Text('MyFin Intelligence'),
      ),
      body: StreamBuilder<CashBalanceSnapshot>(
        stream: CashRepository.instance.watchBalance(),
        initialData: CashBalanceSnapshot.empty,
        builder: (context, cashSnapshot) {
          final cashBalance = cashSnapshot.data?.balance ?? 0;
          return StreamBuilder<List<PortfolioItem>>(
            stream: PortfolioRepository.instance.watchPortfolio(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? <PortfolioItem>[];
              return FutureBuilder<PortfolioValuation>(
                initialData: PortfolioValuationService.instance.peek(items),
                future: PortfolioValuationService.instance.calculate(items),
                builder: (context, valuationSnapshot) {
                  final valuation = valuationSnapshot.data;
                  final scoreResult = valuation == null
                      ? null
                      : const PortfolioScoreServiceV2().calculateFromValuation(
                          valuation,
                          cashBalance: cashBalance,
                        );
                  final analysis = PortfolioAnalyzer.analyze(
                    items,
                    scoreResult: scoreResult,
                  );

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

                  final recommendationInsights = const RecommendationEngineV2()
                      .generate(analysis);
                  final recommendations = recommendationInsights
                      .map((item) => item.action)
                      .toList();
                  final advisorRecommendations = const AIAdvisorService()
                      .generate(analysis);

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

                              colors: [Color(0xFF0F172A), Color(0xFF008DB9)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF008DB9,
                                ).withValues(alpha: .24),
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
                                        color: const Color(
                                          0xFF6FD8FF,
                                        ).withValues(alpha: 0.10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF6FD8FF,
                                            ).withValues(alpha: 0.18),
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
                                          portfolioItems: items,
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
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                'Portföyünü birlikte değerlendirelim',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
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
                        _DistributionBalanceCard(
                          onQuestion: (question) {
                            Navigator.push(
                              context,
                              noAnimationRoute(
                                builder: (_) => AiChatPage(
                                  analysis: analysis,
                                  portfolioItems: items,
                                  initialQuestion: question,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        IntelligenceRecommendationCard(
                          recommendations: [
                            ...advisorRecommendations,
                            ...recommendations,
                          ],
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<MarketMoodResult>(
                          initialData: MarketMoodService.instance.latest,
                          future: MarketMoodService.instance.getMood(),
                          builder: (context, moodSnapshot) {
                            return IntelligenceMarketMoodCard(
                              result: moodSnapshot.data,
                              isLoading:
                                  moodSnapshot.connectionState ==
                                  ConnectionState.waiting,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        IntelligenceAIDecisionCard(
                          strengths: analysis.strengths,
                          warnings: analysis.warnings,
                          riskLevel: analysis.riskLevel,
                          investmentStyle: analysis.investmentStyle,
                        ),
                        const SizedBox(height: 16),
                        IntelligenceTimelineCard(events: timelineEvents),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: showBottomNav
          ? const MyFinBottomNav(selectedIndex: 3)
          : null,
    );
  }
}

class _DistributionBalanceCard extends StatelessWidget {
  const _DistributionBalanceCard({required this.onQuestion});

  final ValueChanged<String> onQuestion;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C3AED);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F3FF), Color(0xFFEFF6FF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDD6FE)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: .22),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology_alt_outlined,
                  size: 34,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dağılım Dengesi',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Portföyünü dengelemek için MyFin AI’ye sor',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BalanceQuestion(
            label: 'Yoğunluğu nasıl azaltabilirim?',
            onTap: () => onQuestion(
              'Portföyümdeki yoğunlaşmayı analiz et. Yoğunluğu azaltmak için mevcut dağılımıma uygun, uygulanabilir adımları sırala.',
            ),
          ),
          const SizedBox(height: 8),
          _BalanceQuestion(
            label: 'Daha dengeli dağılım nasıl olur?',
            onTap: () => onQuestion(
              'Portföyüm için daha dengeli bir varlık dağılımı nasıl olabilir? Mevcut ağırlıkları dikkate alarak hangi alanların artırılıp azaltılabileceğini açıkla.',
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceQuestion extends StatelessWidget {
  const _BalanceQuestion({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .78),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              const Icon(
                Icons.help_outline_rounded,
                size: 17,
                color: Color(0xFF7C3AED),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 17,
                color: Color(0xFF7C3AED),
              ),
            ],
          ),
        ),
      ),
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
                color: const Color(0xFFF5A623).withValues(alpha: glowStrength),
                blurRadius: 22,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Transform.scale(scale: scale, child: child),
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
