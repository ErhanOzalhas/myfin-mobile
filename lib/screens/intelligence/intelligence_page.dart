import 'package:flutter/material.dart';

import '../../models/portfolio_item.dart';
import '../../repositories/portfolio_repository.dart';
import '../../services/ai/portfolio_analyzer.dart';
import '../../widgets/intelligence/intelligence_recommendation_card.dart';
import '../../widgets/intelligence/intelligence_score_card.dart';
import '../../widgets/intelligence_market_mood_card.dart';

class IntelligencePage extends StatelessWidget {
  const IntelligencePage({super.key});

  String _statusForScore(int score) {
    if (score >= 80) return 'Strong';
    if (score >= 60) return 'Balanced';
    if (score > 0) return 'Needs Attention';
    return 'No Data';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Intelligence'),
      ),
      body: StreamBuilder<List<PortfolioItem>>(
        stream: PortfolioRepository.instance.watchPortfolio(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final analysis = PortfolioAnalyzer.analyze(items);

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
                const IntelligenceMarketMoodCard(),
                const SizedBox(height: 16),
                const IntelligenceRecommendationCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}