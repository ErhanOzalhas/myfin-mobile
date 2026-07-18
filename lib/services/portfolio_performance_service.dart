import 'dart:math' as math;

import '../models/portfolio_item.dart';
import '../models/portfolio_performance.dart';
import '../models/portfolio_snapshot.dart';
import '../repositories/portfolio_snapshot_repository.dart';
import 'portfolio_valuation_service.dart';

class PortfolioPerformanceService {
  PortfolioPerformanceService._();

  static final PortfolioPerformanceService instance =
      PortfolioPerformanceService._();

  final PortfolioSnapshotRepository _repository =
      PortfolioSnapshotRepository.instance;
  final Map<String, Future<void>> _captures = {};

  Future<void> captureToday(List<PortfolioItem> items) async {
    final valuation = await PortfolioValuationService.instance.calculate(items);
    await _captureToday(valuation, DateTime.now());
  }

  Future<PortfolioPerformance> load({
    required List<PortfolioItem> items,
    required DateTime start,
    required DateTime end,
  }) async {
    final valuation = await PortfolioValuationService.instance.calculate(items);
    final today = DateTime.now();
    await _captureToday(valuation, today);

    final stored = await _repository.getRange(start: start, end: end);
    final snapshots = [...stored];
    final todayKey = PortfolioSnapshotRepository.dateKey(today);
    final live = _snapshotFromValuation(valuation, today);
    final todayIndex = snapshots.indexWhere((item) => item.dateKey == todayKey);
    if (todayIndex >= 0) {
      snapshots[todayIndex] = live;
    } else if (!today.isBefore(_day(start)) && !today.isAfter(_endOfDay(end))) {
      snapshots.add(live);
    }
    snapshots.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    return calculateFromSnapshots(snapshots);
  }

  Future<void> _captureToday(PortfolioValuation valuation, DateTime now) {
    final key = PortfolioSnapshotRepository.dateKey(now);
    return _captures.putIfAbsent(key, () async {
      try {
        await _repository.upsert(_snapshotFromValuation(valuation, now));
      } finally {
        _captures.remove(key);
      }
    });
  }

  PortfolioSnapshot _snapshotFromValuation(
    PortfolioValuation valuation,
    DateTime capturedAt,
  ) {
    final categories = <String, double>{};
    for (final item in valuation.items) {
      final key = item.item.type.trim().isEmpty ? 'Diğer' : item.item.type;
      categories[key] =
          (categories[key] ?? 0) + item.currentValueInBaseCurrency;
    }
    return PortfolioSnapshot(
      dateKey: PortfolioSnapshotRepository.dateKey(capturedAt),
      capturedAt: capturedAt,
      totalValue: valuation.totalValue,
      totalCost: valuation.totalCost,
      profitLoss: valuation.totalProfit,
      assetCount: valuation.assetCount,
      categoryValues: categories,
    );
  }

  static PortfolioPerformance calculateFromSnapshots(
    List<PortfolioSnapshot> snapshots,
  ) {
    if (snapshots.isEmpty) {
      return const PortfolioPerformance(
        snapshots: [],
        chartValues: [],
        totalReturnPercent: 0,
        averageDailyReturnPercent: 0,
        volatilityPercent: 0,
        netContribution: 0,
      );
    }

    final values = <double>[0];
    final dailyReturns = <double>[];
    var cumulative = 1.0;
    var netContribution = 0.0;

    for (var i = 1; i < snapshots.length; i++) {
      final previous = snapshots[i - 1];
      final current = snapshots[i];
      final contribution = current.totalCost - previous.totalCost;
      netContribution += contribution;
      final denominator = math.max(previous.totalValue, 0.01);
      final dailyReturn =
          (current.totalValue - previous.totalValue - contribution) /
          denominator;
      dailyReturns.add(dailyReturn);
      cumulative *= 1 + dailyReturn;
      values.add((cumulative - 1) * 100);
    }

    final totalReturn = (cumulative - 1) * 100;
    final average = dailyReturns.isEmpty
        ? 0.0
        : dailyReturns.reduce((a, b) => a + b) / dailyReturns.length;
    final variance = dailyReturns.isEmpty
        ? 0.0
        : dailyReturns
                  .map((value) => math.pow(value - average, 2).toDouble())
                  .reduce((a, b) => a + b) /
              dailyReturns.length;

    return PortfolioPerformance(
      snapshots: snapshots,
      chartValues: values,
      totalReturnPercent: totalReturn,
      averageDailyReturnPercent: average * 100,
      volatilityPercent: math.sqrt(variance) * 100,
      netContribution: netContribution,
    );
  }

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  DateTime _endOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
}
