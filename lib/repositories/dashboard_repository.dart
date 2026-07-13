import '../models/dashboard_summary.dart';
import '../models/portfolio_item.dart';
import '../services/portfolio_valuation_service.dart';

class DashboardRepository {
  DashboardRepository._();

  static final DashboardRepository instance = DashboardRepository._();

  Future<DashboardSummary> calculate(
    List<PortfolioItem> items,
  ) async {
    final valuation =
        await PortfolioValuationService.instance.calculate(items);

    PortfolioItemValuation? best;
    PortfolioItemValuation? worst;

    for (final itemValuation in valuation.items) {
      if (best == null ||
          itemValuation.profitPercent > best.profitPercent) {
        best = itemValuation;
      }

      if (worst == null ||
          itemValuation.profitPercent < worst.profitPercent) {
        worst = itemValuation;
      }
    }

    return DashboardSummary(
      totalCost: valuation.totalCost,
      currentValue: valuation.totalValue,
      profitLoss: valuation.totalProfit,
      profitPercent: valuation.profitPercent,
      bestPerformer: best?.item.symbol,
      bestPerformance: best?.profitPercent ?? 0,
      worstPerformer: worst?.item.symbol,
      worstPerformance: worst?.profitPercent ?? 0,
    );
  }
}
