import '../models/ai_score_breakdown.dart';
import '../models/portfolio_item.dart';

class AIScoreEngine {
  const AIScoreEngine();

  AIScoreBreakdown calculate(List<PortfolioItem> items) {
    if (items.isEmpty) {
      return const AIScoreBreakdown(
        diversification: 0,
        risk: 0,
        profitability: 0,
        allocation: 0,
        cashRatio: 0,
        stability: 0,
        growth: 0,
      );
    }

    final diversification = _calculateDiversification(items);
    final allocation = _calculateAllocation(items);
    final profitability = _calculateProfitability(items);
    final risk = _calculateRisk(items);
    final stability = _calculateStability(items);
    final growth = _calculateGrowth(items);
    final cashRatio = _calculateCashRatio(items);

    return AIScoreBreakdown(
      diversification: diversification,
      risk: risk,
      profitability: profitability,
      allocation: allocation,
      cashRatio: cashRatio,
      stability: stability,
      growth: growth,
    );
  }

  int _calculateDiversification(List<PortfolioItem> items) {
    final uniqueAssets = items.map((e) => e.symbol.toUpperCase()).toSet().length;

    if (uniqueAssets >= 10) return 100;
    if (uniqueAssets >= 8) return 90;
    if (uniqueAssets >= 6) return 80;
    if (uniqueAssets >= 5) return 70;
    if (uniqueAssets >= 4) return 60;
    if (uniqueAssets >= 3) return 45;
    if (uniqueAssets >= 2) return 30;

    return 15;
  }

  int _calculateRisk(List<PortfolioItem> items) {
    final total = items.fold<double>(
      0,
      (sum, item) => sum + item.totalCost,
    );

    if (total <= 0) return 0;

    double biggestWeight = 0;

    for (final item in items) {
      final weight = item.totalCost / total;

      if (weight > biggestWeight) {
        biggestWeight = weight;
      }
    }

    final concentration = biggestWeight * 100;

    if (concentration <= 20) return 100;
    if (concentration <= 30) return 85;
    if (concentration <= 40) return 70;
    if (concentration <= 50) return 55;
    if (concentration <= 60) return 40;
    if (concentration <= 70) return 25;

    return 10;
  }

  int _calculateProfitability(List<PortfolioItem> items) {
    double totalCost = 0;
    double totalCurrent = 0;

    for (final item in items) {
      totalCost += item.averagePrice * item.quantity;
      totalCurrent += item.totalCost;
    }

    if (totalCost <= 0) return 50;

    final profitPercent = ((totalCurrent - totalCost) / totalCost) * 100;

    if (profitPercent >= 30) return 100;
    if (profitPercent >= 20) return 90;
    if (profitPercent >= 10) return 80;
    if (profitPercent >= 5) return 70;
    if (profitPercent >= 0) return 60;
    if (profitPercent >= -10) return 45;
    if (profitPercent >= -20) return 30;

    return 15;
  }

  int _calculateAllocation(List<PortfolioItem> items) {
    final total = _totalCost(items);
    if (total <= 0) return 0;

    final byType = <String, double>{};

    for (final item in items) {
      final key = item.type.toLowerCase().trim();
      byType[key] = (byType[key] ?? 0) + item.totalCost;
    }

    final typeCount = byType.length;
    final biggestRatio = byType.values.reduce((a, b) => a > b ? a : b) / total;

    int score = 40;

    if (typeCount >= 5) {
      score += 35;
    } else if (typeCount >= 4) {
      score += 28;
    } else if (typeCount >= 3) {
      score += 20;
    } else if (typeCount >= 2) {
      score += 10;
    }

    if (biggestRatio <= .30) {
      score += 25;
    } else if (biggestRatio <= .40) {
      score += 18;
    } else if (biggestRatio <= .50) {
      score += 10;
    } else if (biggestRatio <= .65) {
      score += 2;
    } else {
      score -= 15;
    }

    return score.clamp(0, 100);
  }

  int _calculateStability(List<PortfolioItem> items) {
    final total = _totalCost(items);
    if (total <= 0) return 0;

    double weightedScore = 0;

    for (final item in items) {
      final weight = item.totalCost / total;
      weightedScore += _stabilityScoreForType(item.type) * weight;
    }

    final diversificationBonus = (_calculateDiversification(items) * .12).round();
    final score = weightedScore.round() + diversificationBonus;

    return score.clamp(0, 100);
  }

  int _calculateGrowth(List<PortfolioItem> items) {
    final total = _totalCost(items);
    if (total <= 0) return 0;

    double weightedScore = 0;

    for (final item in items) {
      final weight = item.totalCost / total;
      weightedScore += _growthScoreForType(item.type) * weight;
    }

    final score = weightedScore.round();
    return score.clamp(0, 100);
  }

  int _calculateCashRatio(List<PortfolioItem> items) {
    final total = _totalCost(items);
    if (total <= 0) return 0;

    final cashValue = items.fold<double>(0, (sum, item) {
      final type = item.type.toLowerCase().trim();
      final symbol = item.symbol.toUpperCase().trim();

      final isCash = type.contains('nakit') ||
          type.contains('cash') ||
          type.contains('döviz') ||
          type.contains('doviz') ||
          symbol == 'TRY' ||
          symbol == 'USD' ||
          symbol == 'EUR';

      return isCash ? sum + item.totalCost : sum;
    });

    final ratio = cashValue / total;

    if (ratio >= .08 && ratio <= .20) return 100;
    if (ratio >= .05 && ratio < .08) return 80;
    if (ratio > .20 && ratio <= .30) return 75;
    if (ratio >= .02 && ratio < .05) return 55;
    if (ratio > .30 && ratio <= .45) return 45;
    if (ratio < .02) return 25;

    return 30;
  }

  double _totalCost(List<PortfolioItem> items) {
    return items.fold<double>(0, (sum, item) => sum + item.totalCost);
  }

  int _stabilityScoreForType(String type) {
    final normalized = type.toLowerCase().trim();

    if (normalized.contains('nakit') ||
        normalized.contains('cash') ||
        normalized.contains('döviz') ||
        normalized.contains('doviz')) {
      return 92;
    }

    if (normalized.contains('fon') || normalized.contains('etf')) {
      return 82;
    }

    if (normalized.contains('altın') ||
        normalized.contains('altin') ||
        normalized.contains('gold')) {
      return 78;
    }

    if (normalized.contains('hisse') || normalized.contains('stock')) {
      return 62;
    }

    if (normalized.contains('kripto') || normalized.contains('crypto')) {
      return 35;
    }

    return 58;
  }

  int _growthScoreForType(String type) {
    final normalized = type.toLowerCase().trim();

    if (normalized.contains('kripto') || normalized.contains('crypto')) {
      return 88;
    }

    if (normalized.contains('hisse') || normalized.contains('stock')) {
      return 78;
    }

    if (normalized.contains('fon') || normalized.contains('etf')) {
      return 70;
    }

    if (normalized.contains('altın') ||
        normalized.contains('altin') ||
        normalized.contains('gold')) {
      return 52;
    }

    if (normalized.contains('nakit') ||
        normalized.contains('cash') ||
        normalized.contains('döviz') ||
        normalized.contains('doviz')) {
      return 35;
    }

    return 55;
  }
}