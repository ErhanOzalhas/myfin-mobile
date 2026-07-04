import '../models/portfolio_item.dart';
import 'portfolio_metrics_service.dart';

enum RecommendationLevel {
  good,
  info,
  warning,
}

class RecommendationItem {
  final RecommendationLevel level;
  final String title;
  final String message;

  const RecommendationItem({
    required this.level,
    required this.title,
    required this.message,
  });
}

class RecommendationEngine {
  const RecommendationEngine();

  List<RecommendationItem> analyze({
    required int diversificationScore,
    required int overallScore,
    required List<PortfolioItem> items,
  }) {
    const metrics = PortfolioMetricsService();

    final allocations = metrics.allocationBySymbol(items);
    final largestWeight = allocations.values.isEmpty
        ? 0.0
        : allocations.values.reduce((a, b) => a > b ? a : b);

    final recommendations = <RecommendationItem>[];

    if (largestWeight > 0.60) {
      recommendations.add(
        const RecommendationItem(
          level: RecommendationLevel.warning,
          title: "High Concentration",
          message: "One holding represents more than 60% of your portfolio.",
        ),
      );
    }

    if (overallScore >= 80) {
      recommendations.add(
        const RecommendationItem(
          level: RecommendationLevel.good,
          title: "Strong Portfolio",
          message: "Your portfolio looks healthy overall.",
        ),
      );
    }

    if (diversificationScore < 50) {
      recommendations.add(
        const RecommendationItem(
          level: RecommendationLevel.warning,
          title: "Low Diversification",
          message: "Consider spreading investments across more assets.",
        ),
      );
    }

    if (items.length <= 2) {
      recommendations.add(
        const RecommendationItem(
          level: RecommendationLevel.info,
          title: "Few Holdings",
          message: "Adding more positions may reduce concentration risk.",
        ),
      );
    }

    return recommendations;
  }
}