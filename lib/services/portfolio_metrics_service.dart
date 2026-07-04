import '../models/portfolio_item.dart';

class PortfolioMetricsService {
  const PortfolioMetricsService();

  /// Total portfolio value based on cost basis.
  double totalValue(List<PortfolioItem> items) {
    return items.fold(
      0,
      (sum, item) => sum + item.totalCost,
    );
  }

  /// Allocation by symbol (AAPL, THYAO...)
  Map<String, double> allocationBySymbol(
    List<PortfolioItem> items,
  ) {
    final total = totalValue(items);

    if (total == 0) return {};

    final result = <String, double>{};

    for (final item in items) {
      result[item.symbol] =
          (result[item.symbol] ?? 0) + item.totalCost;
    }

    result.updateAll((_, value) => value / total);

    return result;
  }

  /// Allocation by currency (TRY, USD...)
  Map<String, double> allocationByCurrency(
    List<PortfolioItem> items,
  ) {
    final total = totalValue(items);

    if (total == 0) return {};

    final result = <String, double>{};

    for (final item in items) {
      result[item.currency] =
          (result[item.currency] ?? 0) + item.totalCost;
    }

    result.updateAll((_, value) => value / total);

    return result;
  }

  /// Allocation by asset type (Stock, ETF, Crypto...)
  Map<String, double> allocationByType(
    List<PortfolioItem> items,
  ) {
    final total = totalValue(items);

    if (total == 0) return {};

    final result = <String, double>{};

    for (final item in items) {
      result[item.type] =
          (result[item.type] ?? 0) + item.totalCost;
    }

    result.updateAll((_, value) => value / total);

    return result;
  }

  /// Largest holding in portfolio.
  PortfolioItem? largestHolding(
    List<PortfolioItem> items,
  ) {
    if (items.isEmpty) return null;

    PortfolioItem largest = items.first;

    for (final item in items.skip(1)) {
      if (item.totalCost > largest.totalCost) {
        largest = item;
      }
    }

    return largest;
  }
}