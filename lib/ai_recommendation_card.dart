import 'package:flutter/material.dart';
import 'package:myfin_mobile/services/recommendation_engine.dart';

class AIRecommendationCard extends StatelessWidget {
  final List<RecommendationItem> recommendations;

  const AIRecommendationCard({
    super.key,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Portfolio Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          ...recommendations.map(_RecommendationRow.new),
        ],
      ),
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  final RecommendationItem item;

  const _RecommendationRow(this.item);

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.level) {
      RecommendationLevel.good => Icons.check_circle_rounded,
      RecommendationLevel.info => Icons.info_rounded,
      RecommendationLevel.warning => Icons.warning_amber_rounded,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
