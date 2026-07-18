import 'package:flutter_test/flutter_test.dart';
import 'package:myfin_mobile/models/portfolio_snapshot.dart';
import 'package:myfin_mobile/services/portfolio_performance_service.dart';

void main() {
  PortfolioSnapshot snapshot(
    String date, {
    required double value,
    required double cost,
  }) {
    return PortfolioSnapshot(
      dateKey: date,
      capturedAt: DateTime.parse(date),
      totalValue: value,
      totalCost: cost,
      profitLoss: value - cost,
      assetCount: 1,
      categoryValues: const {},
    );
  }

  test('calculates return from real value change', () {
    final result = PortfolioPerformanceService.calculateFromSnapshots([
      snapshot('2026-07-17', value: 100, cost: 100),
      snapshot('2026-07-18', value: 110, cost: 100),
    ]);

    expect(result.totalReturnPercent, closeTo(10, 0.0001));
    expect(result.averageDailyReturnPercent, closeTo(10, 0.0001));
    expect(result.netContribution, 0);
  });

  test('does not count a new contribution as investment return', () {
    final result = PortfolioPerformanceService.calculateFromSnapshots([
      snapshot('2026-07-17', value: 100, cost: 100),
      snapshot('2026-07-18', value: 150, cost: 150),
    ]);

    expect(result.totalReturnPercent, closeTo(0, 0.0001));
    expect(result.netContribution, 50);
  });
}
