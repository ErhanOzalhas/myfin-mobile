// lib/services/portfolio_analyzer.dart

import '../models/portfolio_analysis.dart';

/// PortfolioItem sınıfı mevcut projedeki modele göre çalışır.
/// Beklenen alanlar:
///   - type
///   - totalValue
///   - totalCost
class PortfolioAnalyzer {
  const PortfolioAnalyzer._();

  static PortfolioAnalysis analyze(List<dynamic> items) {
    if (items.isEmpty) {
      return PortfolioAnalysis.empty();
    }

    double totalValue = 0;
    double totalCost = 0;

    final Map<String, double> allocation = {};

    for (final item in items) {
      final value = (item.totalValue as num).toDouble();
      final cost = (item.totalCost as num).toDouble();

      totalValue += value;
      totalCost += cost;

      final type = (item.type ?? 'Other').toString();

      allocation[type] = (allocation[type] ?? 0) + value;
    }

    final totalProfit = totalValue - totalCost;

    final profitPercent =
        totalCost == 0 ? 0.0 : (totalProfit / totalCost) * 100.0;

    final normalizedAllocation = <String, double>{};

    allocation.forEach((key, value) {
      normalizedAllocation[key] =
          totalValue == 0 ? 0 : (value / totalValue) * 100;
    });

    final diversification =
        _calculateDiversification(normalizedAllocation);

    final risk =
        _calculateRisk(normalizedAllocation);

    final health =
        _calculateHealth(
      diversification,
      risk,
      profitPercent,
    );

    return PortfolioAnalysis(
      totalValue: totalValue,
      totalCost: totalCost,
      totalProfit: totalProfit,
      profitPercent: profitPercent,
      healthScore: health,
      diversificationScore: diversification,
      riskScore: risk,
      allocation: normalizedAllocation,
    );
  }

  static double _calculateDiversification(
      Map<String, double> allocation) {
    if (allocation.isEmpty) return 0;

    double score = allocation.length * 18;

    final largest = allocation.values.reduce(
      (a, b) => a > b ? a : b,
    );

    if (largest > 60) {
      score -= 25;
    } else if (largest > 45) {
      score -= 12;
    }

    return score.clamp(0.0, 100.0);
  }

  static double _calculateRisk(
      Map<String, double> allocation) {
    if (allocation.isEmpty) return 0;

    double risk = 25;

    allocation.forEach((type, percent) {
      final t = type.toLowerCase();

      if (t.contains('crypto')) {
        risk += percent * 0.45;
      } else if (t.contains('stock') ||
          t.contains('hisse')) {
        risk += percent * 0.20;
      } else if (t.contains('gold') ||
          t.contains('altın')) {
        risk += percent * 0.08;
      } else if (t.contains('cash') ||
          t.contains('nakit')) {
        risk -= percent * 0.05;
      }
    });

    return risk.clamp(0.0, 100.0);
  }

  static double _calculateHealth(
    double diversification,
    double risk,
    double profit,
  ) {
    double score = 50;

    score += diversification * 0.30;
    score += (100 - risk) * 0.25;

    if (profit > 0) {
      score += (profit.clamp(0.0, 20.0)) * 1.2;
    } else {
      score -= ((-profit).clamp(0.0, 20.0));
    }

    return score.clamp(0.0, 100.0);
  }
}