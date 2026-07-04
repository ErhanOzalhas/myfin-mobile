import 'package:myfin_mobile/models/portfolio_item.dart';

class PortfolioSummary {
  final double totalCost;
  final double totalValue;
  final double totalProfit;
  final double profitPercent;
  final int assetCount;
  final String primaryCurrency;

  const PortfolioSummary({
    required this.totalCost,
    required this.totalValue,
    required this.totalProfit,
    required this.profitPercent,
    required this.assetCount,
    required this.primaryCurrency,
  });
}

class PortfolioSummaryService {
  /// Şimdilik toplam değer hesabında kullanıcının girdiği alış birim fiyatı esas alınır.
  /// Canlı fiyat eşleşmesi tam oturduktan sonra currentValue ayrı bir alanda ele alınacak.
  static Future<PortfolioSummary> calculate(List<PortfolioItem> items) async {
    return calculateFromCost(items);
  }

  static PortfolioSummary calculateFromCost(List<PortfolioItem> items) {
    final totalCost = items.fold<double>(
      0,
      (sum, item) => sum + item.totalCost,
    );

    return _buildSummary(
      items,
      totalCost: totalCost,
      totalValue: totalCost,
    );
  }

  static PortfolioSummary _buildSummary(
    List<PortfolioItem> items, {
    required double totalCost,
    required double totalValue,
  }) {
    final totalProfit = totalValue - totalCost;
    final profitPercent = totalCost <= 0 ? 0.0 : (totalProfit / totalCost) * 100;

    return PortfolioSummary(
      totalCost: totalCost,
      totalValue: totalValue,
      totalProfit: totalProfit,
      profitPercent: profitPercent,
      assetCount: items.length,
      primaryCurrency: _primaryCurrency(items),
    );
  }

  static String _primaryCurrency(List<PortfolioItem> items) {
    if (items.isEmpty) return 'TRY';

    final totals = <String, double>{};
    for (final item in items) {
      totals[item.currency] = (totals[item.currency] ?? 0) + item.totalCost;
    }

    return totals.entries
        .fold<MapEntry<String, double>?>(null, (best, entry) {
          if (best == null || entry.value > best.value) return entry;
          return best;
        })
        ?.key ??
        'TRY';
  }
}
