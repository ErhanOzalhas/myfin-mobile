import 'package:flutter/material.dart';
import 'package:myfin_mobile/models/portfolio_item.dart';

import 'package:myfin_mobile/screens/intelligence/ai_chat_page.dart';
import 'package:myfin_mobile/services/ai_analysis_service.dart';
import 'package:myfin_mobile/services/ai/portfolio_analysis_mapper.dart';
import 'package:myfin_mobile/services/ai/portfolio_analysis.dart';
import 'package:myfin_mobile/repositories/portfolio_repository.dart';
import '../../utils/no_animation_route.dart';
class AIScoreSection extends StatelessWidget {
  const AIScoreSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PortfolioItem>>(
      stream: PortfolioRepository.instance.watchPortfolio(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        final analysisResult =
            const AIAnalysisService().analyze(items);

        final PortfolioAnalysis portfolioAnalysis =
            mapToPortfolioAnalysis(analysisResult);

        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.of(context).push(
              noAnimationRoute(
                builder: (_) => AiChatPage(
                  analysis: portfolioAnalysis,
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6D5DF6),
                        Color(0xFF00A3FF),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MyFin Intelligence',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        analysisResult.resultSummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Score ${portfolioAnalysis.aiScore} • View insights',
                        style: const TextStyle(
                          color: Color(0xFF1D9BF0),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        );
      },
    );
  }
}