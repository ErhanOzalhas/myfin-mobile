import 'portfolio_snapshot.dart';

class PortfolioPerformance {
  const PortfolioPerformance({
    required this.snapshots,
    required this.chartValues,
    required this.totalReturnPercent,
    required this.averageDailyReturnPercent,
    required this.volatilityPercent,
    required this.netContribution,
  });

  final List<PortfolioSnapshot> snapshots;
  final List<double> chartValues;
  final double totalReturnPercent;
  final double averageDailyReturnPercent;
  final double volatilityPercent;
  final double netContribution;

  bool get hasHistory => snapshots.length >= 2;
  bool get isPositive => totalReturnPercent >= 0;

  String get momentumLabel => isPositive ? 'Pozitif' : 'Negatif';

  String get riskLabel {
    if (!hasHistory) return 'Veri bekleniyor';
    if (volatilityPercent >= 3) return 'Yüksek';
    if (volatilityPercent >= 1.25) return 'Orta';
    return 'Düşük';
  }
}
