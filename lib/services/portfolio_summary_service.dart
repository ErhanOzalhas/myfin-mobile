import '../models/portfolio_item.dart';
import 'portfolio_valuation_service.dart';

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
  static Future<PortfolioSummary> calculate(
    List<PortfolioItem> items, {
    bool forceRefresh = false,
  }) async {
    final valuation = await PortfolioValuationService.instance.calculate(
      items,
      forceRefresh: forceRefresh,
    );

    return PortfolioSummary(
      totalCost: valuation.totalCost,
      totalValue: valuation.totalValue,
      totalProfit: valuation.totalProfit,
      profitPercent: valuation.profitPercent,
      assetCount: valuation.assetCount,
      primaryCurrency: valuation.baseCurrency,
    );
  }

  /// Yalnızca yüklenme anı ve çevrimdışı görsel geri dönüş için kullanılır.
  /// Yabancı para birimleri burada birbirine eklenmez.
  static PortfolioSummary calculateFromCost(
    List<PortfolioItem> items,
  ) {
    final tryItems = items.where(
      (item) => _normalizeCurrency(item.currency) == 'TRY',
    );

    final totalCost = tryItems.fold<double>(
      0,
      (sum, item) => sum + item.totalCost,
    );

    return PortfolioSummary(
      totalCost: totalCost,
      totalValue: totalCost,
      totalProfit: 0,
      profitPercent: 0,
      assetCount: items.length,
      primaryCurrency: 'TRY',
    );
  }

  static String _normalizeCurrency(String value) {
    final normalized = value.trim().toUpperCase();

    return switch (normalized) {
      'TL' || '₺' => 'TRY',
      _ => normalized,
    };
  }
}
