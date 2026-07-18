import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:myfin_mobile/models/portfolio_item.dart';
import 'package:myfin_mobile/models/portfolio_performance.dart';
import 'package:myfin_mobile/models/portfolio_snapshot.dart';
import 'package:myfin_mobile/services/portfolio_valuation_service.dart';
import 'package:myfin_mobile/services/report_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final item = PortfolioItem(
    id: '1',
    name: 'Şişecam Türk Lirası',
    symbol: 'SISE',
    type: 'Hisse',
    quantity: 10,
    averagePrice: 100,
    currency: 'TRY',
  );
  final valuation = PortfolioValuation(
    baseCurrency: 'TRY',
    items: [
      PortfolioItemValuation(
        item: item,
        costInBaseCurrency: 1000,
        currentValueInBaseCurrency: 1100,
        profitLossInBaseCurrency: 100,
        profitPercent: 10,
        hasLivePrice: true,
      ),
    ],
    totalCost: 1000,
    totalValue: 1100,
    totalProfit: 100,
    profitPercent: 10,
  );
  final performance = PortfolioPerformance(
    snapshots: [
      PortfolioSnapshot(
        dateKey: '2026-07-17',
        capturedAt: DateTime(2026, 7, 17),
        totalValue: 1000,
        totalCost: 1000,
        profitLoss: 0,
        assetCount: 1,
        categoryValues: const {'Hisse': 1000},
      ),
      PortfolioSnapshot(
        dateKey: '2026-07-18',
        capturedAt: DateTime(2026, 7, 18),
        totalValue: 1100,
        totalCost: 1000,
        profitLoss: 100,
        assetCount: 1,
        categoryValues: const {'Hisse': 1100},
      ),
    ],
    chartValues: const [0, 10],
    totalReturnPercent: 10,
    averageDailyReturnPercent: 10,
    volatilityPercent: 0,
    netContribution: 0,
  );

  test('creates valid portfolio PDF and Excel signatures', () async {
    final service = ReportExportService.instance;
    final pdf = await service.buildPortfolioPdf(valuation);
    final excel = service.buildPortfolioExcel(valuation);

    expect(ascii.decode(pdf.take(4).toList()), '%PDF');
    expect(excel.take(2).toList(), [0x50, 0x4B]);
  });

  test('creates valid performance PDF and Excel signatures', () async {
    final service = ReportExportService.instance;
    final pdf = await service.buildPerformancePdf(performance, '7 Gün');
    final excel = service.buildPerformanceExcel(performance, '7 Gün');

    expect(ascii.decode(pdf.take(4).toList()), '%PDF');
    expect(excel.take(2).toList(), [0x50, 0x4B]);
  });
}
