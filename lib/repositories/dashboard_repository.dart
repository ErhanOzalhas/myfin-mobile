import '../models/dashboard_summary.dart';
import '../models/market_quote.dart';
import '../models/portfolio_item.dart';
import 'market_repository.dart';

class DashboardRepository {
  DashboardRepository._();

  static final DashboardRepository instance = DashboardRepository._();

  Future<DashboardSummary> calculate(List<PortfolioItem> items) async {
    double totalCost = 0;
    double currentValue = 0;

    String? bestName;
    double bestPercent = -999999;

    String? worstName;
    double worstPercent = 999999;

    for (final item in items) {
      final MarketQuote quote = await MarketRepository.instance.getQuote(
        symbol: item.symbol,
        type: item.type,
      );

      final double cost = item.totalCost;
      final double value = quote.currentPrice * item.quantity;

      totalCost += cost;
      currentValue += value;

      final double percent = cost == 0 ? 0.0 : ((value - cost) / cost) * 100;

      if (percent > bestPercent) {
        bestPercent = percent;
        bestName = item.symbol;
      }

      if (percent < worstPercent) {
        worstPercent = percent;
        worstName = item.symbol;
      }
    }

    final double profit = currentValue - totalCost;
    final double profitPercent =
        totalCost == 0 ? 0.0 : ((profit / totalCost) * 100).toDouble();

    return DashboardSummary(
      totalCost: totalCost,
      currentValue: currentValue,
      profitLoss: profit,
      profitPercent: profitPercent,
      bestPerformer: bestName,
      bestPerformance: bestName == null ? 0.0 : bestPercent,
      worstPerformer: worstName,
      worstPerformance: worstName == null ? 0.0 : worstPercent,
    );
  }
}
